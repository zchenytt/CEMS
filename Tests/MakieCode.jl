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

f = Figure(; size = (300, 300), figure_padding = 0)
ax = Axis(f[1,1], xlabel = "Training Time (s)", ylabel = "Relative Gap", xticks = [25, 50, 75, 100])
for r = eachrow(df)
    color = ifelse(r.rho == 0.75, ifelse(r.F == 4, :red4, :deepskyblue3), ifelse(r.F == 4, :red2, :blue))
    scatter!(ax, r.decen_time, r.decen_rgap; marker = :xcross, color = color)
end
scatter!(ax, df[1, :decen_time], df[1, :decen_rgap]; marker = :xcross, color = :blue, label = "ρ = 1/4, F = 1")
scatter!(ax, df[2, :decen_time], df[2, :decen_rgap]; marker = :xcross, color = :deepskyblue3, label = "ρ = 3/4, F = 1")
scatter!(ax, df[3, :decen_time], df[3, :decen_rgap]; marker = :xcross, color = :red2, label = "ρ = 1/4, F = 4")
scatter!(ax, df[4, :decen_time], df[4, :decen_rgap]; marker = :xcross, color = :red4, label = "ρ = 3/4, F = 4")
axislegend(ax; position = :rt)
save("timergap.pdf", f)

