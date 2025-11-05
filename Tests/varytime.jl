const (K, F, Krho, my_seed) = map(a -> parse(Int, a), ARGS)
# for S = 0:9, (F, Krho) = ((1, 3), (4, 1))
#     "julia varytime.jl 64 $F $Krho $S" |> println
# end
println("$PROGRAM_FILE> (K, F, Krho, my_seed) = $((K, F, Krho, my_seed))")
import Random; Random.seed!(hash(my_seed));
import Gurobi; const GRB_ENV = Gurobi.Env();
import JuMP, Statistics, JLD2
import JuMP.value as ı
scalar!(X, j, m, x) = (o = m.moi_backend; Gurobi.GRBgetdblattrelement(o, "X", Gurobi.c_column(o, JuMP.index(x[j])), view(X, j)));
value!(X, m, x) = foreach(j -> scalar!(X, j, m, x), eachindex(X));
get_simple_model() = (m = JuMP.direct_model(Gurobi.Optimizer(GRB_ENV)); JuMP.set_silent(m); JuMP.set_attribute(m, "Threads", 1); m);
const DEFAULT_THREADS, THREAD_FOR_MAIN_LOOP, THREAD_FOR_MASTER = Threads.nthreads(:default), 1, 1;
const THREAD_FOR_BLOCKS = DEFAULT_THREADS - THREAD_FOR_MAIN_LOOP - THREAD_FOR_MASTER;
const J, T, rho = (K)THREAD_FOR_BLOCKS, 24, 25/100 * Krho;
const LOG_TIME = 15; 
const mstsolvetime, pairblockrgap, selfblockrgap = Float64[], Float64[], Float64[];
ˈ96ˈ24(t) = (t-1)÷F+1;
abstract type Vertex end # TODO [need to add Qbus etc. to the vertices]
struct Vertexs <: Vertex
    bEV::Vector{Float64}
    bU::Matrix{Float64}
    pBus::Vector{Float64}
    Vertexs(U) = new(
        Vector{Float64}(undef, T),
        Matrix{Float64}(undef, T, U),
        Vector{Float64}(undef, T)
    )
end;
new_vertex(j) = j in Rng1 ? Vertexp(length(D[j].U_1), length(D[j].U_2)) : Vertexs(length(D[j].U));
fillvertex!(v::Vertex, j, X; inn = inn) = ((m, x) = (inn[j], X[j]); foreach(s -> value!(getproperty(v, s), m, getproperty(x, s)), propertynames(v)));
struct Vertexp <: Vertex
    bES::Vector{Float64}
    bLent::Vector{Float64}
    bEV_1::Vector{Float64}
    bEV_2::Vector{Float64}
    bU_1::Matrix{Float64}
    bU_2::Matrix{Float64}
    pBus::Vector{Float64}
    Vertexp(U1, U2) = new(
        Vector{Float64}(undef, T * F),
        Vector{Float64}(undef, T),
        Vector{Float64}(undef, T),
        Vector{Float64}(undef, T),
        Matrix{Float64}(undef, T, U1),
        Matrix{Float64}(undef, T, U2),
        Vector{Float64}(undef, T * F)
    )
