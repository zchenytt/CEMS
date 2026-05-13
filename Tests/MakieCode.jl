using CairoMakie

k = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
n = [0, 0, 0, 1, 2, 2, 2, 2, 3, 29, 40]/40

pk = [4, 5, 9]
pn = [1, 2, 3]/40

f = Figure(; size = (500, 250), figure_padding = 0)
ax = Axis(f[1,1]; xlabel = "Multiplier to the Base Solve Time", ylabel = "Proportion of Instances Solved",
xticks = [1, 4, 5, 9, 10], yticks = [0, 3/40, 29/40, 1]);
stairs!(ax, k, n; label = "centralized optimization", step = :post)
scatter!(ax, pk, pn)
scatter!(10, 29/40; color = :tomato)
scatter!(11, 40/40; color = :tomato)
axislegend(ax; position = :lt)

save("cenprofile.pdf", f)

f = Figure(; size = (600, 300), figure_padding = 0)
ax = Axis(f[1,1], xlabel = "Training Time (s)", ylabel = "Relative Gap", title = "F = 1")
ax2 = Axis(f[1,2], xlabel = "Training Time (s)", title = "F = 4")
scatter!(ax, df[1, :decen_time], df[1, :decen_rgap]; color = :blue, label = "ρ = 1/4")
scatter!(ax, df[2, :decen_time], df[1, :decen_rgap]; color = :tomato, label = "ρ = 3/4")
scatter!(ax2, df[3, :decen_time], df[3, :decen_rgap]; color = :blue, label = "ρ = 1/4")
scatter!(ax2, df[4, :decen_time], df[4, :decen_rgap]; color = :tomato, label = "ρ = 3/4")
for r = eachrow(df)
    color = ifelse(r.rho == 0.75, :tomato, :blue)
    a = ifelse(r.F == 4, ax2, ax)
    scatter!(a, r.decen_time, r.decen_rgap; color = color)
end
for r = eachrow(df)
    a = ifelse(r.F == 4, ax2, ax)
    lines!(a, [r.cg_time, r.decen_time], [r.cg_rgap, r.decen_rgap]; color = :silver)
end
axislegend(ax; position = :rt)
axislegend(ax2; position = :rt)
save("timergap2.pdf", f)

using CairoMakie

g(F, t) = [vnt[i].cg_rgap for i = 1:71 if vnt[i].F == F && vnt[i].cg_time == t];
t(F, t) = [vnt[i].decen_time for i = 1:71 if vnt[i].F == F && vnt[i].cg_time == t];
d(F, t) = [vnt[i].decen_rgap for i = 1:71 if vnt[i].F == F && vnt[i].cg_time == t];
o(v) = fill(1, length(v));
f = Figure();

ax = Axis(f[1,1]; ylabel="Relative Gap", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(g(1,0)), g(1,0); color = :cadetblue1)
ax = Axis(f[1,2]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(g(1,300)), g(1,300); color = :cadetblue1)
ax = Axis(f[1,3]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(1,300)), d(1,300); color = :palegreen)
ax = Axis(f[1,4]; xticksvisible=false,xticklabelsvisible=false,title="K=64, F=1, ρ=75%")
boxplot!(ax, o(g(1,900)), g(1,900); color = :cadetblue1)
ax = Axis(f[1,5]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(1,900)), d(1,900); color = :palegreen)

ax = Axis(f[2,1]; ylabel="Time (s)", xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[2,3];xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(1,300)), t(1,300); color = :palegreen)
ax = Axis(f[2,5];xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(1,900)), t(1,900); color = :palegreen)

ax = Axis(f[3,1]; ylabel="Relative Gap", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(g(4,0)), g(4,0); color = :cadetblue1)
ax = Axis(f[3,2]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(g(4,300)), g(4,300); color = :cadetblue1)
ax = Axis(f[3,4]; xticksvisible=false,xticklabelsvisible=false,title="K=64, F=4, ρ=25%")
boxplot!(ax, o(g(4,900)), g(4,900); color = :cadetblue1)
ax = Axis(f[3,6]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(g(4,2700)), g(4,2700); color = :cadetblue1)
ax = Axis(f[3,3]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(4,300)), d(4,300); color = :palegreen)
ax = Axis(f[3,5]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(4,900)), d(4,900); color = :palegreen)
ax = Axis(f[3,7]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(4,2700)), d(4,2700); color = :palegreen)

