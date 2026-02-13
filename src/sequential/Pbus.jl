module Pbus

import ..In: _s, _t, D, G, F, T, J1, C
import JuMP

##########
# APIs
decide1(inn) = for (m, D)=zip(inn, D)
    p = isa(D, Dict)
    decide1(m, (p ? (0,1) : (1,)), (p ? D[1] : D))
end
decide2(inn, #=House0=# h) = for j=J1 decide2(inn[j], h, G[j], D[j][h]) end
##########

_pConH0(s, f, m, h, G, D) = JuMP.@constraint(m, m[:pBus][h,f] == +(
    m[:pEV][h,s] + m[:pLent][s], # EV_charger at House0
    m[:pAC][h,s] + m[:pU][h,s],
    m[:pES][f,1]-m[:pES][f,0], # only at House0
    D[s], -G[f], m[:ϖ][f]
))
_set_lbub(p, E, i) = (JuMP.set_lower_bound(p, (i)E); JuMP.set_upper_bound(p, E))
function decide2(m, #=House0=# h, G, D)
    _1FT, pBus = 1:(F)T, m[:pBus]
    for f=_1FT _pConH0(_s(f), f, m, h, G, D) end
    #==# e = JuMP.@variable(m)
    #==# refs = JuMP.@constraint(m, [f=_1FT, i=1:2], e ≥ (3-2i)pBus[h,f])
    JuMP.@objective(m, Min, e)
    JuMP.set_attribute(m, "TimeLimit", 15)
    JuMP.optimize!(m)
    ter = JuMP.termination_status(m)
    ter === JuMP.OPTIMAL || error("with G pBusH0 optimize: $ter")
    E = JuMP.objective_value(m)
    #==# JuMP.delete(m, e)
    #==# foreach(c -> JuMP.delete(m, c), refs)
    E ≥ 0 || error("PBusH0 < 0")
    E = ceil(E)
    for f=_1FT _set_lbub(pBus[h,f], E, -1) end
end
_add_h(m, _h) = JuMP.@expression(m, h, _h)
function decide1(#=inn[j]=# m, #=(1,)/(0,1)=# _h, #=D[j][1]/D[j]=# D)
    _add_h(m, _h)
    # this is the detailed physics (in arrays)
    JuMP.@variable(m, pBus[h=_h, t=1:((1-h)F+h)T]) # House0's pBus (with `G`) is `(F)T`
    # for single-block only [:pCost], for paired-block also [:GCur]
    # these are (economic) scalars
    JuMP.@expression(m,pCost,sum((C[f]/F)pBus[h,_t(f,h)] for h=_h for f=eachindex(C)))
    h = 1
    JuMP.@constraint(m, [s=1:T], pBus[h,s] == +( D[s],
        m[:pEV][h,s], # # EV_charger at House1
        m[:pAC][h,s] + m[:pU][h,s],
    ))
    #==# e = JuMP.@variable(m)
    #==# refs = JuMP.@constraint(m, [t=1:T], e ≥ pBus[h,t])
    JuMP.@objective(m, Min, e)
    JuMP.set_attribute(m, "TimeLimit", 8)
    JuMP.optimize!(m)
    ter = JuMP.termination_status(m)
    ter === JuMP.OPTIMAL || error("no G pBusH1 optimize: $ter")
    E = JuMP.objective_value(m)
    #==# JuMP.delete(m, e)
    #==# foreach(c -> JuMP.delete(m, c), refs)
    E ≥ 0 || error("PBusH1 < 0")
    E = ceil(E)
    for s=1:T _set_lbub(pBus[h,s], E, 0) end
end

end