end;
function get_C_and_O()
    C = F === 1 ? [
        [10, 9, 9, 9, 10, 12, 15, 18, 20, 18, 16, 15, 14, 15, 16, 18, 22, 28, 32, 30, 26, 20, 15, 12],# Case 1: Flat midday, strong evening peak
        [12, 11, 11, 12, 14, 18, 24, 26, 22, 18, 15, 14, 13, 14, 18, 24, 30, 34, 32, 28, 22, 18, 15, 13],# Case 2: Two peaks (morning + evening), midday dip
        [16, 15, 14, 14, 15, 18, 24, 30, 28, 22, 18, 12, 10, 12, 16, 22, 28, 34, 36, 32, 28, 24, 20, 18],# Case 3: Midday solar effect (cheapest at noon, peaks morning & evening)
        [8, 8, 8, 9, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 36, 34, 30, 26, 20, 14],# Case 4: Steady climb during day, single high plateau evening
        [5, 5, 5, 6, 8, 12, 18, 24, 28, 32, 36, 38, 36, 34, 30, 28, 26, 24, 22, 20, 18, 14, 10, 8]# Case 5: Inverted (very low off-peak overnight, high midday, gentle evening)
    ] : [
        [10, 10, 9, 9, 9, 10, 12, 14, 17, 19, 22, 25, 28, 30, 32, 33, 34, 34, 33, 31, 29, 26, 24, 22, 20, 19, 18, 18, 19, 20, 22, 25, 27, 29, 32, 34, 36, 37, 38, 38, 38, 37, 35, 33, 31, 28, 25, 23, 21, 19, 18, 17, 16, 15, 14, 13, 12, 12, 12, 12, 12, 13, 14, 16, 18, 20, 22, 24, 25, 26, 26, 25, 24, 22, 20, 18, 16, 15, 14, 13, 12, 11, 11, 10, 10, 10, 10, 9, 9, 9, 9, 9, 9, 9, 9, 10], # Morning–Evening Peaks
        [28, 29, 28, 27, 26, 25, 24, 22, 21, 19, 18, 17, 15, 14, 13, 13, 13, 13, 14, 15, 16, 18, 19, 21, 23, 25, 27, 28, 29, 29, 30, 31, 32, 33, 34, 34, 34, 34, 33, 32, 31, 30, 29, 28, 27, 26, 26, 26, 27, 28, 29, 30, 31, 31, 31, 31, 30, 29, 28, 27, 26, 25, 24, 24, 23, 22, 22, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 31, 32, 33, 33, 33, 33, 33, 32, 31, 30, 29, 29, 29, 29, 29, 29, 29, 29, 29], # Midday Solar Dip
        [28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 16, 15, 15, 15, 16, 17, 18, 19, 20, 22, 23, 24, 25, 25, 25, 25, 25, 24, 24, 24, 25, 26, 27, 28, 29, 30, 31, 31, 30, 29, 28, 27, 26, 25, 25, 25, 25, 26, 27, 28, 29, 29, 29, 28, 27, 26, 25, 24, 24, 24, 24, 25, 26, 27, 28, 28, 28, 27, 26, 25, 25, 25, 25, 25, 26, 27, 28, 29, 29, 29, 29, 28, 27, 26, 25, 25, 25, 25, 26, 27, 28, 29, 29], # Night Peak
        [14, 15, 13, 22, 30, 16, 17, 18, 14, 24, 26, 38, 12, 13, 27, 30, 13, 17, 28, 35, 20, 14, 18, 26, 16, 19, 15, 13, 30, 34, 12, 28, 14, 17, 35, 22, 12, 13, 25, 16, 19, 15, 18, 27, 32, 15, 13, 19, 21, 23, 24, 27, 31, 18, 12, 13, 15, 21, 33, 16, 19, 15, 12, 28, 34, 15, 18, 25, 12, 27, 26, 22, 14, 12, 13, 19, 29, 34, 38, 20, 12, 18, 13, 17, 26, 31, 14, 15, 19, 12, 13, 24, 34, 20, 15, 14], # Volatile / Spiky Day
        [8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 12, 12, 13, 13, 14, 15, 15, 16, 17, 18, 18, 19, 20, 21, 21, 22, 23, 23, 24, 25, 25, 26, 27, 27, 28, 29, 30, 30, 31, 31, 32, 33, 33, 34, 34, 35, 35, 36, 36, 36, 37, 37, 37, 37, 37, 38, 38, 38, 38, 38, 37, 37, 37, 37, 36, 36, 36, 35, 35, 34, 34, 33, 33, 32, 32, 31, 30, 30, 29, 28, 27, 27, 26, 26, 25, 25, 24, 24, 24, 24, 24, 23, 23, 22, 22] # Gradual Rising
    ]
    O = [
        [28,28,27,27,28,29,31,33,35,36,37,38,38,38,37,36,35,34,32,31,30,29,29,28],# Case 1: Typical hot day (peak ~38°C around 15:00)
        [29,28,28,28,29,31,33,35,37,39,40,41,42,42,41,40,38,36,34,33,32,31,30,29],# Case 2: Extremely hot day (peak ~42°C, late afternoon peak)
        [27,27,27,27,28,29,30,32,33,34,35,35,35,35,34,33,32,31,30,29,28,28,28,27],# Case 3: Milder hot day (peak ~35°C, smooth curve)
        [32,32,31,31,32,34,36,38,40,42,43,44,44,44,43,42,41,40,38,37,36,35,34,33],# Case 4: Heatwave night (doesn’t cool much at night, peak 44°C)
        [27,27,27,27,28,29,30,33,35,37,38,39,39,39,38,37,36,34,32,31,30,29,28,27]# Case 5: Cool morning, sharp rise, peak ~39°C
    ]
    C[rand(1:5)], O[rand(1:5)]
