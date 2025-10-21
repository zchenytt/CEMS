import JuMP, Gurobi
import JuMP.value as ı
import LinearAlgebra.⋅ as ⋅
import Statistics, Random, Printf

# This is a experimental algorithm (round check)
# but the performance is slower than the inbox algorithm
# so do not use struct any longer
# and don't pursue type accuracy
# use primitive types is sufficient (nt, functions)

# but the some thoughts are valueble: you don't need an initial artificial bound
# you just manually gives a (evenly spread) trial point
# and collect the first round of cuts to make the master problem bounded

abstract type Vertex end
struct Vertexs <: Vertex
    bEV::Vector{Bool}
    bU::Matrix{Bool}
    pBus::Vector{Float64}
    Vertexs(T, U) = new(
        Vector{Bool}(undef, T),
        Matrix{Bool}(undef, T, U),
        Vector{Float64}(undef, T)
    )
end;
struct Vertexp <: Vertex
    bES::Vector{Bool}
    bLent::Vector{Bool}
    bEV_1::Vector{Bool}
    bEV_2::Vector{Bool}
    bU_1::Matrix{Bool}
    bU_2::Matrix{Bool}
    pBus::Vector{Float64}
    Vertexp(T, U1, U2) = new(
        Vector{Bool}(undef, T),
        Vector{Bool}(undef, T),
        Vector{Bool}(undef, T),
        Vector{Bool}(undef, T),
        Matrix{Bool}(undef, T, U1),
        Matrix{Bool}(undef, T, U2),
        Vector{Float64}(undef, T)
    )
end;
struct Snap
    t::Float64
    ub::Float64
    θ::Vector{Float64}
    β::Vector{Float64}
    Snap(t, ub) = new(t, ub, Vector{Float64}(undef, J), Vector{Float64}(undef, T))
end;
macro get_int_decision(model, expr) return esc(quote
    let e = JuMP.@expression($model, $expr), a
        a = map(_ -> JuMP.@variable($model, integer = true), e)
        JuMP.@constraint($model, a .== e)
        a
    end
end) end;
♭(x) = round(Bool, ı(x));
function newver(j)
    x = X[j]
    if j in Rng1
        _, U1 = size(x.bU_1)
        T, U2 = size(x.bU_2)
        Vertexp(T, U1, U2)
    else
        T, U = size(x.bU)
        Vertexs(T, U)
    end
end;
function fillvertex!(v::Vertexs, x)
    @. v.bEV = ♭(x.bEV)
    @. v.bU = ♭(x.bU)
    @. v.pBus = ı(x.pBus)
    nothing
end;
function fillvertex!(v::Vertexp, x)
    @. v.bES = ♭(x.bES)
    @. v.bLent = ♭(x.bLent)
    @. v.bEV_1 = ♭(x.bEV_1)
    @. v.bEV_2 = ♭(x.bEV_2)
    @. v.bU_1 = ♭(x.bU_1)
    @. v.bU_2 = ♭(x.bU_2)
    @. v.pBus = ı(x.pBus)
    nothing
end;
function get_simple_model()
    m = JuMP.direct_model(Gurobi.Optimizer(GRB_ENV))
    JuMP.set_silent(m)
    JuMP.set_attribute(m, "Threads", 1)
    m
end;
function get_prob_decision(model, v::Vector)
    I = length(v)
    x = JuMP.@variable(model, [1:I], lower_bound = 0)
    JuMP.@constraint(model, sum(x) == 1)
    x
