module Res
import ..In: G, F, J1, C, GDiv
import JuMP

function build(tks, inn)
    for (j, n)=zip(J1, inn) setindex!(tks, Threads.@spawn(_2(j, n)), j) end
    for (_, t)=zip(J1, tks) wait(t) end
end

_1(j) = G[j] 
function _2(j, #=inn[j]=# m)
    G = _1(j)
    JuMP.@variable(m, 0 ≤ ϖ[f=eachindex(G)] ≤ G[f])
    JuMP.@variable(m, GCur)
    JuMP.@constraint(m, GCur == sum((C ÷ GDiv / F)ϖ for (C,ϖ)=zip(C,ϖ)))
end

end