end;
get_pair_and_self_Rng(J) = (d = round(Int, rho * J); (1:d, d+1:J)); # Rng1, Rng2
prev(t, d, T) = (n = t-d; n<1 ? T+n : n);
pc_P_AC(O, OH, CND, Q_I, COP) = ceil(Int, ((maximum(O) - OH)CND + maximum(Q_I)) / COP);
function gen_ac_data()::Tuple
    CND   = .5rand(1:7) 
    INR   = rand(6:20)  
    COP   = rand(2:.5:4)
    Q_I   = rand(3:9, T)
    Q_BUS = rand(25:35) 
    OH    = rand(24:29) 
    OΔ    = rand(4:9)   
    P_AC  = pc_P_AC(O, OH, CND, Q_I, COP)
    CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC
end;
function add_AC_module!(model, O, CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC)
    pAC = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = P_AC)
    o = JuMP.@variable(model, [1:T], lower_bound = OH-OΔ, upper_bound = OH)
    q = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = Q_BUS)
    JuMP.@constraint(model, [t=1:T], (O[t]-o[t])CND + Q_I[t] -q[t] -pAC[t]COP == (o[t<T ? t+1 : 1]-o[t])INR)
    o, q, pAC
end;
function add_U_module!(model, U)
    bU::Matrix{JuMP.VariableRef} = JuMP.@variable(model, [t = 1:T, i = eachindex(U)], Bin)
    JuMP.@constraint(model, sum(bU; dims = 1) .≥ true)
    pU = JuMP.@expression(model, [t=1:T], sum(sum(bU[prev(t,φ-1,T), i]P for (φ,P) = enumerate(v)) for (i,v) = enumerate(U))) # Vector{JuMP.AffExpr}
    return bU, pU
end;
function add_self_EV_module!(model, P_EV, E_EV) # self means a household in a block with cardinality 1
    bEV, pEV = JuMP.@variable(model, [1:T], Bin), JuMP.@variable(model, [1:T])
    JuMP.@constraint(model, (P_EV.m)bEV .≤ pEV)
    JuMP.@constraint(model, pEV .≤ (P_EV.M)bEV)
    JuMP.@constraint(model, sum(pEV) ≥ E_EV)
    bEV, pEV # bEV can be _inferred from_ pEV
end;
function pc_self_P_BUS(D, U, P_EV, E_EV, O, CND, INR, COP, Q_I, OH, OΔ, P_AC)::Tuple{Bool, Int64}
    success, P_BUS = true, -1
    model = get_simple_model()
    bU, pU = add_U_module!(model, U)
    bEV, pEV = add_self_EV_module!(model, P_EV, E_EV)
    o, q, pAC = add_AC_module!(model, O, CND, INR, COP, Q_I, 0, OH, OΔ, P_AC) # Q_BUS = 0
    pBus = JuMP.@variable(model)
    JuMP.@constraint(model, pBus .≥ D + pU + pEV + pAC) # No G | ES
    JuMP.@objective(model, Min, pBus)
    JuMP.set_attribute(model, "TimeLimit", 15)
    JuMP.optimize!(model)
    ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
    ps === JuMP.FEASIBLE_POINT || return false, P_BUS
    (ts === JuMP.OPTIMAL || ts === JuMP.TIME_LIMIT) || return false, P_BUS
    val = JuMP.objective_value(model)
    val > 0 || return false, P_BUS
    P_BUS = ceil(Int, val)
    success, P_BUS
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
        return bEV_1, pEV_1, bLent, pLent
