module Ms
import ..In: C, F, T, J, J1, _s, _t
import ..Settings
import JuMP

initialize_inn(inn, θ, β) = for (n, θj)=zip(inn, θ) _2(n, θj, β) end # once for Feas., once for MinCost
_6(m, v, s) = (haskey(m, s) && JuMP.unregister(m, s); setindex!(m, v, s))
_7(o) = x -> Settings._gcc(o, x)
_8(x) = Dict(x => i for (i, x)=enumerate(x))
function _2(n, θj, β)
    x = [β; θj]
    ci = map(_7(JuMP.backend(JuMP.owner_model(θj))), x) # this is fixed
    _6(n, _8(x), :Di)
    _6(n, ci, :ci)
    _6(n, similar(ci, Cdouble), :cd) # modify this vector via cd[i]
    haskey(n, :vf) || setindex!(n, _9(JuMP.backend(n), Ref{Cdouble}()), :vf)
    haskey(n, :r) || setindex!(n, Ref{Cdouble}(), :r)
    JuMP.set_attribute(n, "IntFeasTol", 1e-9)
    JuMP.set_objective_sense(n, JuMP.MIN_SENSE)
end

_pBus(d, _h, p, β, i) = for h=_h, (f,c)=enumerate(C)
    d[p[h,_t(f,h)]] += β[f]+(i)c/F
end
function reset_obj(refLk, ref, m, #=MinCost true; Feas. false=# i::Bool)
    _h, d, o = m[:h], m[:pBusObj], JuMP.backend(m)
    nt = @lock(refLk, ref[])
    has_G = 0 in _h
    has_G && Settings.setoc(o, m[:GCur], Cdouble(i && has_G))
    zerodict!(d)
    _pBus(d, _h, m[:pBus], nt.β, i)
    Settings.set_oc_by_dict(o, d)
end
zerodict!(d) = for k=keys(d) setindex!(d, 0., k) end

const nt_type = @NamedTuple{ub::Float64, θ::Vector{Float64}, β::Vector{Float64}, common::Float64}
function construct_nt(#=out=# m)
    v = m[:vf]
    (
        ub = JuMP.objective_bound(m),
        θ = v.(m[:θ]),
        β = v.(m[:β]),
        common = v(m[:common])
    )
end
construct_nt(βsum::Int) = (ub=Inf, θ=fill(Inf, J), β=fill(βsum/F/T, (F)T), common=NaN)

function _5(m)
    JuMP.@variable(m, β[1:(F)T] ≥ 0)
    JuMP.@variable(m, θ[1:J])
    JuMP.@expression(m, common, JuMP.AffExpr(0))
    β, θ, common
end
function build_master(#=out=# m, P_A::Float64, #=Feas. 1; mC. 0=# i::Int, ref)
    β, θ, common = _5(m)
    isFs = Bool(i)
    isFs || JuMP.add_to_expression!(common, -(P_A)sum(β)) 
    JuMP.@objective(m, Max, common + sum(θ))
    if isFs
        JuMP.@constraint(m, sum(β) == i)
        ref.x = construct_nt(i)
    end
    m[:vf] = _9(JuMP.backend(m), Ref{Cdouble}())
end

function _1(S, B, β, _h, p, cd, Di, v) # the β-pBus term
    for (f, β)=enumerate(β), h=_h
        X = v(p[h,_t(f,h)])
        S += B[f]X
        cd[Di[β]] -= X
    end
    S
end
_9(o, r) = x -> Settings.value(o, x, r)
function get_cn_vio(j, n, out, ref, refLk, i::Bool)
    v = n[:vf]
    Di, cd, _h = n[:Di], n[:cd], n[:h]
    cn = i ? (v(n[:pCost]) + (0 in _h ? v(n[:GCur]) : 0.)) : 0.
    cd .= 0
    nt = @lock(refLk, ref[])
    S = _1(cn, nt.β, out[:β], _h, n[:pBus], cd, Di, v)
    vio = nt.θ[j] - S
    cd[Di[out[:θ][j]]] = 1.
    cn, vio # ALSO cd has been mutated
end

# Feas->MinC Transition
function warm_out_by_ipr(dualLk, tks, out, ipr, inn)
    for j=eachindex(tks) setindex!(tks, Threads.@spawn(_4(dualLk, out, ipr, inn, j)), j) end
    foreach(wait, tks)
end
function _4(dualLk, out, ipr, inn, j)
    n = inn[j]
    Di, ci, cd, has_H0, v = n[:Di], n[:ci], n[:cd], 0 in n[:h], _9(JuMP.backend(ipr), inn[j][:r])
    cn = v(ipr[:pCost][j]) + (has_H0 ? v(ipr[:GCur][j]) : 0.)
    pBlock, i = ipr[:pBlock][j], has_H0 ? identity : _s
    for (f, β)=enumerate(out[:β])
        cd[Di[β]] = -v(pBlock[i(f)])
    end
    cd[Di[out[:θ][j]]] = 1.
    len = Cint(length(ci))
    o = JuMP.backend(out)
    @lock(dualLk, Settings.addle(o, len, ci, cd, cn))
end

end