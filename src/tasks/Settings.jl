module Settings
import JuMP, Gurobi

# Benchmark shows that both `@build_constraint` and `add_constraint` are at the best performance
zerodict!(d) = for k=keys(d) setindex!(d, 0., k) end
set_oc_by_dict(o, d::Dict{JuMP.VariableRef, Float64}) = for (x,c)=d setoc(o, x, c) end

const SAF = JuMP.MOI.ObjectiveFunction{JuMP.MOI.ScalarAffineFunction{Float64}}()

_gcc(o, x) = Gurobi.c_column(o, JuMP.index(x));
_gv!(r, o, x) = Gurobi.GRBgetdblattrelement(o, "X", _gcc(o, x), r);
value(o, x, r) = (_gv!(r, o, x); r.x);

setoc(o, x, c) = JuMP.MOI.modify(o, SAF, JuMP.MOI.ScalarCoefficientChange(JuMP.index(x), c))

# used to add `θ - c'β ≤ cn` cuts (signs of θ and cn are regular), `n == length(x/c)`
addle(o, n::Cint, x::Vector{Cint}, c::Vector{Cdouble}, cn::Cdouble) = Gurobi.GRBaddconstr(o, n, x, c, Gurobi.GRB_LESS_EQUAL, cn, "")

function printinfo() 
    th = map(Threads.nthreads, (:default, :interactive))
    println("Settings> Threads=$th")
end
# The "Crossover=0" option is observed to be too vague (e.g. terminate with a 3% rGap) for certain cases, thus abandoned
const C = Dict{String, Any}("OutputFlag" => 0, "Threads" => 1, "MIPGap" => 0, "MIPGapAbs" => 0, "Method" => 2)
Env() = Gurobi.Env(C) # generate a _new_ one as defined by `Gurobi.Env`
Model() = JuMP.direct_model(Gurobi.Optimizer(Env()))
Model(tks, v) = for i=eachindex(tks) setindex!(tks, Threads.@spawn(setindex!(v, Model(), i)), i) end
function Model(tks)
    v = similar(tks, JuMP.Model)
    Model(tks, v)
    foreach(wait, tks)
    v
end

# [Test functions] (monitor the cpu engagement (e.g. by htop) while testing)
function test_multithreaded_mip_build_and_solve(num_threads, N=80)
    tks = Vector{Task}(undef, num_threads)
    println("test> building empty models...")
    v = Model(tks)
    println("test> filling models...")
    build_test_model(tks, v, N)
    println("test> solving models...")
    solve_test_model(tks, v)
end
function solve_test_model(tks, v)
    for (j, m)=enumerate(v) setindex!(tks, Threads.@spawn(JuMP.optimize!(m)), j) end
    foreach(wait, tks)
end
function build_test_model(tks, v, N)
    for (j, m)=enumerate(v) setindex!(tks, Threads.@spawn(build_test_model(m, N)), j) end
    foreach(wait, tks)
end
function build_test_model(m, N)
    # N indicates how hard the MIP is, e.g. N = 80 is hard
    JuMP.@variable(m, x[1:N], Bin)
    JuMP.@variable(m, y[1:N], Bin)
    JuMP.@variable(m, z[1:N, 1:N] >= 0)
    o = m.moi_backend
    for z=z setoc(o, z, rand(-1:.0017:1)) end
    JuMP.set_objective_sense(m, JuMP.MIN_SENSE)
    # add classic BQP cuts
    JuMP.@constraint(m, [i=1:N, j=1:N], z[i, j] <= x[i])
    JuMP.@constraint(m, [i=1:N, j=1:N], z[i, j] <= y[j])
    JuMP.@constraint(m, [i=1:N, j=1:N], z[i, j] >= x[i] + y[j] - 1)
end

end