end;
function add_EV_2_module!(model, P_EV_2, E_EV_2, bLent, pLent)
        bEV_2, pEV_2 = JuMP.@variable(model, [1:T], Bin), JuMP.@variable(model, [1:T])
        JuMP.@constraint(model, bEV_2 .≤ bLent)
        JuMP.@constraint(model, (P_EV_2.m)bEV_2 .≤ pEV_2)
        JuMP.@constraint(model, pEV_2 .≤ (P_EV_2.M)bEV_2)
        JuMP.@constraint(model, sum(pEV_2 + pLent) ≥ E_EV_2)
        return bEV_2, pEV_2
end;
function add_self_circuit_breaker_module!(model, P_BUS, D, pU, pEV, pAC)
    pBus = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = P_BUS)
    JuMP.@constraint(model, pBus .≥ D + pU + pEV + pAC) # No G | ES
    pBus
end;
function add_circuit_breaker_pair_module!(model, P_BUS_1, P_BUS_2, p_ES, G, pLent, pEV_1, pU_1, pAC_1, D_1, pEV_2, pU_2, pAC_2, D_2; T = T, F = F)
    pBus_1 = JuMP.@variable(model, [1:(F)T], lower_bound = -P_BUS_1, upper_bound = P_BUS_1)
    pBus_2 = JuMP.@variable(model, [1:T], lower_bound = 0, upper_bound = P_BUS_2)
    f = ˈ96ˈ24
    JuMP.@constraint(model, [t = 1:(F)T], pBus_1[t] == p_ES.c[t] -p_ES.d[t] -G[t] + pLent[f(t)] + pEV_1[f(t)] + pU_1[f(t)] + pAC_1[f(t)] + D_1[f(t)])
    JuMP.@constraint(model, pBus_2 .≥ pEV_2 + pU_2 + pAC_2 + D_2)
    pBus = JuMP.@variable(model, [1:(F)T])
    JuMP.@constraint(model, [t = 1:(F)T], pBus[t] == pBus_1[t] + pBus_2[f(t)])
    pBus, pBus_1, pBus_2
end;
function add_ES_module!(model, P_ES, E_ES; T = T, F = F)
    pES = ( # eES is dependent variable
        c = JuMP.@variable(model, [1:(F)T], lower_bound = 0),
        d = JuMP.@variable(model, [1:(F)T], lower_bound = 0)
    ); bES = JuMP.@variable(model, [1:(F)T], Bin)
        JuMP.@constraint(model, pES.c .≤ (bES)P_ES.c)
        JuMP.@constraint(model, pES.d .≤ (1 .- bES)P_ES.d)
    eES = JuMP.@variable(model, [t=1:(F)T], lower_bound = t<(F)T ? 0 : E_ES.e, upper_bound = E_ES.M)
    JuMP.@constraint(model, [t=1:(F)T], pES.c[t]*.95/F - pES.d[t]/.95/F == eES[t]-(t>1 ? eES[t-1] : E_ES.i))
    pES, bES, eES
end;
function get_E_ES(Rng)::NamedTuple # # unaltered when scale is changed
    M = rand(Rng) # Max E
    i = rand(0:M) # initial SOC _is_ this value
    e = rand(0:min(M, 21)) # ending SOC should ≥ this value
    (; i, M, e)
