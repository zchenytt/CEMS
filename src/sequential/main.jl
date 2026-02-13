import Random
Random.seed!(hash(50))
include("In.jl");
using .In
foreach(s -> include(string(s, ".jl")), ("Settings", "Res", "Pbus", "Un", "Ac", "Es", "Ev", "Ms", "Ipr"))
include("Train.jl")
import JuMP

set_inn_intfeas(m) = JuMP.set_attribute(m, "IntFeasTol", 1e-9)
const ref = Ref((ub=NaN, θ=fill(NaN,J), β=fill(NaN,(F)T), common=0.));
out, ipr = Settings.Model(), Settings.Model(); # keep expr of 1.coupling, 2.Integer, 3. cost
const COT = 1e-5;
const inn = Settings.Model(J); foreach(set_inn_intfeas, inn)

foreach(x -> x.build(inn), (Res, Es, Ac, Un, Ev))
Res.build_GCur(inn)
Pbus.decide1(inn)
Pbus.decide2(inn, 0)
Ipr.build_ipr(ipr, inn);
Ms.build_master(out, NaN, 1, ref);

const Saturate = fill(false, J); # usable only in sequential programming
Train.dual_train(300, ref, out, inn, ipr, false, Saturate, COT)

Ipr.complete_LP(ipr)
const P_A = Ipr.LP2IP(ipr) + 0.5;
fpr = ipr; # use name `fpr` to hold the current status, while `ipr` should be tied to the min-cost problem

###################
# Min-cost Problem
###################
out = Settings.Model();
Ms.build_master(out, P_A, 0, ref);
# Need a finite initial bound
foreach(j -> Ms.add_initial_cut_for_min_cost_problem(out, fpr, j), 1:J)
JuMP.optimize!(out); ter = JuMP.termination_status(out)
ter === JuMP.OPTIMAL || error("Master(min-cost, initial): $ter")
setfield!(ref, :x, Ms.construct_nt(out));

# This paragraph is trial to get an early error (if exists)
ipr = Settings.Model() # `ipr`=new; `fpr`=old
Ipr.build_ipr(ipr, inn);
Ipr.add_to_ipr(ipr, fpr) # 🗝️
# Let's see if this phase is sufficient
Ipr.complete_LP(ipr, P_A)
Ipr.LP2IP(ipr)

ipr = Settings.Model() # `ipr`=new; `fpr`=old
Ipr.build_ipr(ipr, inn);
Ipr.add_to_ipr(ipr, fpr) # 🗝️
Train.dual_train(300, ref, out, inn, ipr, true, Saturate, COT)
Ipr.complete_LP(ipr, P_A)
Ipr.LP2IP(ipr)

# TODO The idea to remember: any economic problems stems from physical problem first
# so to furnish an initial ub for the master problem (via 1 cut per block),
# we need 1 initial vertex from each block, and then decide the RHS data input of the complicating constraint.
# It is not an issue at all to start with a finite ub for any min-rating problem (as we've done)
# This method of designing economic problem is strongly reasonable in practice 

# [Important] whether use the primal or dual master LP is a complex problem, 
# depending on your OR modeling language, your physical problem, the solver, the algorithm in the solver..
# which one will be better is generally not known a priori
# We just opt to use the dual cutting plane formulation
