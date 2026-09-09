using ImplicitPlots
using Test
import Plots
using DynamicPolynomials: @polyvar
using HomotopyContinuation: @var
import HomotopyContinuation as HC
import CairoMakie
import Makie

const GB = ImplicitPlots.GeometryBasics

@testset "ImplicitPlots.jl" begin

    f(x, y) = (x^4 + y^4 - 1) * (x^2 + y^2 - 2) + x^5 * y
    @test implicit_plot(f; xlims = (-2, 2), ylims = (-2, 2)) isa Plots.Plot

    @polyvar x y
    f2 = (x^4 + y^4 - 1) * (x^2 + y^2 - 2) + x^5 * y
    @test implicit_plot(f2; xlims = (-2, 2), ylims = (-2, 2)) isa Plots.Plot

    @var x y
    f3 = (x^4 + y^4 - 1) * (x^2 + y^2 - 2) + x^5 * y
    @test implicit_plot(f3; xlims = (-2, 2), ylims = (-2, 2)) isa Plots.Plot

    circle(x, y) = x^2 + y^2 - 1
    p = implicit_plot(circle; resolution = 40)
    @test implicit_plot!(p, circle; resolution = 40) === p
    @test implicit_plot!(circle; resolution = 40) === p
    @test implicit_curve!(p, circle; resolution = 40) === p
    @test implicit_curve!(circle; resolution = 40) === p
    @test implicit_plot((x, y) -> 1.0; resolution = 10) isa Plots.Plot
    @test_throws ArgumentError implicit_plot!(nothing, circle)
end

@testset "Function adapters" begin
    f = ImplicitFunction((x, y, z) -> x + 2y + 3z)
    @test f(1, 2, 3) == 14
    @test ImplicitFunction(f) === f
    # Detect arity without evaluating outside the function's domain.
    @test ImplicitFunction((x, y) -> sqrt(x - 2) + y)(3, 0) == 1
    @test_throws ArgumentError ImplicitFunction(x -> x)
    @test_throws ArgumentError implicit_surface!((x, y) -> x + y)
    @test_throws ArgumentError implicit_curve!((x, y, z) -> x + y + z)

    @polyvar x y z
    @test ImplicitFunction(x + 2y + 3z)(1, 2, 3) == 14
    @var a b c
    @test ImplicitFunction(a + 2b + 3c)(1, 2, 3) == 14
    @test ImplicitFunction(HC.System([a + 2b + 3c]))(1, 2, 3) == 14
    @test_throws ArgumentError ImplicitFunction(HC.System([a + b, a - b]))
end


@testset "Surface geometry" begin
    # Unequal axes and a translated center expose coordinate-order/bounds errors.
    ellipsoid(x, y, z) = (x - 2)^2 + 4(y + 1)^2 + (z - 3)^2 / 4 - 1
    f = ImplicitFunction(ellipsoid)
    bounds = (xlims = (0.5, 3.5), ylims = (-2.0, 0.0), zlims = (0.5, 5.5))
    coarse_fig = implicit_plot(f; bounds..., mesh_resolution = 0.2)
    fine_fig = implicit_plot(f; bounds..., mesh_resolution = 0.1)
    coarse = Makie.current_axis(coarse_fig).scene.plots[1][1][]
    fine = Makie.current_axis(fine_fig).scene.plots[1][1][]
    points = GB.coordinates(fine)
    faces = GB.faces(fine)
    @test !isempty(points)
    @test !isempty(faces)
    @test length(faces) > length(GB.faces(coarse))
    @test maximum(p -> abs(ellipsoid(p...)), points) < 0.02
    for i = 1:3
        @test all(p -> values(bounds)[i][1] <= p[i] <= values(bounds)[i][2], points)
    end
    @test all(face -> all(i -> 1 <= i <= length(points), face), faces)
    empty_fig = implicit_plot((x, y, z) -> 1.0; mesh_resolution = 1)
    empty_mesh = Makie.current_axis(empty_fig).scene.plots[1][1][]
    @test isempty(GB.faces(empty_mesh))
    for spacing in (0, -1, Inf, NaN)
        @test_throws ArgumentError implicit_plot(f; mesh_resolution = spacing)
    end
    for lim in ((1, 1), (2, 1), (-Inf, 1))
        @test_throws ArgumentError implicit_plot(f; xlims = lim)
    end
