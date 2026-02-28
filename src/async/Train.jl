module Train

import ..Settings
import ..Ms, ..Ipr
import JuMP

################################################
# sequential programming
# dual_train(K, a...) = for k=1:K
#     dual_iterate(k, a...) && break
# end
# function dual_iterate(k, Lk, ref, out, inn, ipr, i, Saturate, COT)
#     for (j, n)=enumerate(inn) Ms.reset_obj(Lk.ref, ref, n, i) end
#     foreach(JuMP.optimize!, inn)
#     all(m -> JuMP.termination_status(m) === JuMP.OPTIMAL, inn) || error("234")
#     bias = ref.x.common
#     log_valid_lb(k, inn, bias)
#     Saturate .= false
#     for (j, n)=enumerate(inn)
#         # TODO here this ref is new by definition, we can also make it non-update as a variant
#         cn, vio = Ms.get_cn_vio(j, n, out, ref, Lk.ref, i::Bool)
#         println("ismC = $i, j = $j, vio = $vio")
#         if vio > COT
#             _1(out, n, cn, Lk.d)
#             Ipr.add_to_ipr(Lk.p, ipr, inn[j], j)
#         else
#             Saturate[j] = true
#         end
#     end
#     all(Saturate) && return true
#     JuMP.optimize!(out)
#     ter = JuMP.termination_status(out)
#     ter === JuMP.OPTIMAL || error("Master: $ter")
#     nt = Ms.construct_nt(out)
#     log_CTPLN_ub(k, nt)
#     setfield!(ref, :x, nt) # to be locked
#     false
# end
# function log_valid_lb(k, inn, bias)
#     bound = bias + sum(JuMP.objective_bound, inn)
#     @ccall(printf("k=%d, lb=%e\n"::Cstring; k::Cint, bound::Cdouble)::Cint)
# end
# function log_CTPLN_ub(k, nt)
#     bound = nt.ub
#     @ccall(printf("k=%d, ub=%e\n"::Cstring; k::Cint, bound::Cdouble)::Cint)
# end
################################################
opt_and_ter(m) = (JuMP.optimize!(m); JuMP.termination_status(m))

ss(a...) = Threads.@spawn(schedulingloop(a...))
spawn_sub(j, inn, a...)=(n = inn[j]; Threads.@spawn(subfun(j, n, a...)))

function warm_by_inn(tks, ref, mst, inn, Lk, Ncuts, COT, evt) # Feas. is warmed by inn, whereas MinCost is warmed by ipr
    # here is locally parallel but globally sync programming, so no locks are needed
    for (j, n)=enumerate(inn)
        JuMP.set_attribute(n, "TimeLimit", 25)
        tks[j] = spawn_sub(j, inn, Lk, Ncuts, ref, mst.f.d, mst.f.p, COT, false, evt)
    end
    foreach(wait, tks)
    out = mst.f.d
    opt_and_ter(out) === JuMP.OPTIMAL || error()
    ref.x = Ms.construct_nt(out, ref, 1)
end