end;
function get_a_paired_block(O)::NamedTuple
    while true
        model = get_simple_model() # for a block who has a lender and a borrower house
        JuMP.set_attribute(model, "TimeLimit", 18)
        # 6 lines
        G = rand(0:17, (F)T)
        D_1 = rand(0:5, T)
        P_ES, E_ES = (c = rand(1:6), d = rand(1:6)), get_E_ES(19:55) # unaltered when scale is changed
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
        JuMP.optimize!(model)
        ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
        ps === JuMP.FEASIBLE_POINT || (printstyled("\nget_a_paired_block> re-generating...\n"; color = :yellow); continue)
        (ts === JuMP.OPTIMAL || ts === JuMP.TIME_LIMIT) || (printstyled("\nget_a_paired_block> re-generating...\n"; color = :yellow); continue)
        temp_float64 = ı(temp_x)
        temp_float64 > 0 || (printstyled("\nget_a_paired_block> re-generating...\n"; color = :yellow); continue)
        P_BUS_2 = ceil(Int, temp_float64)
        JuMP.delete(model, temp_c)
        JuMP.delete(model, temp_x)
        JuMP.set_upper_bound.(pBus_2, P_BUS_2)
        temp_x = JuMP.@variable(model) # reuse the local name
        f = ˈ96ˈ24
        JuMP.@constraint(model, [t = 1:(F)T], -temp_x ≤ pES.c[t] -pES.d[t] -G[t] + pLent[f(t)] + pEV_1[f(t)] + pU_1[f(t)] + pAC_1[f(t)] + D_1[f(t)])
        JuMP.@constraint(model, [t = 1:(F)T],  temp_x ≥ pES.c[t] -pES.d[t] -G[t] + pLent[f(t)] + pEV_1[f(t)] + pU_1[f(t)] + pAC_1[f(t)] + D_1[f(t)])
        JuMP.@objective(model, Min, temp_x)
        JuMP.optimize!(model)
        ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
        ps === JuMP.FEASIBLE_POINT || (printstyled("\nget_a_paired_block> re-generating...\n"; color = :yellow); continue)
        (ts === JuMP.OPTIMAL || ts === JuMP.TIME_LIMIT) || (printstyled("\nget_a_paired_block> re-generating...\n"; color = :yellow); continue)
        temp_float64 = ı(temp_x)
        temp_float64 > -1e-5 || (printstyled("\nget_a_paired_block> re-generating...\n"; color = :yellow); continue)
        P_BUS_1 = max(1, ceil(Int, temp_float64))
        return (;P_BUS_1, P_BUS_2, G, P_ES, E_ES, D_1, D_2, U_1, U_2, P_EV_1, P_EV_2,
        E_EV_1, E_EV_2, CND_1, CND_2, INR_1, INR_2, COP_1, COP_2, Q_I_1, Q_I_2,
        Q_BUS_1, Q_BUS_2, OH_1, OH_2, OΔ_1, OΔ_2, P_AC_1, P_AC_2)
    end
end; 
function get_a_self_block(O)::NamedTuple
    while true
        D = rand(0:5, T) # base demand
        U = [rand(1:4, rand(2:5)) for _ = 1:rand(1:4)] # each entry is a cycle vector of an uninterruptible load 
        P_EV, E_EV = (m = rand((1., 1.5)), M = rand(3:7)), rand(10:39)
        CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC = gen_ac_data()
        success, P_BUS = pc_self_P_BUS(D, U, P_EV, E_EV, O, CND, INR, COP, Q_I, OH, OΔ, P_AC)
        success && return (;P_BUS, D, U, P_EV, E_EV, CND, INR, COP, Q_I, Q_BUS, OH, OΔ, P_AC)
        printstyled("get_a_self_block> re-generating...\n"; color = :yellow)
    end
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
function build_cen!(D; cen = cen, Rng1 = Rng1, T = T, F = F)
    pA = map(_ -> zero(JuMP.AffExpr), 1:(F)T)
    for j = 1:J
        addf = ifelse(j ∈ Rng1, add_a_paired_block!, add_a_self_block!)
        nt = addf(cen, D[j])
        e = nt.pBus
        if j ∈ Rng1
            foreach(t -> JuMP.add_to_expression!(pA[t], e[t]), 1:(F)T)
        else
            foreach(t -> JuMP.add_to_expression!(pA[t], e[ˈ96ˈ24(t)]), 1:(F)T)
        end
        print("\rbuild_cen> j = $j / $J = J")
    end
    JuMP.@variable(cen, pA_scalar)
    JuMP.@objective(cen, Min, pA_scalar)
    JuMP.@constraint(cen, pA_scalar .≥ pA)
    nothing
end;
function fill_inn!(X, D; inn = inn, O = O, Rng1 = Rng1)
    z = Threads.Atomic{Int}(J)
    f = function(j)
        p = j ∈ Rng1
        getf = ifelse(p, get_a_paired_block, get_a_self_block)
        D[j] = Dj = getf(O)
        addf = ifelse(p, add_a_paired_block!, add_a_self_block!)
        X[j] = addf(inn[j], Dj)
        Threads.atomic_sub!(z, 1)
        print("\rfill_inn!> rest = $(z.value), j = $j")
    end
    tasks = map(j -> Threads.@spawn(f(j)), 1:J)
    foreach(wait, tasks)
    println()
