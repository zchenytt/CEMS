module Un
import ..In: T, J1, J2
import JuMP

build(inn) = for (j, h)=zip((J1, J2), ((0,1), (1,))), j=j
    add(inn[j], h)
end

get() = [rand(1:4, rand(2:5)) for _ = 1:rand(1:4)] # in one house

function add(m, #=(0,1) or (1,)=# h)
    U = Dict(h => get() for h=h)
    JuMP.@variable(m, bU[h=h, t=1:T, i=eachindex(U[h])], Bin) # house=0 is owning `G`
    JuMP.@variable(m, pU[h=h, t=1:T])
    JuMP.@constraint(m, [h=h, i=eachindex(U[h])], sum(bU[h,t,i] for t=1:T) ≥ 1)
    # A block i.e. inn[j] might have 2 households, while each house (having a pBus) has multiple U device
    JuMP.@constraint(m, [h=h, t=1:T], pU[h,t] == sum(
        bU[h, prev(t, k-1), i]P
        for (i,v)=enumerate(U[h]) for (k,P)=enumerate(v)
    )) # the overall power (at each t) across devices, for each house
    nothing
end

function prev(t, d)
    n = t-d
    ifelse(n<1, T+n, n)
end

end