end;
function get_C_and_O()
    C = [
        # Case 1: Flat midday, strong evening peak
        [10, 9, 9, 9, 10, 12, 15, 18, 20, 18, 16, 15, 14, 15, 16, 18, 22, 28, 32, 30, 26, 20, 15, 12],
        # Case 2: Two peaks (morning + evening), midday dip
        [12, 11, 11, 12, 14, 18, 24, 26, 22, 18, 15, 14, 13, 14, 18, 24, 30, 34, 32, 28, 22, 18, 15, 13],
        # Case 3: Midday solar effect (cheapest at noon, peaks morning & evening)
        [16, 15, 14, 14, 15, 18, 24, 30, 28, 22, 18, 12, 10, 12, 16, 22, 28, 34, 36, 32, 28, 24, 20, 18],
        # Case 4: Steady climb during day, single high plateau evening
        [8, 8, 8, 9, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 36, 34, 30, 26, 20, 14],
        # Case 5: Inverted (very low off-peak overnight, high midday, gentle evening)
        [5, 5, 5, 6, 8, 12, 18, 24, 28, 32, 36, 38, 36, 34, 30, 28, 26, 24, 22, 20, 18, 14, 10, 8]
    ]
    O = [
        # Case 1: Typical hot day (peak ~38°C around 15:00)
        [28,28,27,27,28,29,31,33,35,36,37,38,38,38,37,36,35,34,32,31,30,29,29,28],
        # Case 2: Extremely hot day (peak ~42°C, late afternoon peak)
        [29,28,28,28,29,31,33,35,37,39,40,41,42,42,41,40,38,36,34,33,32,31,30,29],
        # Case 3: Milder hot day (peak ~35°C, smooth curve)
        [27,27,27,27,28,29,30,32,33,34,35,35,35,35,34,33,32,31,30,29,28,28,28,27],
        # Case 4: Heatwave night (doesn’t cool much at night, peak 44°C)
        [32,32,31,31,32,34,36,38,40,42,43,44,44,44,43,42,41,40,38,37,36,35,34,33],
        # Case 5: Cool morning, sharp rise, peak ~39°C
        [27,27,27,27,28,29,30,33,35,37,38,39,39,39,38,37,36,34,32,31,30,29,28,27]
    ]
    return C[rand(1:5)], O[rand(1:5)]
end;
function get_pair_and_self_Rng(J)
    d = J÷4
    1:d, d+1:J # Rng1, Rng2
end;
function prev(t, d, T) return (n = t-d; n<1 ? T+n : n) end;
function pc_P_AC(O, OH, CND, Q_I, COP) return ceil(Int, ((maximum(O) - OH)CND + maximum(Q_I)) / COP) end;
function get_E_ES(Rng)::NamedTuple
    M = rand(Rng) # Max E
    i = rand(0:M) # initial SOC _is_ this value
    e = rand(0:min(M, 21)) # ending SOC should ≥ this value
    (; i, M, e)
end;
function add_ES_module!(model, P_ES, E_ES)
    pES = (
        c = JuMP.@variable(model, [1:T], lower_bound = 0),
        d = JuMP.@variable(model, [1:T], lower_bound = 0)
    ); bES = JuMP.@variable(model, [1:T], Bin)
        JuMP.@constraint(model, pES.c .≤ (bES)P_ES.c)
        JuMP.@constraint(model, pES.d .≤ (1 .- bES)P_ES.d)
    eES = JuMP.@variable(model, [t=1:T], lower_bound = t<T ? 0 : E_ES.e, upper_bound = E_ES.M)
    JuMP.@constraint(model, [t=1:T], pES.c[t]*.95 - pES.d[t]/.95 == eES[t]-(t>1 ? eES[t-1] : E_ES.i))
    return pES, bES, eES
end;
function gen_ac_data()::Tuple
    CND   = .5rand(1:7) 
    INR   = rand(6:20)  
    COP   = rand(2:.5:4)
    Q_I   = rand(3:9, T)
    Q_BUS = rand(25:35) 
    OH    = rand(24:29) 
    OΔ    = rand(4:9)   
    P_AC  = pc_P_AC(O, OH, CND, Q_I, COP)
    return CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC
end;
function add_AC_module!(model, O, CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC)
    pAC = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = P_AC)
    o = JuMP.@variable(model, [1:T], lower_bound = OH-OΔ, upper_bound = OH)
    q = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = Q_BUS)
    JuMP.@constraint(model, [t=1:T], (O[t]-o[t])CND + Q_I[t] -q[t] -pAC[t]COP == (o[t<T ? t+1 : 1]-o[t])INR)
    return o, q, pAC
