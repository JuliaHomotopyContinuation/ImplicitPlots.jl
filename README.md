# ImplicitPlots.jl

Plot plane curves and surfaces defined by a function `f(x,y)=0` resp. `f(x,y,z)=0`.

## Plane curves

```julia
using ImplicitPlots, Plots

f(x,y) = (x^4 + y^4 - 1) * (x^2 + y^2 - 2) + x^5 * y
implicit_plot(f; xlims=(-2,2), ylims=(-2,2))
```
<img src="images/example_curve.png" style="max-width:100%" width="400px"></img>

Polynomials following the HomotopyContinuation. jl or MultivariatePolynomials.jl interface are also supported.
```julia
using HomotopyContinuation

@var x y
f2 = (x^4 + y^4 - 1) * (x^2 + y^2 - 2) + x^5 * y
implicit_plot(f2; xlims=(-2,2), ylims=(-2,2))
```

```julia
using DynamicPolynomials

@polyvar x y
f3 = (x^4 + y^4 - 1) * (x^2 + y^2 - 2) + x^5 * y
implicit_plot(f3; xlims=(-2,2), ylims=(-2,2))
```

## Surface

For surfaces you need a Makie backend, such as GLMakie or CairoMakie.
```julia
using ImplicitPlots, HomotopyContinuation, GLMakie

@var x y z
g = (0.3*x^2+0.5z-0.3x+1.2*y^2-1.1)^2+(0.7*(y+0.5x)^2+y+1.2*z^2-1)^2-0.3
implicit_plot(g)
```

Surface plots return a Makie `Figure`. Requires Julia 1.10 or later.

## Options

Pass options as keyword arguments, e.g. `implicit_plot(f; xlims=(-2,2), grid=false)`.
`xlims` defaults to `(-5,5)` for plane curves and `(-3,3)` for surfaces.
`ylims` and, for surfaces, `zlims` default to `xlims`. Use `grid=false` to hide the grid.

For plane curves:

| Option | Default | Description |
| --- | --- | --- |
| `resolution` | `400` | Number of sample points along each axis. Increase for finer curves. |
| `linecolor` | `:dodgerblue` | Curve color. |
| `linewidth` | `1` | Curve line width. |
| `aspect_ratio` | `:equal` | Relative scaling of the axes. |

For surfaces:

| Option | Default | Description |
| --- | --- | --- |
| `mesh_resolution` | `0.04` | Maximum grid spacing in coordinate units. Decrease for finer meshes. |
| `color` | `:steelblue` | Surface or wireframe color. |
| `wireframe` | `false` | Draw triangle edges instead of a filled surface. |
| `show_axis` | `true` | Show axis decorations. |
| `size` | `(800,800)` | Figure size; `resolution=(800,800)` is also accepted. |

Finer sampling requires more time and memory. For surfaces, `resolution` changes
the figure size; `mesh_resolution` controls geometric detail.
Additional curve options are passed to Plots. Additional surface options are passed
to Makie's `mesh!` or `wireframe!`; `axis=(; ...)` and `figure=(; ...)` configure
the Makie axis and figure.
