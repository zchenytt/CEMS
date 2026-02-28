module L2i
import ..Settings
import ..In: J1, J2, T, F, _s
import JuMP, Dates, JLD2
here_now() = Dates.now() + Dates.Hour(8)
function summary(#=result_dict=# r)
    agap = r[:du] - r[:dl]
    rgap = agap / r[:dl]
    err = abs(r[:du] - r[:pl]) / max(abs(r[:du]), abs(r[:pl]))
    rgap_ip = (r[:pi] - r[:dl]) / r[:pi] # this is the global gap
    println("summary> l = $rgap, e = $err, i = $rgap_ip, lagap = $agap")
end

#= There are 2 ways to enforce integrality---add to expression or add to coefficients (i.e. raw decisions)
we opt to follow the definition and add integrality to the resulting expression
In this case, we observe that indeed there is an advantage that
for non-integer decisions, proper combination exist at the optimal solution =#
enforce_integrality(m, e) = (a = JuMP.@variable(m, integer=true); JuMP.@constraint(m, a == e))
_8(v, x) = JuMP.set_lower_bound(v[1], x)
add_int_constr(m) = for p=(:bU, :bEV, :bLent, :bES), at_j=m[p], e=values(at_j) enforce_integrality(m, e) end
function LP2IP(#=ipr=# m, MaxSec, ismC, r)
    JuMP.set_attribute(m, "Threads", 4)
    JuMP.optimize!(m)
    JuMP.termination_status(m) === JuMP.OPTIMAL || error(1)
    tm = JuMP.solve_time(m)
    @ccall(printf("LP2IP> LP solved in %e(s)\n"::Cstring; tm::Cdouble)::Cint)
    r[:pl] = JuMP.objective_value(m) # primal linear, should = `out`
    add_int_constr(m)
    if ismC
        foreach(c -> _8(c, 1.), m[:c])
        JuMP.set_attribute(m, "TimeLimit", 15)
        JuMP.optimize!(m)
        foreach(c -> _8(c, 0.), m[:c])
    end
    Settings.reset_param_gap(m)
    JuMP.set_attribute(m, "TimeLimit", max(60.0, MaxSec/3))
    JuMP.optimize!(m)
    JuMP.primal_status(m) === JuMP.FEASIBLE_POINT || error(JuMP.termination_status(m), JuMP.primal_status(m))
    r[:pi] = bound = JuMP.objective_value(m) # primal integer
    JLD2.save(
        string(ifelse(ismC, "MinC", "Feas"), ".jld2"), # file name
        "r", # key string (irrelevant)
        (t = here_now(), r = r) # time and result
    )
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