end;
function solve_mst_and_up_value!(m, s, θ, β)
    JuMP.optimize!(m)
    ts = JuMP.termination_status(m)
    ts === JuMP.OPTIMAL || error("solve_mst> $ts") # The LP should always be solved to OPTIMAL
    push!(mstsolvetime, JuMP.solve_time(m))
    s.ub.x = JuMP.objective_bound(m)
    value!(s.β, m, β)
    value!(s.θ, m, θ)
end;
function shot!(ref)
    s = rEF.x
    @lock mst_lock solve_mst_and_up_value!(model, s, θ, β) # `s` gets updated/mutated here
    s_tmp = ref.x
    setfield!(ref, :x, s) # the ref gets updated here
    setfield!(rEF, :x, s_tmp)
end;
function initialize_out()
    model = get_simple_model()
    JuMP.@variable(model, β[1:(F)T] ≥ 0)
    JuMP.@constraint(model, sum(β) == 1) # ⚠️ special
    JuMP.@variable(model, θ[1:J])
    JuMP.@expression(model, out_obj_tbMax, sum(θ))
    JuMP.@objective(model, Max, out_obj_tbMax)
    # JuMP.@constraint(model, out_obj_tbMax ≤ an_UB)
    model, θ, β
end;
function bilin_expr(j, iˈı::Function, β)
    if j in Rng1
        JuMP.@expression(model, sum(iˈı(p)b for (b, p) = zip(β, X[j].pBus)))
    else
        p = X[j].pBus
        JuMP.@expression(model, sum(iˈı(p[ˈ96ˈ24(t)])β[t] for t = 1:(F)T))
    end
end;
sublog(j) = println("block(j = $j)> no solution, go back to re-optimize...")
function subproblemˈs_duty(j; initialize = false)
    mj = inn[j]
    while true
        s = getfield(ref, :x)
        JuMP.set_objective_function(mj, bilin_expr(j, identity, s.β))
        JuMP.optimize!(mj)
        ps, ts = JuMP.primal_status(mj), JuMP.termination_status(mj)
        ts === JuMP.INTERRUPTED && return
        if ps !== JuMP.FEASIBLE_POINT || (ts !== JuMP.OPTIMAL && ts !== JuMP.TIME_LIMIT)
            JuMP.set_attribute(mj, "Seed", rand(0:2000000000))
            Threads.@spawn(:interactive, sublog(j))
            continue
        end
        if !initialize
            s = getfield(ref, :x)
            s.θ[j] - bilin_expr(j, ı, s.β) > COT || return
        end
        K_VCG[j] === MaxVerNum && return
        K_VCG[j] += 1
        fillvertex!(VCG[j][K_VCG[j]], j, X)
        if j in Rng1
            @lock pairblockrgap_lock push!(pairblockrgap, JuMP.relative_gap(mj))
        else
            @lock selfblockrgap_lock push!(selfblockrgap, JuMP.relative_gap(mj))
        end
        con = JuMP.@build_constraint(θ[j] ≤ bilin_expr(j, ı, β))
        @lock mst_lock JuMP.add_constraint(model, con)
        Threads.atomic_add!(Ncuts, 1)
        return
    end
end;
function subproblemˈs_objbnd!(pvv, j)
    mj = inn[j]
    s = getfield(ref, :x)
    JuMP.set_objective_function(mj, bilin_expr(j, identity, s.β))
    JuMP.set_attribute(mj, "TimeLimit", 120)
    while true
        JuMP.optimize!(mj)
        ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
        if ps === JuMP.FEASIBLE_POINT && (ts === JuMP.OPTIMAL || ts === JuMP.TIME_LIMIT)
            pvv[j] = JuMP.objective_bound(mj)
            return
        end
        JuMP.set_attribute(mj, "TimeLimit", 20)
        printstyled("subproblemˈs_objbnd!> re-solving block $j...\n"; color = :yellow)
    end
