module Es
import ..In: F, T, J1
import JuMP

build(inn) = for j=J1 add(inn[j], get()) end

function get() # ES data for a household (out of J1) that has `G`
    M = rand(19:55) # Max E
    i = rand(0:M) # initial SOC is this value
    e = rand(0:min(M, 21)) # ending SOC should ≥ this value
    P = Dict(0 => rand(1:6), 1 => rand(1:6)) # Charging(1) and Dis''(0) UB
    (; M, i, e, P)
end
function add(m, ES)
    (; M, i, e, P) = ES
    FT = (F)T
    JuMP.@variable(m, ifelse(t<FT, 0, e) <= eES[t=1:FT] <= M)
    JuMP.@variable(m, pES[t=1:FT, ES_get_charged=(0,1)], lower_bound = 0)
    JuMP.@variable(m, bES[t=1:FT], Bin)
    JuMP.@constraint(m, [t=1:FT, c=(0,1)], pES[t, c] <= ((1-c) + (2c-1)bES[t])P[c])
    JuMP.@constraint(m, [t=1:FT], (eES[t]-(t>1 ? eES[t-1] : i))F == .95pES[t,1] - pES[t,0]/.95)
    nothing
end

end
