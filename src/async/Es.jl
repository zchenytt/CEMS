module Es
import ..In: F, T, J1
import JuMP

function build(tks, inn)
    for (j, n)=zip(J1, inn) setindex!(tks, Threads.@spawn(_1(n)), j) end
    for (j, t)=zip(J1, tks) wait(t) end
end

function get() # ES data for a household (out of J1) that has `G`
    M = rand(19:55) # Max E
    i = rand(0:M) # initial SOC is this value
    e = rand(0:min(M, 21)) # ending SOC should ≥ this value
    P = Dict(0 => rand(1:6), 1 => rand(1:6)) # Charging(1) and Dis''(0) UB
    (; M, i, e, P)
end
_1(m) = add(m, get())
function add(m, ES)
    (; M, i, e, P) = ES
    FT = (F)T
    JuMP.@variable(m, (t === FT)e <= eES[t=1:FT] <= M)
    JuMP.@variable(m, pES[t=1:FT, ES_get_charged=(0,1)], lower_bound = 0)
    JuMP.@variable(m, bES[t=1:FT], Bin)
    JuMP.@constraint(m, [t=1:FT, c=(0,1)], pES[t, c] <= ((1-c) + (2c-1)bES[t])P[c])
    JuMP.@constraint(m, [t=1:FT], (eES[t]-(t>1 ? eES[t-1] : i))F == .95pES[t,1] - pES[t,0]/.95)
end

end