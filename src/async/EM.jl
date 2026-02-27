"""
    EM

Dual decomposition of an energy management problem.

To start solving a case, configure (F, J, rho) in In.jl:
F = 1 or 4, harder for bigger ones
J = 2 to 100000, harder for bigger ones
rho = 25% or 75% (or other percentages), harder for bigger ones

Then go to Script.jl to set `MaxSec`---the seconds
you'd like to spend on async training.
Change the random seed at the top to test different cases.
"""
module EM
    export Settings, Ms, Ipr, Train
    include("In.jl")
    include("Settings.jl")
    include("L2i.jl")
    include("Ac.jl")
    include("Un.jl")
    include("Ev.jl")
    include("Es.jl")
    include("Res.jl")
    include("Pbus.jl")
    include("Ms.jl")
    include("Ipr.jl")
    include("Train.jl")
end
