module PlotsPltExt

using StepFunctions
using RecipesBase

@recipe function g(f::StepFunction, a::Real, b::Real; connect_vertical=false)
    xs, ys = lines_data(f, a, b)
    if !connect_vertical
        n = length(xs) ÷ 2
        xs = vcat(map(1:n) do k
            return [xs[2k-1], xs[2k], NaN]
        end...)

        ys = vcat(map(1:n) do k
            return [ys[2k-1], ys[2k], NaN]
        end...)
    end

    return xs, ys
end

end
