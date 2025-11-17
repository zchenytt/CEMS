using CairoMakie

k = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
n = [0, 0, 0, 1, 2, 2, 2, 2, 3, 29, 40]/40

pk = [4, 5, 9]
pn = [1, 2, 3]/40

f = Figure(; size = (500, 250), figure_padding = 0)
ax = Axis(f[1,1]; xlabel = "Multiple of the Base Solve Time", ylabel = "Proportion of Instances Solved",
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

