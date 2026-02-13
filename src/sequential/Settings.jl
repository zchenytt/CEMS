module Settings
import JuMP, Gurobi

# The "Crossover=0" option is observed to be too vague (e.g. terminate with a 3% rGap) for certain cases, thus abandoned
const C = Dict{String, Any}("OutputFlag" => 0, "Threads" => 1, "MIPGap" => 0, "MIPGapAbs" => 0, "Method" => 2)
Env() = Gurobi.Env(C) # generate a _new_ one as defined by `Gurobi.Env`
Model() = JuMP.direct_model(Gurobi.Optimizer(Env()))
function Model(N) # still faster than 1-thread serial construction, i.e. [Model() for i=1:N]
    v = Vector{JuMP.Model}(undef, N)
    foreach(wait, [Threads.@spawn(setindex!(v, Model(), i)) for i=eachindex(v)])
    v
end

end