end;
function warm()
    tasks = map(j -> Threads.@spawn(subproblemˈs_duty(j; initialize = true)), 1:J)
    foreach(wait, tasks)
    Ncuts.value === J || error(); # each block contributes 1 cut to make the master have a finite initial dual bound
    shot!(ref)
    nothing
end;
next(j, J) = j === J ? 1 : j+1;
ntasksaway(tasks) = count(!istaskdone, tasks); # num of tasks away (i.e. not controllable)
function mainlog(tasks, ref, Ncuts, tabs0)
    a = ntasksaway(tasks)
    ub = ref.x.ub.x
    n = Ncuts.value
    t = round(Int, time() - tabs0) 
    println("main> N_BlockTasks_Away = $a, ub = $ub, Ncuts = $n, $t sec")
end;
function main(train_time, mst_task_ref, tasks)
    tabs0 = time(); tabs1 = tabs0 + train_time # Time control region, do NOT move this line
    #################################################
    Ncuts0 = Ncuts.value
    j = 1
    #################################################
    tlog0 = time() # Logging control region, do NOT move this line
    while proceed_main.x && time() < tabs1 # Run with a time limit, or you manually interrupt
        if time() - tlog0 > LOG_TIME
            Threads.@spawn(:interactive, mainlog(tasks, ref, Ncuts, tabs0))
            tlog0 = time()
        end
        if istaskdone(mst_task_ref.x)
            Ncuts_now = Ncuts.value
            if Ncuts_now !== Ncuts0 # detect if new cuts have been added to the master
                if ntasksaway(tasks) < THREAD_FOR_BLOCKS
                    mst_task_ref.x = Threads.@spawn(shot!(ref)) # master's duty
                    Ncuts0 = Ncuts_now
                end
            end
        end
        while ntasksaway(tasks) < THREAD_FOR_BLOCKS  # for block subproblems
            if istaskdone(tasks[j])
                tasks[j] = Threads.@spawn(subproblemˈs_duty($j))
            end
            j = next(j, J) # go to ask the next block
        end
        GC.safepoint()
    end
    foreach(j -> Gurobi.GRBterminate(JuMP.backend(inn[j])), 1:J)
end;
function main(train_time)
    mst_task_ref = Ref(Threads.@spawn(shot!(ref)))
    tasks = map(_ -> Threads.@spawn(missing), 1:J)
    main_task = Threads.@spawn(main(train_time, mst_task_ref, tasks))
    (main = main_task, master = mst_task_ref, blocks = tasks)
end;
macro get_int_decision(model, expr) return esc(quote
    let e = JuMP.@expression($model, $expr), a
        a = map(_ -> JuMP.@variable($model, integer = true), e)
        JuMP.@constraint($model, a .== e)
        a
    end
end) end;
get_prob_decision(model, I) = (x = JuMP.@variable(model, [1:I], lower_bound = 0); JuMP.@constraint(model, sum(x) == 1); x);
function primal_recovery(model) 
    JuMP.set_attribute(model, "Threads", 4)
    l = [get_prob_decision(model, K_VCG[j]) for j = 1:J]
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
    a = [zero(JuMP.AffExpr) for t = 1:(F)T]
    for j = 1:J
        p = Y[j].pBus
        if j in Rng1
            foreach(t -> JuMP.add_to_expression!(a[t], p[t]), 1:(F)T)
        else
            foreach(t -> JuMP.add_to_expression!(a[t], p[ˈ96ˈ24(t)]), 1:(F)T)
        end
    end
    JuMP.@variable(model, e)
    JuMP.@objective(model, Min, e)
    JuMP.@constraint(model, e .≥ a)
    JuMP.optimize!(model)
    prec_time = JuMP.solve_time(model)
    printstyled("Primal Opt time = $prec_time\n"; color = :cyan)
    ub = Inf
    ps, ts = JuMP.primal_status(model), JuMP.termination_status(model)
    if ps === JuMP.FEASIBLE_POINT && (ts === JuMP.OPTIMAL || ts === JuMP.TIME_LIMIT)
        ub = JuMP.objective_value(model)
    end
    prec_time, ub
end;

