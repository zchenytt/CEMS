module Ms
import ..In: C, F, T, J, J1, _s, _t
import JuMP

# mainly do these work
add_vio(θ::JuMP.VariableRef, out, e) = JuMP.@constraint(out, θ ≤ e)
construct_nt(#=out=# m) = (ub=JuMP.objective_bound(m), θ=JuMP.value.(m[:θ]), β=JuMP.value.(m[:β]), common=JuMP.value(m[:common]))
construct_nt(βsum::Int) = (ub=Inf, θ=fill(Inf, J), β=fill(βsum/F/T, (F)T), common=NaN)

# Master formulation is okay
function build_master(#=out=# m, P_A::Float64, #=Feas. 1; minCost 0=# i::Int, ref)
    isFs = Bool(i)
    JuMP.@variable(m, β[1:(F)T] ≥ 0)
    JuMP.@variable(m, θ[1:J])
    JuMP.@expression(m, common, JuMP.AffExpr(0))
    isFs || JuMP.add_to_expression!(common, -(P_A)sum(β)) 
    JuMP.@objective(m, Max, common + sum(θ))
    if isFs
        JuMP.@constraint(m, sum(β) == i)
        setfield!(ref, :x, construct_nt(i))
    end
end

# From Feas. to MinCost. is okay
_add_beta(e, #=out_min_cost's=# β, #=j-th entry=# pBlock, i) = for (f, β)=enumerate(β)
    JuMP.add_to_expression!(e, JuMP.value(pBlock[i(f)]), β)
end
function add_initial_cut_for_min_cost_problem(out, ipr, j)
    h0 = in(j,J1)
    cn = JuMP.value(ipr[:pCost][j]) + (h0 ? JuMP.value(ipr[:GCur][j]) : 0.)
    e = JuMP.AffExpr(cn)
    _add_beta(e, out[:β], ipr[:pBlock][j], h0 ? identity : _s)
    add_vio(out[:θ][j], out, e)
end

# Beta-term collection that suits for both type of problem, is okay
function _add_beta(e, S::Float64, _h, i, pBus, β, B)
    for (f, β)=enumerate(β), h=_h
        X = i(pBus[h,_t(f,h)])
        JuMP.add_to_expression!(e, X, β)
        S += B[f]X
    end
    S
end
function add_bilin_at_once(djXj::Float64, β, pBus, _h, i, #=newEST=# B)
    e = JuMP.AffExpr(djXj)
    S = _add_beta(e, djXj, _h, i, pBus, β, B)
    e, S
end

# this is okay
pnc(pBus,β,i,m,h,f)=JuMP.@expression(m,sum(((i/F)C[f]+β[f])pBus[h,_t(f,h)] for h=h for f=f))
function reset_obj(ref, m, #=MinCost true; Feas. false=# i::Bool)
    h0 = 0 in m[:h]
    nt = #=@lock=# ref[]
    β = nt.β
    e = pnc(m[:pBus], β, i, m, m[:h], eachindex(C))
    (i && h0) && JuMP.add_to_expression!(e, m[:GCur])
    JuMP.@objective(m, Min, e)
end

end

