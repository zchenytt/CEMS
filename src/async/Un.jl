module Un
import ..In: T, J1, J
import JuMP

function build(tks, inn)
    for j=eachindex(tks) setindex!(tks, Threads.@spawn(_1(j, inn)), j) end
    foreach(wait, tks)
end

get() = [rand(1:4, rand(2:5)) for _ = 1:rand(1:4)] # in one house
_1(j::Int, inn) = add(inn[j], j in J1 ? (0, 1) : (1,))
function add(m, h)
    U = Dict(h => get() for h=h)
    JuMP.@variable(m, bU[h=h, t=1:T, i=eachindex(U[h])], Bin) # house=0 is owning `G`
    JuMP.@variable(m, pU[h=h, t=1:T])
    JuMP.@constraint(m, [h=h, i=eachindex(U[h])], sum(bU[h,t,i] for t=1:T) ≥ 1)
    JuMP.@constraint(m, [h=h, t=1:T], pU[h,t] == sum(
        bU[h, prev(t, k-1), i]P
        for (i,v)=enumerate(U[h]) for (k,P)=enumerate(v)
    )) # the overall power (at each t) across devices, for each house
end
prev(t,d) = (n=t-d; (n<1)T+n)

end