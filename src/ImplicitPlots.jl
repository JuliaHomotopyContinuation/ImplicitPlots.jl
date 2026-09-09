module ImplicitPlots

export implicit_plot, implicit_plot!, implicit_curve!, implicit_surface!, ImplicitFunction

import Contour
using RecipesBase
import MultivariatePolynomials, StaticPolynomials
import StaticArrays: SVector
const MP = MultivariatePolynomials
const SP = StaticPolynomials

using Requires: @require
function __init__()
    @require HomotopyContinuation = "f213a82b-91d6-5c5d-acf7-10f1c761b327" include("hc.jl")
end

struct ImplicitFunction{N,F}
    f::F
end
ImplicitFunction{N}(f) where {N} = ImplicitFunction{N,typeof(f)}(f)
(IF::ImplicitFunction{2})(x, y) = IF.f(x, y)
(IF::ImplicitFunction{3})(x, y, z) = IF.f(x, y, z)
ImplicitFunction(f::ImplicitFunction) = f

ImplicitFunction(f::MP.AbstractPolynomialLike) = ImplicitFunction(SP.Polynomial(f))
function ImplicitFunction(f::SP.Polynomial)
    if SP.nvariables(f) == 2
        ImplicitFunction{2}((x, y) -> f(SVector(x, y)))
    elseif SP.nvariables(f) == 3
        ImplicitFunction{3}((x, y, z) -> f(SVector(x, y, z)))
    else
        throw(ArgumentError("Given polynomial doesn't have 2 or 3 variables."))
    end
end
function ImplicitFunction(f)
    if applicable(f, 1.0, 1.0)
        ImplicitFunction{2}(f)
    elseif applicable(f, 1.0, 1.0, 1.0)
        ImplicitFunction{3}(f)
    else
        throw(ArgumentError("Provided function does not accept 2 or 3 arguments."))
    end
end

@recipe function implicit(f::ImplicitFunction{2}; aspect_ratio = :equal, resolution = 400)
    xlims --> (-5.0, 5.0)
    xlims = plotattributes[:xlims]
    ylims --> xlims
    ylims = plotattributes[:ylims]

    linewidth --> 1
    grid --> true
    aspect_ratio := aspect_ratio

    rx = range(xlims[1]; stop = xlims[2], length = resolution)
    ry = range(ylims[1]; stop = ylims[2], length = resolution)
    z = [f(x, y) for x in rx, y in ry]

    lvl = Contour.contour(collect(rx), collect(ry), z, 0.0)
    lines = Contour.lines(lvl)
    isempty(lines) && return (Float64[], Float64[])

    clr = get(plotattributes, :linecolor, :dodgerblue)
    for (k, line) in enumerate(lines)
        xs, ys = Contour.coordinates(line)
        @series begin
            seriestype := :path
            linecolor --> clr
            if k > 1
                label := ""
            end
            xs, ys
        end
    end
end
"""
    implicit_plot(f; kwargs...)

Plot the zero set of a two- or three-variable function or polynomial. Plane curves
use Plots; surfaces use Makie (load a backend such as GLMakie or CairoMakie first).
Surface plots return a Makie `Figure`. See [`implicit_surface!`](@ref).
"""
implicit_plot(f; kwargs...) = implicit_plot(ImplicitFunction(f); kwargs...)
implicit_plot(f::ImplicitFunction{2}; kwargs...) = RecipesBase.plot(f; kwargs...)
implicit_plot!(f; kwargs...) = implicit_plot!(ImplicitFunction(f); kwargs...)
implicit_plot!(f::ImplicitFunction{2}; kwargs...) = RecipesBase.plot!(f; kwargs...)
implicit_plot!(p, f; kwargs...) = implicit_plot!(p, ImplicitFunction(f); kwargs...)
implicit_plot!(p::RecipesBase.AbstractPlot, f::ImplicitFunction{2}; kwargs...) =
    RecipesBase.plot!(p, f; kwargs...)
implicit_plot!(p, f::ImplicitFunction{2}; kwargs...) =
    throw(ArgumentError("A plane curve must be added to a Plots plot."))

implicit_curve!(f; kwargs...) = implicit_curve!(ImplicitFunction(f); kwargs...)
implicit_curve!(f::ImplicitFunction{2}; kwargs...) = implicit_plot!(f; kwargs...)
implicit_curve!(p, f; kwargs...) = implicit_curve!(p, ImplicitFunction(f); kwargs...)
implicit_curve!(p, f::ImplicitFunction{2}; kwargs...) = implicit_plot!(p, f; kwargs...)
implicit_curve!(f::ImplicitFunction; kwargs...) =
    throw(ArgumentError("A plane curve requires two variables."))
implicit_curve!(p, f::ImplicitFunction; kwargs...) =
    throw(ArgumentError("A plane curve requires two variables."))

include("3d.jl")

end # module