end;
function add_U_module!(model, U)
    bU::Matrix{JuMP.VariableRef} = JuMP.@variable(model, [t = 1:T, i = eachindex(U)], Bin)
    JuMP.@constraint(model, sum(bU; dims = 1) .≥ true)
    pU = JuMP.@expression(model, [t=1:T], sum(sum(bU[prev(t,φ-1,T), i]P for (φ,P) = enumerate(v)) for (i,v) = enumerate(U))) # Vector{JuMP.AffExpr}
    return bU, pU
end;
function add_self_EV_module!(model, P_EV, E_EV)
    bEV, pEV = JuMP.@variable(model, [1:T], Bin), JuMP.@variable(model, [1:T])
    JuMP.@constraint(model, (P_EV.m)bEV .≤ pEV)
    JuMP.@constraint(model, pEV .≤ (P_EV.M)bEV)
    JuMP.@constraint(model, sum(pEV) ≥ E_EV)
    bEV, pEV
end;
function pc_self_P_BUS(D, U, P_EV, E_EV, O, CND, INR, COP, Q_I, OH, OΔ, P_AC)::Int
    model = get_simple_model()
    bU, pU = add_U_module!(model, U)
    bEV, pEV = add_self_EV_module!(model, P_EV, E_EV)
    o, q, pAC = add_AC_module!(model, O, CND, INR, COP, Q_I, 0, OH, OΔ, P_AC) # Q_BUS = 0
    pBus = JuMP.@variable(model)
    JuMP.@constraint(model, pBus .≥ D + pU + pEV + pAC) # No G | ES
    JuMP.@objective(model, Min, pBus)
    @lock insset_lock push!(insset, model)
    JuMP.optimize!(model)
    @lock insset_lock delete!(insset, model)
    ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
    if ps != JuMP.FEASIBLE_POINT || ts ∉ [JuMP.OPTIMAL, JuMP.INTERRUPTED]
        error(string(ps, ts))
    end
    val = JuMP.objective_value(model)
    val > 0 || error("The self household has P_BUS = $val")
    ceil(Int, val) # P_BUS
end;
function add_EV_1_module!(model, P_EV_1, E_EV_1)
    bLent, pLent = JuMP.@variable(model, [1:T], Bin), JuMP.@variable(model, [1:T])
    bEV_1, pEV_1 = JuMP.@variable(model, [1:T], Bin), JuMP.@variable(model, [1:T])
    JuMP.@constraint(model, bEV_1 .≤ bLent)
    JuMP.@constraint(model, (1 .- bLent)P_EV_1.m .≤ pLent)
    JuMP.@constraint(model, pLent .≤ (1 .- bLent)P_EV_1.M)
    JuMP.@constraint(model, (P_EV_1.m)bEV_1 .≤ pEV_1)
    JuMP.@constraint(model, pEV_1 .≤ (P_EV_1.M)bEV_1)
    JuMP.@constraint(model, sum(pEV_1) ≥ E_EV_1)
    bEV_1, pEV_1, bLent, pLent
end;
function add_EV_2_module!(model, P_EV_2, E_EV_2, bLent, pLent)
    bEV_2, pEV_2 = JuMP.@variable(model, [1:T], Bin), JuMP.@variable(model, [1:T])
    JuMP.@constraint(model, bEV_2 .≤ bLent)
    JuMP.@constraint(model, (P_EV_2.m)bEV_2 .≤ pEV_2)
    JuMP.@constraint(model, pEV_2 .≤ (P_EV_2.M)bEV_2)
    JuMP.@constraint(model, sum(pEV_2 + pLent) ≥ E_EV_2)
    bEV_2, pEV_2
