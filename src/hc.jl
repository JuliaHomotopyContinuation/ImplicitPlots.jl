const HC = HomotopyContinuation

ImplicitFunction(f::HC.ModelKit.Expression) = ImplicitFunction(HC.System([f]))
ImplicitFunction(f::HC.ModelKit.System) = ImplicitFunction(HC.CompiledSystem(f))
function ImplicitFunction(F::HC.AbstractSystem)
    n = HC.nvariables(F)
    n in (2, 3) || throw(ArgumentError("Given system doesn't have 2 or 3 variables."))
    length(F) == 1 || throw(ArgumentError("Expected a system with exactly one equation."))
    ImplicitFunction{n}((xs...) -> first(F(SVector{n}(xs))))
end
