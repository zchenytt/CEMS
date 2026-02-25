module L2i
import ..In: J1, J2, T, F, _s
import JuMP

#= There are 2 ways to enforce integrality---add to expression or add to coefficients (i.e. raw decisions)
we opt to follow the definition and add integrality to the resulting expression
In this case, we observe that indeed there is an advantage that
for non-integer decisions, proper combination exist at the optimal solution =#
enforce_integrality(m, e) = (a = JuMP.@variable(m, integer=true); JuMP.@constraint(m, a == e))
_8(v, x) = JuMP.set_lower_bound(v[1], x)
add_int_constr(m) = for p=(:bU, :bEV, :bLent, :bES), at_j=m[p], e=values(at_j) enforce_integrality(m, e) end
function LP2IP(#=ipr=# m, ismC, r)
    JuMP.optimize!(m)
    JuMP.termination_status(m) === JuMP.OPTIMAL || error(1)
    r[:pl] = bound = JuMP.objective_value(m) # primal linear, should = `out`
    # println("primal_recover_LP = $bound")
    add_int_constr(m)
    if ismC
        foreach(c -> _8(c, 1.), m[:c])
        JuMP.set_attribute(m, "TimeLimit", 8)
        JuMP.optimize!(m)
        foreach(c -> _8(c, 0.), m[:c])
    end
    JuMP.set_attribute(m, "TimeLimit", 45)
    # JuMP.set_attribute(m, "OutputFlag", 1)
    JuMP.optimize!(m)
    JuMP.primal_status(m) === JuMP.FEASIBLE_POINT || error(2)
    r[:pi] = bound = JuMP.objective_value(m) # primal integer
    # println("primal_recover_IP = $bound")
    bound
end

add_coupling_constr(m,e,x) = JuMP.@constraint(m, [f=1:(F)T], e≥sum(x[j][f] for j=J1)+sum(x[j][_s(f)] for j=J2))
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

end