end;
function add_self_circuit_breaker_module!(model, P_BUS, D, pU, pEV, pAC)
    pBus = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = P_BUS)
    JuMP.@constraint(model, pBus .≥ D + pU + pEV + pAC) # No G | ES
    pBus
end;
function add_circuit_breaker_pair_module!(model, P_BUS_1, P_BUS_2, p_ES, G, pLent, pEV_1, pU_1, pAC_1, D_1, pEV_2, pU_2, pAC_2, D_2)
    pBus_1 = JuMP.@variable(model, [1:T], lower_bound = -P_BUS_1, upper_bound = P_BUS_1)
    pBus_2 = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = P_BUS_2)
    pBus = JuMP.@variable(model, [1:T])
    JuMP.@constraint(model, pBus .== pBus_1 + pBus_2)
    JuMP.@constraint(model, pBus_1 .== p_ES.c -p_ES.d -G + pLent + pEV_1 + pU_1 + pAC_1 + D_1)
    JuMP.@constraint(model, pBus_2 .≥ pEV_2 + pU_2 + pAC_2 + D_2)
    pBus, pBus_1, pBus_2
end;
bilin_expr(j, iˈı::Function, β) = JuMP.@expression(model, sum(iˈı(p)b for (b, p) = zip(β, X[j].pBus)));
function subproblemˈs_duty(j, ref)  # 0, stuck or quitted
    s = getfield(ref, :x)           # 1. quitted: Error quit vs Normal quit
    mj = inn[j]                     # 2. Normal quit: Can or Cannot provide a cut
    JuMP.@objective(mj, Min, bilin_expr(j, identity, s.β))
    JuMP.optimize!(mj)              # 3. Provide cut: Can or Cannot cut off
    ts = JuMP.termination_status(mj)
    ts ∈ NORMALTTST || error("subproblem j=$j terminate with $ts")
    JuMP.primal_status(mj) == JuMP.FEASIBLE_POINT || return
    ver = newver(j)
    fillvertex!(ver, X[j])
    ver_vec[j] = ver # a by-product
    con_vec[j] = JuMP.@build_constraint(θ[j] ≤ bilin_expr(j, ı, β))
    fun_vec[j] = function(s) # master should try this!
        vio_degree = s.θ[j] - bilin_expr(j, ı, s.β)
        vio_degree > COT, vio_degree
    end
    return
end;
function initialize_out(an_UB)
    model = get_simple_model()
    JuMP.@variable(model, β[1:T] ≥ 0)
    JuMP.@constraint(model, sum(β) == 1) # ⚠️ special
    JuMP.@variable(model, θ[1:J])
    JuMP.@expression(model, out_obj_tbMax, sum(θ))
    JuMP.@objective(model, Max, out_obj_tbMax)
    # JuMP.@constraint(model, out_obj_tbMax ≤ an_UB)
    model, θ, β
end;
function initialize_snap(an_UB)
    snap = Snap(0.0, Inf)
    snap.β .= 1/T
    snap.θ .= an_UB / J
    snap
end;
function add_to_masterˈs_duty(j)
    @lock mst_lock begin
        push!(VCG[j], ver_vec[j])
        JuMP.add_constraint(model, con_vec[j]) # should NOT do a solve next, which is slow
    end
    con_vec[j] = CONVACANT
end;
function shot!() # call this only after `model` is solved to OPTIMAL, and only when needed
    snap = Snap(JuMP.solve_time(model), JuMP.objective_bound(model))
    @. snap.θ = ı(θ)
    @. snap.β = ı(β)
    snap
