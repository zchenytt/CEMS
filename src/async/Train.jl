module Train

import ..Settings
import ..Ms, ..Ipr
import JuMP

function summary(#=result_nt=# r)
    agap = r[:du] - r[:dl]
    rgap = agap / r[:dl]
    err = abs(r[:du] - r[:pl]) / max(abs(r[:du]), abs(r[:pl]))
    rgap_ip = (r[:pi] - r[:dl]) / r[:pi]
    println("summary> l = $rgap, e = $err, i = $rgap_ip, lagap = $agap")
end

################################################
# sequential programming
dual_train(K, a...) = for k=1:K
    dual_iterate(k, a...) && break
end
function dual_iterate(k, Lk, ref, out, inn, ipr, i, Saturate, COT)
    for (j, n)=enumerate(inn) Ms.reset_obj(Lk.ref, ref, n, i) end
    foreach(JuMP.optimize!, inn)
    all(m -> JuMP.termination_status(m) === JuMP.OPTIMAL, inn) || error("234")
    bias = ref.x.common
    log_valid_lb(k, inn, bias)
    Saturate .= false
    for (j, n)=enumerate(inn)
        # TODO here this ref is new by definition, we can also make it non-update as a variant
        cn, vio = Ms.get_cn_vio(j, n, out, ref, Lk.ref, i::Bool)
        println("ismC = $i, j = $j, vio = $vio")
        if vio > COT
            _1(out, n, cn, Lk.d)
            Ipr.add_to_ipr(Lk.p, ipr, inn[j], j)
        else
            Saturate[j] = true
        end
    end
    all(Saturate) && return true
    JuMP.optimize!(out)
    ter = JuMP.termination_status(out)
    ter === JuMP.OPTIMAL || error("Master: $ter")
    nt = Ms.construct_nt(out)
    log_CTPLN_ub(k, nt)
    setfield!(ref, :x, nt) # to be locked
    false
end
function log_valid_lb(k, inn, bias)
    bound = bias + sum(JuMP.objective_bound, inn)
    @ccall(printf("k=%d, lb=%e\n"::Cstring; k::Cint, bound::Cdouble)::Cint)
end
function log_CTPLN_ub(k, nt)
    bound = nt.ub
    @ccall(printf("k=%d, ub=%e\n"::Cstring; k::Cint, bound::Cdouble)::Cint)
end
################################################
opt_and_ter(m) = (JuMP.optimize!(m); JuMP.termination_status(m))
fill_otr(otr, a...) = (t = otr.x = spawn_out(a...); wait(t))
spawn_out(a...) = Threads.@spawn(outfun(a...))
spawn_nwloop(a...) = Threads.@spawn(nwloop(a...))
spawn_subfun(j, inn, a...)=(n = inn[j]; Threads.@spawn(subfun(j, n, a...)))
function warm_by_inn(tks, ref, mst, inn, Lk, Ncuts, COT) # Feas. is warmed by inn, whereas MinCost is warmed by ipr
    for j=eachindex(inn) setindex!(tks, spawn_subfun(j, inn, Lk, Ncuts, ref, mst.f.d, mst.f.p, COT, false), j) end
    foreach(wait, tks)
    outfun(mst.f.d, Lk, ref)
end
function outfun(out, Lk, ref)
    ter = @lock Lk.d opt_and_ter(out)
    ter === JuMP.OPTIMAL || error("out: $ter")
    nt = @lock Lk.d Ms.construct_nt(out)
    @lock Lk.ref setfield!(ref, :x, nt)
end
function set_maxtime(inn, out)
    JuMP.set_attribute(out, "TimeLimit", 360)
    for n=inn JuMP.set_attribute(n, "TimeLimit", 40) end
end
function nwloop( # No Wait Loop--it is _nonblocking_ so you'll have to wait for it subsequently
    #=non_locals=# Ncuts0, j, otr,
    #=bookkeeping=# tks, Lk, ref, out, ipr, inn, COT, Ncuts,
    #=Settings=# THREAD_FOR_BLOCKS, i, MaxSec)
    otk, J = otr.x, length(inn)
    D_t = 1_000_000_000 * MaxSec
    tabs0 = time_ns()
    while true
        d_t = time_ns() - tabs0
        # @debug @ccall(printf("t_elapsed=%e\n"::Cstring; d_t / 1e9::Cdouble)::Cint)
        d_t > D_t && break
        if istaskdone(otk)
            wait(otk)
            Ncuts_now = Ncuts.value
            if Ncuts_now !== Ncuts0 && _b(tks, THREAD_FOR_BLOCKS)
                otk = spawn_out(out, Lk, ref)
                Ncuts0 = Ncuts_now
            end
        end
        Ø = 0
        while _b(tks, THREAD_FOR_BLOCKS)
            ø = tks[j]
            if istaskdone(ø)
                wait(ø)
                setindex!(tks, spawn_subfun(j, inn, Lk, Ncuts, ref, out, ipr, COT, i), j)
            end
            j = mod(j, J)+1
            Ø === THREAD_FOR_BLOCKS && break
            Ø += 1
        end
        GC.safepoint()
    end
    otr.x = otk
end
_b(tks, ths) = count(!istaskdone, tks) < ths # returns if `inn-tasks underoccupy hardware resources`
wait3(nwtk, otr, tks) = (wait(nwtk);wait(otr.x);foreach(wait, tks))

function _1(out, n, cn, dualLk) 
    ci, cd, o = n[:ci], n[:cd], JuMP.backend(out)
    len = Cint(length(ci))
    @lock(dualLk, Settings.addle(o, len, ci, cd, cn))
end
function subfun(j, n, Locks, Ncuts, ref, out, ipr, COT, #=MinCost true; Feas. false=# i::Bool)
    Ms.reset_obj(Locks.ref, ref, n, i)
    JuMP.optimize!(n)
    pri = JuMP.primal_status(n)
    pri === JuMP.FEASIBLE_POINT || error("subfun> $pri")
    cn, vio = Ms.get_cn_vio(j, n, out, ref, Locks.ref, i)
    if vio > COT
        # @ccall(printf("j=%d, vio=%e\n"::Cstring; j::Cint, vio::Cdouble)::Cint)
        _1(out, n, cn, Locks.d) # add the violating cut
        Threads.atomic_add!(Ncuts, 1)
        Ipr.add_to_ipr(Locks.p, ipr, n, j)
    end
end

# query a valid lower bound 
function _modify_lb(n, lba, Lk, ref, i)
    Ms.reset_obj(Lk, ref, n, i)
    JuMP.optimize!(n)
    pri = JuMP.primal_status(n)
    pri === JuMP.FEASIBLE_POINT || error("in _modify_lb: $pri")
    Threads.atomic_add!(lba, JuMP.objective_bound(n))
end
function modify_lb(tks, inn, lba, Lk, ref, i)
    for (j,n)=enumerate(inn) setindex!(tks, Threads.@spawn(_modify_lb(n, lba, Lk, ref, i)), j) end
    foreach(wait, tks)
end

end