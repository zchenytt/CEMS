module Ipr
import ..In: J, J1, T, F, _t
import ..Settings
import JuMP

_0() = JuMP.AffExpr(0)
_vj(j) = [_0() for _ = Base.OneTo(((F-1)*(in(j,J1))+1) * T)]
function build_ipr(#=ipr=# m, inn) # {c, bU, bEV, bLent, bES, pBlock, pCost, GCur}
    m[:c] = [JuMP.VariableRef[] for j=1:J]
    # These are containers
    m[:bU] = [Dict(k=>_0() for k=keys(n[:bU].data)) for n=inn] # bU[j][h, t, device(i)]
    m[:bEV] = [Dict((h,t)=>_0() for t=1:T for h=n[:h]) for n=inn] # bEV[j][h, slow]
    m[:bLent] = [[_0() for t=1:T] for j=J1] # bLent[j][slow]
    m[:bES] = [[_0() for t=1:(F)T] for j=J1] # bES[j][fast]
    # CB power: for jinJ1 block, allocate one pBlock, otherwise allocate a 1:T pBus.
    m[:pBlock] = map(_vj, 1:J) # pBlock[j][fast/slow]
    # These are scalars
    m[:pCost] = [_0() for j=1:J]
    m[:GCur] = [_0() for j=J1]
end

_c(m) = JuMP.@variable(m, lower_bound = 0)
add_to_bU(d, i, c, v) = for (k,a)=i JuMP.add_to_expression!(d[k], v(a), c) end
add_to_bEV(h, d, x, c, v) = for h=h, t=1:T JuMP.add_to_expression!(d[h,t], v(x[h,t]), c) end
add_to_pBlock(d, x, c, v) = for f=1:(F)T JuMP.add_to_expression!(d[f], sum(v(x[h,_t(f,h)]) for h=(0,1)), c) end
add_to_vec(e,x,c,v)=for (e,x)=zip(e,x) JuMP.add_to_expression!(e,v(x),c) end
function add_to_ipr(iprLk, #=ipr=# m, #=inn[j]=# n, j) # async API
    v, _H = n[:vf], n[:h]
    c = @lock(iprLk, _c(m))
    add_to_bU(m[:bU][j], n[:bU].data, c, v)
    add_to_bEV(_H, m[:bEV][j], n[:bEV], c, v)
    JuMP.add_to_expression!(m[:pCost][j], v(n[:pCost]), c)
    if in(0, _H)
        add_to_vec(m[:bLent][j], n[:bLent], c, v)
        add_to_vec(m[:bES][j], n[:bES], c, v)
        add_to_pBlock(m[:pBlock][j], n[:pBus], c, v)
        JuMP.add_to_expression!(m[:GCur][j], v(n[:GCur]), c)
    else
        add_to_vec(m[:pBlock][j], n[:pBus], c, v)
    end
    push!(m[:c][j], c)
end

function warm_ipr(tks, iprLk, #=ipr=# m, #=fpr=# n, #=edge_purpose_only=# inn)
    for j=eachindex(tks) setindex!(tks, Threads.@spawn(_222(iprLk, m, n, j, inn)), j) end
    foreach(wait, tks)
end
_9(o, r) = x -> Settings.value(o, x, r)
_222(l, m, n, j, inn) = _2(l, m, n, j, inn[j][:h], _9(JuMP.backend(n), inn[j][:r]))
function _2(iprLk, #=ipr=# m, #=fpr=# n, j::Int, _H, v)
    c = @lock(iprLk, _c(m))
    add_to_bU(m[:bU][j], n[:bU][j], c, v)
    add_to_bEV(_H, m[:bEV][j], n[:bEV][j], c, v)
    JuMP.add_to_expression!(m[:pCost][j], v(n[:pCost][j]), c)
    if in(0, _H)
        add_to_vec(m[:bLent][j], n[:bLent][j], c, v)
        add_to_vec(m[:bES][j], n[:bES][j], c, v)
        JuMP.add_to_expression!(m[:GCur][j], v(n[:GCur][j]), c)
    end
    add_to_vec(m[:pBlock][j], n[:pBlock][j], c, v)
    push!(m[:c][j], c)
end

end