const (Rng1, Rng2), (C, O) = get_pair_and_self_Rng(J), get_C_and_O();
const MaxVerNum, proceed_main = 150, Ref(true); # increase this if not sufficient
const COT, an_UB = 0.5/J, 30.0J;
const mst_lock, selfblockrgap_lock, pairblockrgap_lock = ReentrantLock(), ReentrantLock(), ReentrantLock();
const (model, θ, β), inn, Ncuts = initialize_out(), [get_simple_model() for j = 1:J], Threads.Atomic{Int}(0);
const ref, rEF = Ref((θ = fill(an_UB/J, J), β = fill(1/F/T, (F)T), ub = Ref(an_UB))), Ref((θ = fill(an_UB/J, J), β = fill(1/F/T, (F)T), ub = Ref(an_UB)));
##########################################################
# [build inn]
##########################################################
const X, D = Vector{NamedTuple}(undef, J), Vector{NamedTuple}(undef, J); # X is inn's
fill_inn!(X, D); # build the J blocks in parallel, and get the raw Data
foreach(mj -> JuMP.set_objective_sense(mj, JuMP.MIN_SENSE), inn)
const VCG, K_VCG = [[new_vertex(j) for _ = 1:MaxVerNum] for j = 1:J], fill(0, J); # initially the first vertex is invalid, so K_VCG[j] = 0
foreach(mj -> JuMP.set_attribute(mj, "TimeLimit", 45), inn)
warm()

for (train_time, cg_time) = ((0, 0), (300,300), (600,900), (1800,2700))
    if train_time > 0
        foreach(mj -> JuMP.set_attribute(mj, "TimeLimit", 45), inn)
        setfield!(proceed_main, :x, true)
        mainnt = main(train_time);
        wait(mainnt.main); wait(mainnt.master.x); foreach(wait, mainnt.blocks)
    end
    ##########################################################
    # [Statistics]
    ##########################################################
    maximum(K_VCG) < MaxVerNum || printstyled("You must increase MaxVerNum"; color = :yellow);
    temp_f = v -> (minimum(v), Statistics.mean(v), maximum(v));
    Kverm, Kvermu, KverM = temp_f(K_VCG)
    msttimem, msttimemu, msttimeM = temp_f(mstsolvetime)
    selfrgapm, selfrgapmu, selfrgapM = temp_f(selfblockrgap)
    pairrgapm, pairrgapmu, pairrgapM = temp_f(pairblockrgap)
    ##########################################################
    # [post convergent]: recover a valid `lb`
    # ref.x.ub.x is an upper (dual) bound of the master LP, it is invalid _unless_ the Lagrangian convex optimization is solved to global optimality
    # Nonetheless, we can derive a valid lower bound (to the original MIP), by calculating the _exact_ ObjVals of `inn` vector
    ##########################################################
    pvv = Vector{Float64}(undef, J); # primal bound vector, which is the OBJBND counterpart of the θ vector
    fill_pvv_tasks = map(j -> Threads.@spawn(subproblemˈs_objbnd!(pvv, j)), 1:J);
    t = time(); foreach(wait, fill_pvv_tasks); time() - t
    ub = ref.x.ub.x
    lb = sum(pvv)
    cg_rgap = (ub - lb) / lb
    ##########################################################
    # [primal recovery]
    ##########################################################
    prm = JuMP.direct_model(Gurobi.Optimizer(GRB_ENV));
    JuMP.set_silent(prm)
    JuMP.set_attribute(prm, "TimeLimit", cg_time/8)
    prec_time, decen_ub = primal_recovery(prm);
    decen_time = cg_time + prec_time;
    decen_rgap = (decen_ub - lb) / decen_ub
    ##########################################################
    # save the results
    ##########################################################
    H = 2length(Rng1) + length(Rng2);
    S = my_seed;
    rnt = (; K, S, F, rho, J, H, cg_time, cg_rgap, decen_ub, decen_rgap, decen_time, Kverm, Kvermu, KverM, msttimem, msttimemu, msttimeM, selfrgapm, selfrgapmu, selfrgapM, pairrgapm, pairrgapmu, pairrgapM)
    JLD2.@save "CGT$(cg_time)_K$(K)_F$(F)_KR$(Krho)_S$(S).jld2" rnt
    decen_rgap <= 0.0001 && break
end