ax = Axis(f[4,1]; xlabel="0s",ylabel="Time (s)",xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[4,2]; xlabel="300s",xticksvisible=false,xticklabelsvisible=false,yticksvisible=false,yticklabelsvisible=false,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[4,3]; xlabel="300s",xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(4,300)), t(4,300); color = :palegreen)
ax = Axis(f[4,4]; xlabel="900s",xticksvisible=false,xticklabelsvisible=false,yticksvisible=false,yticklabelsvisible=false,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[4,5]; xlabel="900s",xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(4,900)), t(4,900); color = :palegreen)
ax = Axis(f[4,6]; xlabel="2700s",xticksvisible=false,xticklabelsvisible=false,yticksvisible=false,yticklabelsvisible=false,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[4,7]; xlabel="2700s",xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(4,2700)), t(4,2700); color = :palegreen)
save("b.pdf", f)

f = Figure(); # varytime2.pdf
ax = Axis(f[1,1]; ylabel="Relative Gap", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(g(1,0)), g(1,0); color = :cadetblue1)
ax = Axis(f[1,2]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(1,0)), d(1,0); color = :palegreen)
ax = Axis(f[1,3]; xticksvisible=false,xticklabelsvisible=false,title="K=64, F=1, ρ=75%                              ")
boxplot!(ax, o(g(1,300)), g(1,300); color = :cadetblue1)
ax = Axis(f[1,4]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(1,300)), d(1,300); color = :palegreen)
ax = Axis(f[2,1]; ylabel="Time (s)", xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[2,2];xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(1,0)), t(1,0); color = :palegreen)
ax = Axis(f[2,4];xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(1,300)), t(1,300); color = :palegreen)
ax = Axis(f[3,1]; ylabel="Relative Gap", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(g(4,0)), g(4,0); color = :cadetblue1)
ax = Axis(f[3,2]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(4,0)), d(4,0); color = :palegreen)
ax = Axis(f[3,3]; xticksvisible=false,xticklabelsvisible=false,title="K=64, F=4, ρ=25%                              ")
boxplot!(ax, o(g(4,300)), g(4,300); color = :cadetblue1)
ax = Axis(f[3,4]; xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(d(4,300)), d(4,300); color = :palegreen)
ax = Axis(f[4,1]; xlabel = "0s", ylabel="Time (s)", xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[4,2]; xlabel = "0s", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(4,0)), t(4,0); color = :palegreen)
ax = Axis(f[4,3]; xlabel = "300s", xticksvisible=false,xticklabelsvisible=false,yticksvisible=false,yticklabelsvisible=false,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[4,4]; xlabel = "300s", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, o(t(4,300)), t(4,300); color = :palegreen)

using CairoMakie

m(F,t) = [vnt[i].Kvermu for i = 1:71 if vnt[i].F == F && vnt[i].cg_time == t];
M(F,t) = [vnt[i].KverM for i = 1:71 if vnt[i].F == F && vnt[i].cg_time == t];

