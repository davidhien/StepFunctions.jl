module MakiePltExt

using StepFunctions
using Makie

Makie.convert_arguments(::Type{<:Makie.Lines}, f::StepFunction, a, b) = lines_data(f, a, b)

Makie.convert_arguments(::Type{<:Makie.LineSegments}, f::StepFunction, a, b) = lines_data(f, a, b)

Makie.plottype(::StepFunction, a, b) = Makie.Lines

end
