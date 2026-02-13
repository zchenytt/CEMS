module Ipr # Integer Programming Restricted
import ..In: J, J1, J2, T, F, _t, _s
import JuMP

_vj(j) = [JuMP.AffExpr(0) for _ = Base.OneTo(((F-1)*(in(j,J1))+1) * T)]
function build_ipr(#=ipr=# m, inn) # {c, bU, bEV, bLent, bES, pBlock, pCost, GCur}
    JuMP.@expression(m, c, [JuMP.VariableRef[] for j=1:J]) # store all `c≥0` and `sum(c[j])==1, ∀j`
    # These are containers
    JuMP.@expression(m, bU, [Dict(k=>JuMP.AffExpr(0) for k=keys(inn[j][:bU].data))                   for j=1:J]) # bU[j][h, t, device(i)]
    JuMP.@expression(m, bEV, [Dict((h,t)=>JuMP.AffExpr(0) for t=1:T for h=(in(j,J1) ? (0,1) : (1,))) for j=1:J]) # bEV[j][h, slow]
    JuMP.@expression(m, bLent, [[JuMP.AffExpr(0) for t=1:T]                                          for j=J1]) # bLent[j][slow]
    JuMP.@expression(m, bES, [[JuMP.AffExpr(0) for t=1:(F)T]                                         for j=J1]) # bES[j][fast]
    # CB power: for jinJ1 block, allocate one pBlock, otherwise allocate a 1:T pBus.
    JuMP.@expression(m, pBlock, map(_vj, 1:J)) # pBlock[j][fast/slow]
    # These are scalars
    JuMP.@expression(m, pCost, [JuMP.AffExpr(0) for j=1:J])
    JuMP.@expression(m, GCur,  [JuMP.AffExpr(0) for j=J1])
end

_c(m) = JuMP.@variable(m, lower_bound = 0)
add_to_bU(d, i, c) = for (k,v)=i JuMP.add_to_expression!(d[k], JuMP.value(v), c) end
add_to_bEV(h, d, x, c) = for h=h, t=1:T JuMP.add_to_expression!(d[h,t], JuMP.value(x[h,t]), c) end
add_to_pBlock(d, x, c) = for f=1:(F)T JuMP.add_to_expression!(d[f], sum(JuMP.value(x[h,_t(f,h)]) for h=(0,1)), c) end
add_to_vec(e,x,c)=for (e,x)=zip(e,x) JuMP.add_to_expression!(e,JuMP.value(x),c) end
#=API=# function add_to_ipr(#=ipr=# m, #=inn[j]=# n, j)
    _H = n[:h]
    #=Only here needs lock=# c = _c(m)
    add_to_bU(m[:bU][j], n[:bU].data, c)
    add_to_bEV(_H, m[:bEV][j], n[:bEV], c)
    JuMP.add_to_expression!(m[:pCost][j], JuMP.value(n[:pCost]), c)
    if in(0, _H)
        add_to_vec(m[:bLent][j], n[:bLent], c)
        add_to_vec(m[:bES][j], n[:bES], c)
        add_to_pBlock(m[:pBlock][j], n[:pBus], c)
        JuMP.add_to_expression!(m[:GCur][j], JuMP.value(n[:GCur]), c)
    else
        add_to_vec(m[:pBlock][j], n[:pBus], c)
    end
    push!(m[:c][j], c)
end
#=API=# add_to_ipr(#=ipr=# m, #=fpr=# n) = for j=1:J add_to_ipr(m, n, j, j in J1 ? (0,1) : (1,)) end       
function add_to_ipr(#=ipr=# m, #=fpr=# n, j, #=(0,1)/(1,)=# _H)
    c = _c(m)
    add_to_bU(m[:bU][j], n[:bU][j], c)
    add_to_bEV(_H, m[:bEV][j], n[:bEV][j], c)
    JuMP.add_to_expression!(m[:pCost][j], JuMP.value(n[:pCost][j]), c)
    if in(0, _H)
        add_to_vec(m[:bLent][j], n[:bLent][j], c)
        add_to_vec(m[:bES][j], n[:bES][j], c)
        JuMP.add_to_expression!(m[:GCur][j], JuMP.value(n[:GCur][j]), c)
    end
    add_to_vec(m[:pBlock][j], n[:pBlock][j], c)
    push!(m[:c][j], c)
end

add_coupling_constr(m,e,x) = JuMP.@constraint(m, [f=1:(F)T], e ≥ sum(x[j][f] for j=J1)+sum(x[j][_s(f)] for j=J2))
_sm(m, x) = JuMP.@constraint(m, sum(x) == 1)
function complete_LP(m) # Feas.
    e = JuMP.@variable(m)
    add_coupling_constr(m, e, m[:pBlock])
    JuMP.@objective(m, Min, e)
    foreach(x -> _sm(m, x), m[:c])
end
function complete_LP(m, P_A)
    add_coupling_constr(m, P_A, m[:pBlock])
    JuMP.@objective(m, Min, sum(m[:pCost]) + sum(m[:GCur]))
    foreach(x -> _sm(m, x), m[:c])
end

# There are 2 ways to enforce integrality---add to expression or add to coefficients (i.e. raw decisions)
# we opt to follow the definition and add integrality to the resulting expression
# In this case, we observe that indeed there is an advantage that
# for non-integer decisions, proper combination exist at the optimal solution
add_int_constr(m) = for p=(:bU, :bEV, :bLent, :bES), at_j=m[p], e=values(at_j) enforce_integrality(m, e) end
enforce_integrality(m, e) = (a = JuMP.@variable(m, integer=true); JuMP.@constraint(m, a == e))
function LP2IP(#=ipr=# m) # simple bookkeeping
    JuMP.optimize!(m)
    JuMP.termination_status(m) === JuMP.OPTIMAL || error(238945)
    bound = JuMP.objective_value(m)
    @ccall(printf("primal_recover_LP=%e\n"::Cstring; bound::Cdouble)::Cint)
    add_int_constr(m)
    JuMP.set_attribute(m, "TimeLimit", 30) 
    JuMP.optimize!(m)
    ter = JuMP.termination_status(m)
    prf = JuMP.primal_status(m)
    prf === JuMP.FEASIBLE_POINT || error(346379324)
    ter in (JuMP.OPTIMAL, JuMP.TIME_LIMIT) || error(9079)
    bound = JuMP.objective_value(m)
    @ccall(printf("primal_recover_IP=%e\n"::Cstring; bound::Cdouble)::Cint)
    bound
end

end