end;
function get_a_paired_block(O)::NamedTuple
    model = get_simple_model() # for a block who has a lender and a borrower house
    # 6 lines
    G = rand(0:17, T)
    D_1 = rand(0:5, T)
    P_ES, E_ES = (c = rand(1:6), d = rand(1:6)), get_E_ES(19:55)
    U_1 = [rand(1:4, rand(2:5)) for _ = 1:rand(1:4)] # each entry is a cycle vector of an uninterruptible load 
    P_EV_1, E_EV_1 = (m = rand((1., 1.5)), M = rand(3:7)), rand(10:39)
    CND_1, INR_1, COP_1, Q_I_1, Q_BUS_1, OH_1, OΔ_1, P_AC_1 = gen_ac_data()
    # lender house
    pES, bES, eES = add_ES_module!(model, P_ES, E_ES)
    bU_1, pU_1 = add_U_module!(model, U_1)
    bEV_1, pEV_1, bLent, pLent = add_EV_1_module!(model, P_EV_1, E_EV_1)
    o_1, q_1, pAC_1 = add_AC_module!(model, O, CND_1, INR_1, COP_1, Q_I_1, 0, OH_1, OΔ_1, P_AC_1) # Q_BUS = 0
    # 4 lines
    D_2 = rand(0:5, T) # borrower house
    U_2 = [rand(1:4, rand(2:5)) for _ = 1:rand(1:4)] # each entry is a cycle vector of an uninterruptible load 
    P_EV_2, E_EV_2 = (m = rand((1., 1.5)), M = rand(3:7)), rand(10:39)
    CND_2, INR_2, COP_2, Q_I_2, Q_BUS_2, OH_2, OΔ_2, P_AC_2 = gen_ac_data()
    # borrower house
    bU_2, pU_2 = add_U_module!(model, U_2)
    bEV_2, pEV_2 = add_EV_2_module!(model, P_EV_2, E_EV_2, bLent, pLent)
    o_2, q_2, pAC_2 = add_AC_module!(model, O, CND_2, INR_2, COP_2, Q_I_2, 0, OH_2, OΔ_2, P_AC_2) # Q_BUS = 0
    # determine the circuit breaker limit
    pBus_2 = JuMP.@variable(model, [1:T], lower_bound = 0)
    temp_x = JuMP.@variable(model)
    temp_c = JuMP.@constraint(model, pBus_2 .== temp_x)
    JuMP.@constraint(model, pBus_2 .≥ pEV_2 + pU_2 + pAC_2 + D_2)
    JuMP.@objective(model, Min, temp_x)
    @lock insset_lock push!(insset, model)
    JuMP.optimize!(model)
    @lock insset_lock delete!(insset, model)
    ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
    if ps != JuMP.FEASIBLE_POINT || ts ∉ [JuMP.OPTIMAL, JuMP.INTERRUPTED]
        error(string(ps, ts))
    end
    temp_float64 = ı(temp_x)
    temp_float64 > 0 || error("common pBus_2 has value $temp_float64")
    P_BUS_2 = ceil(Int, temp_float64)
    JuMP.delete(model, temp_c)
    JuMP.delete(model, temp_x)
    JuMP.set_upper_bound.(pBus_2, P_BUS_2)
    temp_x = JuMP.@variable(model) # reuse the local name
    JuMP.@constraint(model, -temp_x .≤ pES.c -pES.d -G + pLent + pEV_1 + pU_1 + pAC_1 + D_1)
    JuMP.@constraint(model,  temp_x .≥ pES.c -pES.d -G + pLent + pEV_1 + pU_1 + pAC_1 + D_1)
    JuMP.@objective(model, Min, temp_x)
    @lock insset_lock push!(insset, model)
    JuMP.optimize!(model)
    @lock insset_lock delete!(insset, model)
    ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
    if ps != JuMP.FEASIBLE_POINT || ts ∉ [JuMP.OPTIMAL, JuMP.INTERRUPTED]
        error(string(ps, ts))
    end
    temp_float64 = ı(temp_x)
    temp_float64 > -1e-5 || error("pBus_1 has value $temp_float64")
    P_BUS_1 = max(1, ceil(Int, temp_float64))
    (;P_BUS_1, P_BUS_2, G, P_ES, E_ES, D_1, D_2, U_1, U_2, P_EV_1, P_EV_2,
    E_EV_1, E_EV_2, CND_1, CND_2, INR_1, INR_2, COP_1, COP_2, Q_I_1, Q_I_2,
    Q_BUS_1, Q_BUS_2, OH_1, OH_2, OΔ_1, OΔ_2, P_AC_1, P_AC_2)
