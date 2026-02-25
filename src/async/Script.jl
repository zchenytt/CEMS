import Random, JuMP
Random.seed!(hash(25))
using EM, EM.In
Settings.printinfo()

begin # containers
    const COT = 1e-5
    const ref = Ref{Ms.nt_type}()
    const otr = Ref{Task}(); # outfun--task's ref
    const tks = Vector{Task}(undef, J)
    const inn = Settings.Model(tks)
    const mst = (f = (p=Settings.Model(), d=Settings.Model()), c = (p=Settings.Model(), d=Settings.Model())) # Feas./Cost.; Primal/Dual
    const rST = Dict(k => NaN for k = (:dl, :du, :pl, :pi))
    const Lk = (ref=ReentrantLock(), d=ReentrantLock(), p=ReentrantLock())
    const Ncuts = Threads.Atomic{Int}(0)
    MaxSec = 900
end;

begin # build test case
    Ms.build_master(mst.f.d, NaN, 1, ref)
    Ms.initialize_inn(inn, mst.f.d[:θ], mst.f.d[:β])
    EM.Res.build(tks, inn)
    EM.Es.build(tks, inn)
    EM.Un.build(tks, inn)
    EM.Ac.build(tks, inn)
    EM.Ev.build(tks, inn)
    EM.Pbus.decide1(tks, inn)
    EM.Pbus.decide2(tks, inn) # if fails, pick other random seeds
    Ipr.build_ipr(mst.f.p, inn)
end;

begin # Feas. problem
    Train.warm_by_inn(tks, ref, mst, inn, Lk, Ncuts, COT) # Feas. only
    Train.set_maxtime(inn, mst.f.d)
    Train.fill_otr(otr, mst.f.d, Lk, ref)
    nwtk = Train.spawn_nwloop(Ncuts.value, 1, otr, tks, Lk, ref, mst.f.d, mst.f.p, inn, COT, Ncuts, min(J, 253), false, MaxSec)
end;

begin # Feas. summary
    Train.wait3(nwtk, otr, tks)
    rST[:du] = ref.x.ub; 
    lba = Threads.Atomic{Float64}(ref.x.common);
    Train.modify_lb(tks, inn, lba, Lk.ref, ref, false);
    rST[:dl] = lba.value;
    EM.L2i.complete_LP(mst.f.p)
    P_A = EM.L2i.LP2IP(mst.f.p, false, rST) + 5.678
    Train.summary(rST)
end;

begin # Min.Cost problem
    Ms.build_master(mst.c.d, P_A, 0, ref)
    Ms.initialize_inn(inn, mst.c.d[:θ], mst.c.d[:β])
    Ms.warm_out_by_ipr(Lk.d, tks, mst.c.d, mst.f.p, inn) # MinCost only
    Ipr.build_ipr(mst.c.p, inn)
    Ipr.warm_ipr(tks, Lk.p, mst.c.p, mst.f.p, inn) # MinCost only
    Ncuts.value = 0
    Train.set_maxtime(inn, mst.c.d)
    Train.fill_otr(otr, mst.c.d, Lk, ref)
    nwtk = Train.spawn_nwloop(Ncuts.value, 1, otr, tks, Lk, ref, mst.c.d, mst.c.p, inn, COT, Ncuts, min(J, 253), true, MaxSec)
end;

begin # Min.Cost summary
    Train.wait3(nwtk, otr, tks)
    rST[:du] = ref.x.ub;
    lba.value = ref.x.common;
    Train.modify_lb(tks, inn, lba, Lk.ref, ref, true);
    rST[:dl] = lba.value;
    EM.L2i.complete_LP(mst.c.p, P_A)
    EM.L2i.LP2IP(mst.c.p, true, rST)
    Train.summary(rST)
end;
