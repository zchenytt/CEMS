module Res
import ..In: G, F, T, J1, C, GDiv
import JuMP

build(inn) = for j=J1 JuMP.@variable(inn[j], 0 ≤ ϖ[f=1:(F)T] ≤ G[j][f]) end
build_GCur(inn) = for j=J1
    m = inn[j]
    ϖ = m[:ϖ] # only inn[j in J1] has [:GCur]
    # this is a (economic) scalar
    JuMP.@expression(m, GCur, sum((C ÷ GDiv / F)ϖ for (C,ϖ)=zip(C,ϖ)))
end

end
