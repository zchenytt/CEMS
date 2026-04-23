module Settings
import JuMP, Gurobi
function Model!(mv::Vector{JuMP.Model}, i, #=with existing ones=# ev::Vector{Gurobi.Env})
    m = JuMP.direct_model(Gurobi.Optimizer(ev[i]))
    JuMP.set_string_names_on_creation(m, false)
    mv[i] = m
end
Model!(mv::Vector{JuMP.Model}, #=with existing ones=# ev::Vector{Gurobi.Env}) = Threads.@threads for i=eachindex(mv)
    Model!(mv, i, ev)
end
printinfo() = (th = map(Threads.nthreads, (:default, :interactive)); println("Settings> Threads=$th"))
end;

import Gurobi, JuMP
const CONFIG = Dict{String,Any}("OutputFlag"=>0,"Threads"=>1);
Env() = Gurobi.Env(CONFIG);
function Env(N::Int)
    v = Vector{Gurobi.Env}(undef, N)
    Threads.@threads for i=eachindex(v)
        v[i] = Env()
    end
    v
end;
function build!(m; N = 80)
    x = JuMP.@variable(m, [1:N], binary=true)
    y = JuMP.@variable(m, [1:N], binary=true)
    z = JuMP.@variable(m, [1:N, 1:N], lower_bound=0)
    JuMP.@constraint(m, [i=1:N, j=1:N], z[i, j] <= x[i])
    JuMP.@constraint(m, [i=1:N, j=1:N], z[i, j] <= y[j])
    JuMP.@constraint(m, [i=1:N, j=1:N], z[i, j] >= x[i] + y[j] - 1)
    JuMP.@objective(m, Min, sum(rand(-1:.0017:1)i for i=z))
end;

function _heavy_fn(ch, s, m)
    JuMP.optimize!(m)
    put!(ch, s)
end

function main(S)
    envs = Env(S)
    inn = similar(envs, JuMP.Model)
    Settings.Model!(inn, envs)
    println("building models in parallel")
    Threads.@threads for s = eachindex(inn)
        m = inn[s]
        build!(m)
        JuMP.set_attribute(m, "TimeLimit", 100. - s)
    end
    println("spawning...")
    ch = Channel{Int}()
    for (s, m)=enumerate(inn)
        Threads.@spawn(_heavy_fn(ch, s, m))
    end
    println("waiting...")
    i = 0
    while i !== S
        s = take!(ch)
        i += 1
        @ccall(printf("%d/%d, s=%d\n"::Cstring; i::Cint, S::Cint, s::Cint)::Cint)
    end
end;
@time main(99)