end; 
function get_a_self_block(O)::NamedTuple
    D = rand(0:5, T) # base demand
    U = [rand(1:4, rand(2:5)) for _ = 1:rand(1:4)] # each entry is a cycle vector of an uninterruptible load 
    P_EV, E_EV = (m = rand((1., 1.5)), M = rand(3:7)), rand(10:39)
    CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC = gen_ac_data()
    P_BUS = pc_self_P_BUS(D, U, P_EV, E_EV, O, CND, INR, COP, Q_I, OH, OΔ, P_AC)
    (;P_BUS, D, U, P_EV, E_EV, CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC)
end;
function add_a_paired_block!(model, d::NamedTuple)::NamedTuple
    # lender house
    pES, bES, eES = add_ES_module!(model, d.P_ES, d.E_ES)
    bU_1, pU_1 = add_U_module!(model, d.U_1)
    bEV_1, pEV_1, bLent, pLent = add_EV_1_module!(model, d.P_EV_1, d.E_EV_1)
    o_1, q_1, pAC_1 = add_AC_module!(model, O, d.CND_1, d.INR_1, d.COP_1, d.Q_I_1, 0, d.OH_1, d.OΔ_1, d.P_AC_1) # Q_BUS = 0
    # borrower house
    bU_2, pU_2 = add_U_module!(model, d.U_2)
    bEV_2, pEV_2 = add_EV_2_module!(model, d.P_EV_2, d.E_EV_2, bLent, pLent)
    o_2, q_2, pAC_2 = add_AC_module!(model, O, d.CND_2, d.INR_2, d.COP_2, d.Q_I_2, 0, d.OH_2, d.OΔ_2, d.P_AC_2) # Q_BUS = 0
    # circuit breaker pair
    pBus, pBus_1, pBus_2 = add_circuit_breaker_pair_module!(model, d.P_BUS_1, d.P_BUS_2,
        pES, d.G, pLent, pEV_1, pU_1, pAC_1, d.D_1,
        pEV_2, pU_2, pAC_2, d.D_2)
    (;pBus, pBus_1, pBus_2, bLent, bES, bEV_1, bEV_2, bU_1, bU_2, q_1, q_2)
end;
function add_a_self_block!(model, d::NamedTuple)::NamedTuple
    bU, pU = add_U_module!(model, d.U)
    bEV, pEV = add_self_EV_module!(model, d.P_EV, d.E_EV)
    o, q, pAC = add_AC_module!(model, O, d.CND, d.INR, d.COP, d.Q_I, 0, d.OH, d.OΔ, d.P_AC) # Q_BUS = 0
    pBus = add_self_circuit_breaker_module!(model, d.P_BUS, d.D, pU, pEV, pAC)
    (;pBus, bEV, bU, q)
end;
function fill_model_X!(v::Vector, X)
    z = Threads.Atomic{Int}(J)
    f = function(j)
        p = j ∈ Rng1
        X[j] = ifelse(p, add_a_paired_block!, add_a_self_block!)(
            v[j],
            ifelse(p, get_a_paired_block, get_a_self_block)(O)
        )
        Threads.atomic_sub!(z, 1)
        print("\rrest = $(z.value), j = $j")
    end
    tasks, js_remains = map(j -> Threads.@spawn(f(j)), 1:J), Set(1:J)
    t0 = time()
    while !isempty(js_remains)
        progress_j = 0
        for j = js_remains
            istaskdone(tasks[j]) && (progress_j = j; break)
        end
        if progress_j > 0
            pop!(js_remains, progress_j)
            t0 = time()
        elseif time() - t0 > 15
            foreach(Gurobi.GRBterminate ∘ JuMP.backend, insset)
            printstyled("\nWarning: $(time()) terminate all solves\n"; color = :yellow)
            @lock insset_lock empty!(insset)
            t0 = time()
        else
            yield()
        end
    end
    return foreach(wait, tasks)