f = Figure(; figure_padding=0); # Kver.pdf
ax = Axis(f[1,1]; ylabel="Statistic of Cut Number", title = "mean", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, fill(1,10), m(1,300); color = :gold)
ax = Axis(f[1,2]; xticksvisible=false,xticklabelsvisible=false, title = "max")
boxplot!(ax, fill(1,10), M(1,300); color = :lightcoral)
ax = Axis(f[1,3]; xticksvisible=false,xticklabelsvisible=false, title = "mean")
boxplot!(ax, fill(1,10), m(1,900); color = :gold)
ax = Axis(f[1,4]; xticksvisible=false,xticklabelsvisible=false, title = "max")
boxplot!(ax, fill(1,10), M(1,900); color = :lightcoral)
ax = Axis(f[1,5]; title = "mean",xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax = Axis(f[1,6]; title = "max",xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)
ax2 = Axis(f[1,6]; yaxisposition = :right, ylabel = "K=64, F=1, ρ=75%",xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)

ax = Axis(f[2,1]; xlabel = "300s", ylabel="Statistic of Cut Number", xticksvisible=false,xticklabelsvisible=false)
boxplot!(ax, fill(1,10), m(4,300); color = :gold)
ax = Axis(f[2,2]; xticksvisible=false,xticklabelsvisible=false, xlabel = "300s")
boxplot!(ax, fill(1,10), M(4,300); color = :lightcoral)
ax = Axis(f[2,3]; xticksvisible=false,xticklabelsvisible=false, xlabel = "900s")
boxplot!(ax, fill(1,10), m(4,900); color = :gold)
ax = Axis(f[2,4]; xticksvisible=false,xticklabelsvisible=false, xlabel = "900s")
boxplot!(ax, fill(1,10), M(4,900); color = :lightcoral)
ax = Axis(f[2,5]; xticksvisible=false,xticklabelsvisible=false, xlabel = "2700s")
boxplot!(ax, fill(1,10), m(4,2700); color = :gold)
ax = Axis(f[2,6]; xticksvisible=false,xticklabelsvisible=false, xlabel = "2700s")
boxplot!(ax, fill(1,10), M(4,2700); color = :lightcoral)
ax2 = Axis(f[2,6]; yaxisposition = :right, ylabel = "K=64, F=4, ρ=25%",xticksvisible=false,xticklabelsvisible=false,ytickcolor=:white,yticklabelcolor=:white,xgridvisible=false,ygridvisible=false,spinewidth=0)

save("b.pdf", f)



using CairoMakie

function myplot(ax, st, du)
    x = Float64[]
    y = Float64[]
    for (s, d) in zip(st, du)
        e = s + d
        append!(x, [s, s, e, e, NaN])  # NaN breaks the line between pulses
        append!(y, [0, 1, 1, 0, NaN])
    end
    lines!(ax, x, y)
end

fig = Figure()
ax = Axis(fig[1, 1], yticksvisible = false, yticklabelsvisible = false, xticklabelsvisible = false, ylabel = "Coordinator")
st = [0.091016521, 0.152329771, 0.22072411800000002, 0.25008360300000004, 0.255847649, 0.25846846, 0.26308228300000003, 0.26661691600000004, 0.272814642, 0.276925882, 0.282161424, 0.29055184100000003, 0.295933649, 0.29983150000000003, 0.305196257, 0.311476107, 0.32025927200000004, 0.33983670600000004, 0.35286712800000003, 0.36416678900000005, 0.376731409, 0.39775692, 0.42503107900000003, 0.45237902100000005, 0.505055232, 0.5478365070000001, 0.5851411390000001, 0.628356833, 0.6772277590000001, 0.729084873, 0.763440279, 0.774017397, 0.8056601280000001, 1.2314171090000001, 1.288884742, 1.382724764, 1.4639252520000001, 1.497014869, 1.5655856140000002, 1.6719570840000002, 1.756309117, 1.8420523050000002, 1.9372859610000002, 1.97040667, 2.101175366, 2.19528342, 2.405995496, 2.481108153, 2.5605218180000002, 2.584094366, 2.622329331, 2.709760187, 2.749886909, 2.809311322, 2.862984399, 2.961530128, 3.005372792, 3.1191383530000003, 3.1619094170000004, 3.1777344480000003, 3.224377281, 3.3037114030000003, 3.3840169600000003, 3.4330735740000002, 3.4598902920000003, 3.498999227, 3.5259005890000004, 3.571950654, 3.637910139, 3.6743063690000004, 3.733573434, 4.375443452, 4.494356701, 4.7705882410000005, 4.916733917, 5.053359534, 5.157281951000001, 5.205062516, 5.283019004000001, 5.300804895000001, 5.323930623000001, 5.388025451000001, 5.469054571, 5.486017905000001, 5.512625023, 5.52687634, 5.544063324000001, 5.563837297, 5.849542244, 5.964140574, 6.141683889, 7.101619929000001, 7.292409065, 7.360706788000001, 7.3870323430000004, 7.504750117, 8.092261066, 9.176303974000001, 9.237185524000001, 9.313675745000001, 9.335121575, 9.355784899000001, 9.423970866000001, 9.828968471000001];
du = [0.0009250641, 0.001023054, 0.002556086, 0.00306201, 0.001343966, 0.001902819, 0.002716064, 0.002271175, 0.002838135, 0.003499031, 0.007559061, 0.003319979, 0.002774, 0.00229001, 0.003432989, 0.003470898, 0.01174688, 0.01067495, 0.007078886, 0.01092005, 0.01189089, 0.01825809, 0.02500415, 0.03195596, 0.02909803, 0.02723289, 0.03369308, 0.03504992, 0.04456091, 0.03237319, 0.005908012, 0.02040505, 0.04738712, 0.05199003, 0.05595517, 0.07353997, 0.01803589, 0.05277705, 0.06998086, 0.08084297, 0.05468917, 0.0916791, 0.01345515, 0.09826207, 0.07718706, 0.08592987, 0.07031202, 0.06708002, 0.01800203, 0.021626, 0.07756901, 0.03204894, 0.02516818, 0.047683, 0.03579116, 0.03909302, 0.05272603, 0.03213906, 0.0115478, 0.02004504, 0.02610421, 0.01931405, 0.01925802, 0.01841402, 0.02284002, 0.01608706, 0.01806903, 0.01398492, 0.01813006, 0.01224494, 0.01446795, 0.04653597, 0.01169205, 0.01251888, 0.07644296, 0.04922891, 0.04302406, 0.02673697, 0.01476407, 0.01964903, 0.02036214, 0.01138997, 0.01463103, 0.0227201, 0.01104879, 0.01493716, 0.01546788, 0.01084518, 0.01089287, 0.01794004, 0.01515603, 0.06446886, 0.016855, 0.020751, 0.02252817, 0.01423717, 0.009716034, 0.05826402, 0.06702304, 0.01694393, 0.01565814, 0.01851296, 0.01093006, 0.01118112];
xlims!(ax, 0, 10)
myplot(ax, st, du)
axj1 = Axis(fig[2, 1], yticksvisible = false, yticklabelsvisible = false, xticklabelsvisible = false, ylabel = "Paired-Block")
st = [0.001492938, 0.272187483, 0.47855874400000004, 0.9707299070000001, 1.227450221, 1.4074762600000001, 1.5384385610000002, 1.6735034590000002, 2.185201416, 2.363926743, 2.504890785, 2.6624057580000002, 2.790216564, 2.957061619, 3.082981648, 3.2503873590000003, 3.4505255590000004, 3.6355095370000003, 3.9806214860000004, 4.848968568, 5.352460376000001, 5.551762959, 5.678071184, 5.876355455000001, 6.411258376, 8.667629117, 9.156112576]
du = [0.2351301, 0.190177, 0.490489, 0.2478831, 0.1294892, 0.1177301, 0.1306088, 0.134968, 0.1667559, 0.13939, 0.1530929, 0.09935403, 0.1533151, 0.1210668, 0.154819, 0.1755111, 0.176218, 0.2769651, 0.166182, 0.1372571, 0.170747, 0.122303, 0.1540289, 0.1730289, 0.174674, 0.1091211, 0.1340799]
xlims!(axj1, 0, 10)
myplot(axj1, st, du)
axje = Axis(fig[3, 1], yticksvisible = false, yticklabelsvisible = false, xlabel = "Time (s)", ylabel = "Self-Block")
st = [0.144806243, 0.226993625, 0.271880392, 0.306092472, 0.415665857, 0.465484294, 0.509626665, 0.530823158, 0.583532889, 0.679926247, 0.70243252, 0.7599833410000001, 0.823266738, 0.9259941380000001, 0.9935045140000001, 1.096221339, 1.193878422, 1.2112225950000002, 1.343876207, 1.4449826190000001, 1.5469375680000002, 1.646330386, 1.751030617, 1.797022166, 1.906123623, 2.0029391750000003, 2.127067683, 2.2230194780000003, 2.362408163, 2.457517411, 2.6376801640000003, 2.727813031, 2.940505674, 2.978443341, 3.057767042, 3.104606463, 3.154054265, 3.180269984, 3.205049981, 3.233108585, 3.2492432100000004, 3.3019168490000004, 3.363743255, 3.3898747830000002, 3.4402501630000004, 3.524486575, 3.554572426, 3.624624571, 3.804042157, 3.8916316880000004, 4.071299345, 4.268986966, 4.61838895, 5.175548773, 6.229655572, 6.334144781, 7.423711462000001, 7.539360462, 7.625161397]
du = [0.04874015, 0.01855707, 0.02245498, 0.02610803, 0.04134607, 0.03069687, 0.01851702, 0.05011582, 0.03935003, 0.01878595, 0.0255022, 0.04440212, 0.01351905, 0.04376221, 0.02543497, 0.02625799, 0.01547599, 0.02502394, 0.02169108, 0.03616285, 0.03066301, 0.0390172, 0.008929968, 0.0131321, 0.01076508, 0.01365209, 0.03680396, 0.03274107, 0.014956, 0.01286387, 0.015692, 0.01970887, 0.02221107, 0.03180099, 0.0412221, 0.03492904, 0.01691794, 0.0132308, 0.01592183, 0.01382494, 0.01408386, 0.01248288, 0.01676416, 0.009144068, 0.01035118, 0.01339102, 0.01480293, 0.01059914, 0.01122999, 0.01673889, 0.03497505, 0.03770494, 0.03338695, 0.02215099, 0.01567698, 0.02385116, 0.02724099, 0.02178216, 0.02787209]
xlims!(axje, 0, 10)
myplot(axje, st, du)
fig

save("duty.pdf", fig)
