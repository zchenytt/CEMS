module Train

import ..Ms, ..Ipr
import JuMP

function log_valid_lb(k, inn, bias)
    bound = bias + sum(JuMP.objective_bound, inn)
    @ccall(printf("k=%d, lb=%e\n"::Cstring; k::Cint, bound::Cdouble)::Cint)
end
function log_CTPLN_ub(k, nt)
    bound = nt.ub
    @ccall(printf("k=%d, ub=%e\n"::Cstring; k::Cint, bound::Cdouble)::Cint)
end

function dual_iterate(k, ref, out, inn, ipr, ismC, Saturate, COT)
    for (j, n)=enumerate(inn) Ms.reset_obj(ref, n, ismC) end
    foreach(JuMP.optimize!, inn)
    all(m -> JuMP.termination_status(m) === JuMP.OPTIMAL, inn) || error("234")
    bias = ref.x.common
    log_valid_lb(k, inn, bias)
    Saturate .= false
    for (j, n)=enumerate(inn)
        djXj = ismC ? (JuMP.value(n[:pCost])+(0 in n[:h] ? JuMP.value(n[:GCur]) : 0.)) : 0.
        nt = ref.x # to be locked
        e, S = Ms.add_bilin_at_once(djXj, out[:β], n[:pBus], n[:h], JuMP.value, nt.β)
        vio = nt.θ[j] - S
        # println("ismC = $ismC, j = $j, vio = $vio")
        if vio > COT
            Ms.add_vio(out[:θ][j], out, e) # to be locked
            Ipr.add_to_ipr(ipr, inn[j], j)
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
dual_train(K, a...) = for k=1:K
    dual_iterate(k, a...) && break
end

end