end;
function primal_recovery(model)
    JuMP.set_attribute(model, "Threads", 8)
    JuMP.unset_silent(model)
    l = map(v -> get_prob_decision(model, v), VCG)
    Y = [j ∈ Rng1 ? (
        bES = @get_int_decision(model, sum((t.bES)l for (l, t) = zip(l[j], VCG[j]))),
        bU_1 = @get_int_decision(model, sum((t.bU_1)l for (l, t) = zip(l[j], VCG[j]))),
        bU_2 = @get_int_decision(model, sum((t.bU_2)l for (l, t) = zip(l[j], VCG[j]))),
        bEV_1 = @get_int_decision(model, sum((t.bEV_1)l for (l, t) = zip(l[j], VCG[j]))),
        bEV_2 = @get_int_decision(model, sum((t.bEV_2)l for (l, t) = zip(l[j], VCG[j]))),
        bLent = @get_int_decision(model, sum((t.bLent)l for (l, t) = zip(l[j], VCG[j]))),
        pBus = JuMP.@expression(model, sum((t.pBus)l for (l, t) = zip(l[j], VCG[j])))
    ) : (
        bU = @get_int_decision(model, sum((t.bU)l for (l, t) = zip(l[j], VCG[j]))),
        bEV = @get_int_decision(model, sum((t.bEV)l for (l, t) = zip(l[j], VCG[j]))),
        pBus = JuMP.@expression(model, sum((t.pBus)l for (l, t) = zip(l[j], VCG[j])))
    ) for j = 1:J]
    JuMP.@variable(model, e)
    JuMP.@constraint(model, e .≥ sum(t.pBus for t = Y))
    JuMP.@objective(model, Min, e)
    JuMP.optimize!(model)
    printstyled("Primal Opt time = $(JuMP.solve_time(model))"; color = :cyan)
    JuMP.termination_status(model) == JuMP.OPTIMAL || error("fails")
    JuMP.objective_value(model)
end;
function warm_up()
    tm0 = time()
    broadcast!(j -> Threads.@spawn(subproblemˈs_duty(j, snp_ref)), tsk_vec, 1:J)
    b = fill(true, J)
    while true
        for j = 1:J
            if b[j]
                t = tsk_vec[j]
                if istaskdone(t)
                    wait(t)
                    b[j] = false
                    if con_vec[j] === CONVACANT
                        error("TODO: no cut feedback initially")
                    else
                        tsk_mst[j] = Threads.@spawn(add_to_masterˈs_duty(j))
                        Printf.@printf("\rwarm_up> rest = %6i, j = %6i | %.0f sec", count(b), j, time() - tm0)
                    end
                end
            end
        end
        any(b) || break
        @lock mst_lock JuMP.optimize!(model) # in place of yield()
    end
    print("\nwarm_up> waiting for master's duties...")
    foreach(wait, tsk_mst)
    JuMP.optimize!(model)
    JuMP.termination_status(model) == JuMP.OPTIMAL || error("master maybe still unbounded, check it")
    println("\rwarm_up> $(mapreduce(length, +, VCG)) cuts added, J = $J, time = $(time() - tm0)")
end;

