import Makie
import GeometryBasics, Meshing

function implicit_plot(
    f::ImplicitFunction{3};
    resolution = (800, 800),
    size = resolution,
    axis = (;),
    figure = (;),
    kwargs...,
)
    fig = Makie.Figure(; size, figure...)
    scene = Makie.Axis3(fig[1, 1]; merge((aspect = :data,), axis)...)
    implicit_surface!(scene, f; kwargs...)
    fig
end
implicit_plot!(p, f::ImplicitFunction{3}; kwargs...) = implicit_surface!(p, f; kwargs...)
implicit_plot!(f::ImplicitFunction{3}; kwargs...) = implicit_surface!(f; kwargs...)
implicit_surface!(f; kwargs...) = implicit_surface!(Makie.current_axis(), f; kwargs...)
function implicit_surface!(fig::Makie.Figure, f; kwargs...)
    implicit_surface!(Makie.current_axis(fig), f; kwargs...)
    fig
end

"""
    implicit_surface!(scene, f; xlims=(-3,3), ylims=xlims, zlims=xlims,
                      color=:steelblue, mesh_resolution=0.04, wireframe=false)

Visualize the implicit surface `f(x,y,z)=0` in the given box. `scene` is a Makie
`Axis3`, `LScene`, or `Scene`; a `Figure` uses its current axis. Without a target,
use Makie's current axis. Returns the target.

`mesh_resolution` is the maximum grid spacing in coordinate units. Extra keywords
are passed to Makie's `mesh!` or `wireframe!`. Historical `x_min`/`xmin`, `x_max`/
`xmax`, and corresponding y/z bounds are accepted; explicit `*lims` take precedence.
"""
function implicit_surface!(
    scene,
    f;
    x_min = -3.0,
    xmin = x_min,
    x_max = 3.0,
    xmax = x_max,
    xlims = (xmin, xmax),
    y_min = xlims[1],
    ymin = y_min,
    y_max = xlims[2],
    ymax = y_max,
    z_min = xlims[1],
    zmin = z_min,
    z_max = xlims[2],
    zmax = z_max,
    ylims = (ymin, ymax),
    zlims = (zmin, zmax),
    color = :steelblue,
    show_axis = true,
    wireframe = false,
    mesh_resolution = 0.04,
    grid = true,
    kwargs...,
)
    g = ImplicitFunction(f)
    g isa ImplicitFunction{3} || throw(ArgumentError("A surface requires three variables."))
    scene isa Union{Makie.Axis3,Makie.LScene,Makie.Scene} || throw(
        ArgumentError(
            "A surface requires a Makie Axis3, LScene, or Scene. Create an axis first.",
        ),
    )
    for lim in (xlims, ylims, zlims)
        length(lim) == 2 && all(isfinite, lim) && lim[1] < lim[2] ||
            throw(ArgumentError("Surface limits must be finite, increasing pairs."))
    end
    mesh_resolution isa Real && isfinite(mesh_resolution) && mesh_resolution > 0 ||
        throw(ArgumentError("mesh_resolution must be a positive, finite grid spacing."))
    wireframe === true ||
        wireframe === false ||
        isnothing(wireframe) ||
        throw(ArgumentError("wireframe must be true, false, or nothing."))

    # Meshing 0.7 replaces SignedDistanceField/GLNormalMesh with sampled values
    # and isosurface. Keep the original grid spacing and marching tetrahedra.
    rx, ry, rz = map((xlims, ylims, zlims)) do lim
        n = max(2, ceil(Int, (lim[2] - lim[1]) / mesh_resolution) + 1)
        range(Float64(lim[1]), Float64(lim[2]); length = n)
    end
    values = [g(x, y, z) for x in rx, y in ry, z in rz]
    points, faces = Meshing.isosurface(values, Meshing.MarchingTetrahedra(), rx, ry, rz)
    m = GeometryBasics.Mesh(
        GeometryBasics.Point3f.(points),
        GeometryBasics.TriangleFace{Int}.(faces),
    )

    # Makie now configures axes separately from mesh plot attributes.
    if scene isa Makie.Axis3
        scene.xgridvisible = grid
        scene.ygridvisible = grid
        scene.zgridvisible = grid
        if !show_axis
            Makie.hidedecorations!(scene)
            Makie.hidespines!(scene)
        end
    else
        if scene isa Makie.LScene
            scene.show_axis = show_axis
        end
        axis = (scene isa Makie.LScene ? scene.scene : scene)[Makie.OldAxis]
        if !isnothing(axis)
            axis.visible = show_axis
            axis.showgrid = (grid, grid, grid)
        end
    end

    if wireframe === nothing || !wireframe
        Makie.mesh!(scene, m; color = color, kwargs...)
    else
        Makie.wireframe!(scene, m; color = color, kwargs...)
    end

    scene
end
