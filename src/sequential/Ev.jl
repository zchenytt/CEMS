module Ev
import ..In: T, J1, J2
import JuMP

build(inn) = (_pair(inn); _single(inn, 1))
_single(inn, #=1=# h) = for j=J2 add(inn[j], h, get()) end
_pair(inn)   = for j=J1 addpair(inn[j], getpair()) end

get() = (l = rand((1., 1.5)), u = rand(3:7), e = rand(10:39)) # for a single house
getpair() = Dict(0 => get(), 1 => get()) # for a paired block
function add(m, h, EV)
    (; l, u, e) = EV
    JuMP.@variable(m, bEV[(h,), 1:T], Bin)
    JuMP.@variable(m, pEV[(h,), 1:T])
    JuMP.@constraint(m, sum(pEV) ≥ e)
    JuMP.@constraint(m, [t=1:T], bEV[h,t]l ≤ pEV[h,t])
    JuMP.@constraint(m, [t=1:T], pEV[h,t] ≤ bEV[h,t]u)
    nothing
end
function addpair(m, EV) # add EV at 2 houses _at once_
    JuMP.@variable(m, bLent[1:T], Bin)
    JuMP.@variable(m, pLent[1:T])
    JuMP.@variable(m, bEV[(0,1), 1:T], Bin)
    JuMP.@variable(m, pEV[(0,1), 1:T])
    JuMP.@constraint(m, [h=(0,1)], sum((h)pLent[t] + pEV[h,t] for t=1:T) ≥ EV[h].e)
    JuMP.@constraint(m, [t=1:T, h=(0,1)], bEV[h,t]EV[h].l ≤ pEV[h,t])
    JuMP.@constraint(m, [t=1:T, h=(0,1)], pEV[h,t] ≤ bEV[h,t]EV[h].u)
    # 0 is the household that owning G
    JuMP.@constraint(m, [t=1:T         ], (1-bLent[t])EV[0].l ≤ pLent[t])
    JuMP.@constraint(m, [t=1:T         ], pLent[t] ≤ (1-bLent[t])EV[0].u)
    JuMP.@constraint(m, [t=1:T, h=(0,1)], bEV[h,t] ≤ bLent[t])
    nothing
end

end