function main()
    vnv, tm0 = Vector{Int}(undef, J), time()
    snap = shot!()
    setfield!(snp_ref, :x, snap)
    broadcast!(j -> Threads.@spawn(subproblemˈs_duty(j, snp_ref)), tsk_vec, 1:J)
    b = Vector{Bool}(undef, J) # allocate once
    v = Vector{Int}(undef, J) # record the went-back tasks, indexed by i
    m = Vector{Int}(undef, J) # record the violating tasks, indexed by k
    cn = round = 0
    t0 = time()
    while true
        broadcast!(length, vnv, VCG)
        i = 0 # used for collecting tasks went back, into `v`
        k = 0 # used for collecting violating tasks went back, into `m`
        while true
            vn, j = findmin(vnv)
            vn === IMAX && break # [this round is over]
            t = tsk_vec[j]
            if istaskdone(t)
                wait(t)
                if con_vec[j] !== CONVACANT # a (cut + ver + fun) is available
                    is_vio, vio = fun_vec[j](snap)
                    if is_vio
                        tsk_mst[j] = Threads.@spawn(add_to_masterˈs_duty(j)) # if you want to re-Send a task to Block j, you MUST wait for THIS tsk
                        Printf.@printf("\rmain> round = %4i, ub = %.0f, j = %6i, vio = %e, #Cut = %8i | %.0f sec", round, snap.ub, j, vio, cn+=1, time()-tm0)
                        m[k+=1] = j
                    end
                end
                v[i+=1] = j
            end
            vnv[j] = IMAX # do not focus on this block again for this round
        end
        round += 1
        if k !== 0 # has violation
            a = view(b, 1:k) # lightweight
            fill!(a, true)
            while true # wait for master's aux tasks to finish, AND do part-time jobs
                for i = 1:k
                    if a[i]
                        j = m[i]
                        t = tsk_mst[j]
                        if istaskdone(t)
                            wait(t)
                            a[i] = false
                        end
                    end
                end
                any(a) || break
                @lock mst_lock JuMP.optimize!(model) # in place of yield()
            end
            JuMP.optimize!(model)
            JuMP.termination_status(model) == JuMP.OPTIMAL || error("master maybe still unbounded, check it")
            snap = shot!()
            setfield!(snp_ref, :x, snap)
            js = view(v, 1:i)
            broadcast!(j -> Threads.@spawn(subproblemˈs_duty(j, snp_ref)), view(tsk_vec, js), js) # re-Send
            t0 = time() # still making progress
        elseif i === J
            printstyled("main> all tasks returned in a round are not enriching, quit!\n"; color = :cyan)
            return
        elseif time() - t0 > 10
            printstyled("main> Long time no progress, quit. If solution quality inadequate, enlarge the time threshold\n"; color = :yellow)
            return
        end
    end
end;

const my_seed = 44;
Random.seed!(my_seed);

const J = 45 * 253;
const GRB_ENV = Gurobi.Env();
const (Rng1, Rng2) = get_pair_and_self_Rng(J);
const VCG = map(j -> Vector{ifelse(j in Rng1, Vertexp, Vertexs)}(undef, 0), 1:J); # this is the real depot
const T = 24;
const COT = 0.5/J;
const (C, O) = get_C_and_O(); # price and Celsius vector
const IMAX = typemax(Int);
const NORMALTTST = (JuMP.OPTIMAL, JuMP.INTERRUPTED);
const insset = Set{JuMP.Model}();
const insset_lock = ReentrantLock();
const Con = JuMP.ScalarConstraint{JuMP.AffExpr, JuMP.MOI.LessThan{Float64}};
const CONVACANT::Con = JuMP.@build_constraint(zero(JuMP.AffExpr) ≤ -1.0); # initial placeholder, or vacant
const X = Vector{NamedTuple}(undef, J);
const inn = [get_simple_model() for j = 1:J];
fill_model_X!(inn, X)

const ver_vec = map(newver, 1:J); # this is a temporary depot
const con_vec = fill(CONVACANT, J); 
const fun_vec = Vector{Function}(undef, J);
const tsk_vec = Vector{Task}(undef, J); # for the blocks
const tsk_mst = Vector{Task}(undef, J); # for the master

const mst_lock = ReentrantLock();
const prm = get_simple_model();
const model, θ, β = initialize_out(30J); # ⚠️⚠️⚠️
const snp_ref = Ref{Snap}(initialize_snap(30J)); # for the snap

warm_up() # just directly do this, do _not_ need a `foreach(optimize!, inn)` pre-warm_up

main()

snap = shot!()
ub = primal_recovery(prm);
lb = snap.ub
ub - lb