function subfun(j, n, Lk, Ncuts, ref, out, ipr, COT, #=MinCost true; Feas. false=# i::Bool, evt)
    nt = @lock(Lk.ref, ref.x)
    k1 = nt.k
    if n[:k] !== k1
        Ms.reset_obj(nt, n, i)
        n[:k], n[:should_solve] = k1, true
    end
    if n[:should_solve]
        should_solve = true
        opt_and_ter(n) === JuMP.OPTIMAL && (should_solve = false;)
        if JuMP.primal_status(n) === JuMP.FEASIBLE_POINT
            cn, vio = Ms.get_cn_vio(j, n, out, ref, Lk.ref, i)
            if vio > COT
                # @ccall(printf("j=%d, vio=%e\n"::Cstring; j::Cint, vio::Cdouble)::Cint)
                _1(out, n, cn, Lk.d) # add the violating cut
                Threads.atomic_add!(Ncuts, 1)
                notify(evt) # set it in a different thread!
                should_solve = false
                Ipr.add_to_ipr(Lk.p, ipr, n, j)
            end
        else
            Settings.reset_gurobi_seed(n)
            @ccall(printf("subfun> unsolved at j=%d\n"::Cstring; j::Cint)::Cint)
        end
        n[:should_solve] = should_solve
    end
end
function _outfun(out, Lk, ref, Ncuts, evt)
    n1 = Ncuts.value
    (out[:Ncuts] === n1 && out[:should_solve] === false) && return
    ter = @lock(Lk.d, opt_and_ter(out))
    out[:Ncuts] = n1
    if ter ∉ (JuMP.OPTIMAL, JuMP.LOCALLY_SOLVED)
        out[:should_solve] = true
        return
    end
    ter === JuMP.LOCALLY_SOLVED && @ccall(printf("Warning (julia): out LP LOCALLY_SOLVED\n"::Cstring)::Cint)
    nt = @lock Lk.d Ms.construct_nt(out, ref, 1) # here allocates!
    @lock Lk.ref setfield!(ref, :x, nt)
    notify(evt) # set it in a different thread!
    out[:should_solve] = false
    return
end
function _7(j, J, tks, ths, inn, a...)
    c = -2
    while count(!istaskdone, tks) < ths # `inn-tasks underoccupy hardware resources`
        t = tks[j] # check 1st
        if istaskdone(t)
            wait(t)
            tks[j] = spawn_sub(j, inn, a...)
        end
        j = mod(j, J)+1
        c === ths && break
        c += 1
    end
    j
end
function _8(otk, a...)
    if istaskdone(otk)
        wait(otk)
        otk = Threads.@spawn(_outfun(a...))
    end
    otk
end
function schedulingloop(
    #=non_locals=# evt, j, otr,
    #=bookkeeping=# tks, Lk, ref, out, ipr, inn, COT, Ncuts,
    #=Settings=# THREAD_FOR_BLOCKS, i, MaxSec)
    otk, J, D_t, _ = otr.x, length(inn), 1_000_000_000*MaxSec, notify(evt)
    t0 = time_ns()
    while true
        wait(evt) # irredundant as it sets status `false`
        d_t = time_ns() - t0
        # t_elapsed = d_t / 1_000_000_000
        # @ccall(printf("t_elapsed=%e\n"::Cstring; t_elapsed::Cdouble)::Cint)
        d_t > D_t && break
        otk = _8(otk, out, Lk, ref, Ncuts, evt)
        j = _7(j, J, tks, THREAD_FOR_BLOCKS, inn, Lk, Ncuts, ref, out, ipr, COT, i, evt)
        if !evt.set
            sleep(0.001) # avoid a spinning loop
            notify(evt)
        end
    end
    otr.x = otk
end
function set_maxtime(inn, out)
    JuMP.set_attribute(out, "TimeLimit", 15)
    for n=inn JuMP.set_attribute(n, "TimeLimit", 18) end
end
wait3(stk, otr, tks) = (wait(stk);wait(otr.x);foreach(wait, tks))
function _1(out, n, cn, dualLk) 
    ci, cd, o = n[:ci], n[:cd], JuMP.backend(out)
    len = Cint(length(ci))
    @lock(dualLk, Settings.addle(o, len, ci, cd, cn))
end

# query a valid lower bound: only using ObjBnd here is valid!
function _3(n, lba, refLk, ref, i)
    nt = @lock(refLk, ref.x)
    Ms.reset_obj(nt, n, i)
    JuMP.set_attribute(n, "TimeLimit", 60) # Tuning up this, we might shrink rgap but end up waiting longer
    Settings.solve_many_times(n, "_modify_lb")
    Threads.atomic_add!(lba, JuMP.objective_bound(n))
end
function modify_lb(tks, inn, a...)
    for (j,n)=enumerate(inn) setindex!(tks, Threads.@spawn(_3(n, a...)), j) end
    foreach(wait, tks)
end

end