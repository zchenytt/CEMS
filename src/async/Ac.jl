module Ac
import ..In: T, J1, O
import JuMP

function build(tks, inn)
    for j=eachindex(tks) setindex!(tks, Threads.@spawn(_1(j, inn)), j) end
    foreach(wait, tks)
end

_1(j, inn) = add(inn[j], j in J1 ? (0, 1) : (1,))
function add(m, h)
    AC = Dict(h => get() for h=h)
    JuMP.@variable(m, 0 <= pAC[h=h, t=1:T] <= AC[h].P_AC)
    JuMP.@variable(m, AC[h].OH - AC[h].OΔ <= o[h=h, t=1:T] <= AC[h].OH)
    JuMP.@variable(m, 0 <= q[h=h, t=1:T] <= 0)
    JuMP.@constraint(m, [h=h, t=1:T],
        (O[t]-o[h,t])AC[h].CND + AC[h].Q_I[t] -q[h,t] -pAC[h,t]AC[h].COP ==
        (o[h,(t<T)t+1]-o[h,t])AC[h].INR
    )
    nothing
end
_P_AC(OH, CND, Q_I, COP) = ceil(Int, ((maximum(O) - OH)CND + maximum(Q_I)) / COP)
function get()
    CND   = .5rand(1:7)
    INR   = rand(6:20)  
    COP   = rand(2:.5:4)
    Q_I   = rand(3:9, T)
    # Q_BUS = rand(25:35) 
    OH    = rand(24:29) 
    OΔ    = rand(4:9)   
    P_AC  = _P_AC(OH, CND, Q_I, COP)
    (; CND, INR, COP, Q_I, #=Q_BUS,=# OH, OΔ, P_AC)
end

end