end

@testset "Makie surface plotting" begin
    sphere(x, y, z) = x^2 + y^2 + z^2 - 1
    opts = (xlims = (-1.5, 1.5), mesh_resolution = 0.25)
    fig = implicit_plot(sphere; opts..., size = (400, 400), grid = false)
    @test fig isa Makie.Figure
    ax = Makie.current_axis(fig)
    @test ax isa Makie.Axis3
    @test ax.xgridvisible[] == false
    @test length(ax.scene.plots) == 1
    @test ax.scene.plots[1] isa Makie.Mesh

    @test implicit_plot!(fig, sphere; opts..., wireframe = true, color = :red) === fig
    @test length(ax.scene.plots) == 2
    @test implicit_surface!(ax, sphere; opts..., show_axis = false) === ax
    @test ax.xlabelvisible[] == false
    @test implicit_plot!(sphere; opts...) === ax
    @test implicit_surface!(sphere; opts...) === ax

    @polyvar x y z
    @test implicit_plot(x^2 + y^2 + z^2 - 1; opts...) isa Makie.Figure
    @var a b c
    @test implicit_plot(a^2 + b^2 + c^2 - 1; opts...) isa Makie.Figure
    @test implicit_plot(HC.System([a^2 + b^2 + c^2 - 1]); opts...) isa Makie.Figure

    # The original README's surface remains supported.
    g(x, y, z) =
        (0.3x^2 + 0.5z - 0.3x + 1.2y^2 - 1.1)^2 + (0.7 * (y + 0.5x)^2 + y + 1.2z^2 - 1)^2 -
        0.3
    historical = implicit_plot(g; xlims = (-2, 2), zlims = (-3, 3), mesh_resolution = 0.15)
    @test historical isa Makie.Figure

    # Bounds aliases and explicit limits must map vertices to world coordinates.
    plane = implicit_plot(
        (x, y, z) -> z - 0.4;
        xmin = 2,
        xmax = 3,
        y_min = -2,
        y_max = -1,
        z_min = 0,
        z_max = 1,
        mesh_resolution = 0.25,
    )
    pts = GB.coordinates(Makie.current_axis(plane).scene.plots[1][1][])
    @test !isempty(pts)
    @test all(p -> 2 <= p[1] <= 3 && -2 <= p[2] <= -1 && p[3] ≈ 0.4f0, pts)
    @test implicit_plot((x, y, z) -> 1.0; mesh_resolution = 1) isa Makie.Figure
    @test_throws ArgumentError implicit_surface!(Makie.Figure(), sphere; opts...)
    @test_throws ArgumentError implicit_plot(sphere; opts..., wireframe = :invalid)
    @test_throws ArgumentError implicit_surface!(
        Makie.Axis(Makie.Figure()[1, 1]),
        sphere;
        opts...,
    )

    scene = Makie.Scene()
    @test implicit_surface!(scene, sphere; opts...) === scene
    scene_fig = Makie.Figure()
    lscene = Makie.LScene(scene_fig[1, 1])
    @test implicit_plot!(lscene, sphere; opts..., show_axis = false, grid = false) ===
          lscene
    @test lscene.show_axis[] == false

    explicit = implicit_plot(
        (x, y, z) -> z - 0.4;
        xmin = -10,
        xmax = 10,
        xlims = (2, 3),
        y_min = -10,
        y_max = 10,
        ylims = (-2, -1),
        zlims = (0, 1),
        mesh_resolution = 0.25,
        resolution = (300, 300),
    )
    pts = GB.coordinates(Makie.current_axis(explicit).scene.plots[1][1][])
    @test all(p -> 2 <= p[1] <= 3 && -2 <= p[2] <= -1, pts)
    @test Tuple(GB.widths(explicit.scene.viewport[])) == (300, 300)

    # Exercise the renderer, not just construction of a plot object.
    mktempdir() do dir
        for (name, plot) in (("sphere", fig), ("historical", historical))
            path = joinpath(dir, name * ".png")
            CairoMakie.save(path, plot)
            @test filesize(path) > 1000
        end
    end
end
