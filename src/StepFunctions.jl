module StepFunctions
import Base: hash, ==, isequal
import Base: iterate, isdone, length, eltype
import Base: (+), (-), (*), (/), (//), (^)

"""
    struct StepFunction{X<:Real,Y}

A step function is a piecewise constant function.
It is represented by a vector ``x``, a real ``y_0`` and ``y`` as follows:

``f(t) = \\begin{cases} y_0 & \\text{if } t < x_{1} \\\\ y_{i} & \\text{if } x_i \\leq t < x_{i+1} \\\\ y_{\\text{end}} & \\text{if } t \\geq x_{\\text{end}} \\end{cases}``

The values of ``x`` and ``y`` are saved in vectors `xs` and `ys`, respectively.
We must have `length(xs) == length(ys)`. Furthermore, `xs` must be a sorted vector of sorted reals.
"""
struct StepFunction{X<:Real,Y}
    xs::Vector{X}
    y0::Y
    ys::Vector{Y}

    function StepFunction(xs::Vector{X}, y0::Y, ys::Vector{Y}) where {X,Y}
        if length(ys) != length(xs)
            throw(ArgumentError("For inner constructor: length(xs) must be equal to length(ys)"))
        elseif !issorted(xs)
            throw(ArgumentError("xs must be sorted"))
        elseif !isempty(xs) && xs[end] == Inf
            throw(ArgumentError("xs must not contain Inf"))
        else
            Base.require_one_based_indexing(xs)
            Base.require_one_based_indexing(ys)
            xs, y0, ys = to_minimal_stepfct_data(xs, y0, ys)
            new{X,Y}(xs, y0, ys)
        end
    end
end

"""
    StepFunction(xs::Vector,ys::Vector)

Create the step function `StepFunction(xs,ys[1],ys[2:end])` where `xs` is a vector of the step locations and `ys` is a vector of the step values.
Here, `length(xs)+1` must be equal to `length(ys)`.
"""
function StepFunction(xs::Vector, ys::Vector)
    if length(ys) != length(xs) + 1
        throw(ArgumentError("length(xs)+1 must be equal to length(ys)"))
    elseif !issorted(xs)
        throw(ArgumentError("xs must be sorted"))
    elseif !isempty(xs) && xs[end] == Inf
        throw(ArgumentError("xs must not contain Inf"))
    else
        Base.require_one_based_indexing(xs)
        Base.require_one_based_indexing(ys)
        StepFunction(xs, ys[1], ys[2:end])
    end
end

function hash(f::StepFunction, h::UInt)
    return hash(f.xs, hash(f.y0, hash(f.ys, hash(:StepFunction, h))))
end

function ==(f::StepFunction, g::StepFunction)
    return f.xs == g.xs && f.y0 == g.y0 && f.ys == g.ys
end

function isequal(f::StepFunction, g::StepFunction)
    return isequal(f.xs, g.xs) && isequal(f.y0, g.y0) && isequal(f.ys, g.ys)
end

function (f::StepFunction)(x::Real)
    i = findlast(t -> t <= x, f.xs)
    return i === nothing ? f.y0 : f.ys[i]
end

"""
    struct SortedDomainIterator{S,T}

An iterator that iterates over the sorted union of the domains of the step functions.
"""
struct SortedDomainIterator{S,T}
    xs_iter::T
    function SortedDomainIterator(xs_iter::T) where T
        S = promote_type(eltype.(xs_iter)...)
        return new{S,T}(xs_iter)
    end
end

function length(iter::SortedDomainIterator)
    return sum(xs -> length(xs), iter.xs_iter)
end

function iterate(iter::SortedDomainIterator)
    return iterate(iter, collect(map(xs -> firstindex(xs) - 1, iter.xs_iter)))
end

function iterate(iter::SortedDomainIterator{S,T}, state) where {S,T}
    n = length(iter.xs_iter)
    xs_iter = iter.xs_iter
    minval, min_ind = findmin(1:n) do i
        succ_i = state[i] + 1
        xs = xs_iter[i]
        if succ_i <= lastindex(xs)
            return convert(S, xs[succ_i])
        else
            return Inf
        end
    end
    if minval == Inf
        return nothing
    end
    state[min_ind] += 1
    return minval, state
end

function isdone(iter::SortedDomainIterator{S,T}, state) where {S,T}
    return state === nothing || all(zip(iter.xs_iter, state)) do t
        xs, k = t
        return length(xs) == k
    end
end

eltype(::Type{SortedDomainIterator{S,T}}) where {S,T} = S

"""
    struct ValueSweepIterator{X,Y,XS}

Iterates over the values of a step function at the points in a sorted iterator `xs`.
"""
struct ValueSweepIterator{X,Y,XS}
    f::StepFunction{X,Y}
    xs::XS
    #function ValueSweepIterator(f::StepFunction{X,Y}, xs::XS) where {X,Y,XS}
    #    return new{X,Y,XS}(f,xs)
    #end
end

function length(iter::ValueSweepIterator)
    return length(iter.xs)
end

function iterate(iter::ValueSweepIterator)
    t = iterate(iter.xs)
    if t === nothing
        return nothing
    end
    x0, state = t

    i = findlast(x -> x <= x0, iter.f.xs)
    i = (i === nothing ? 0 : i)

    f = iter.f
    y = i == 0 ? f.y0 : f.ys[i]

    return y, (state, i)
end

function iterate(iter::ValueSweepIterator, state)
    xs_state, i = state

    t = iterate(iter.xs, xs_state)
    if t === nothing
        return nothing
    end
    x, xs_state = t

    while i < length(iter.f.xs) && iter.f.xs[i+1] <= x
        i += 1
    end

    f = iter.f
    y = i == 0 ? f.y0 : f.ys[i]

    return y, (xs_state, i)
end


function isdone(iter::ValueSweepIterator, state)
    return isdone(iter.xs, state[1])
end

eltype(::Type{ValueSweepIterator{X,Y,XS}}) where {X,Y,XS} = Y

##
## arithmetic operations with one step function
##
(*)(a, f::StepFunction) = StepFunction(f.xs, a * f.y0, a * f.ys)
(*)(f::StepFunction, a) = StepFunction(f.xs, f.y0 * a, f.ys * a)

(/)(f::StepFunction, a) = StepFunction(f.xs, f.y0 / a, f.ys / a)
(//)(f::StepFunction, a) = StepFunction(f.xs, f.y0 // a, f.ys // a)

(^)(f::StepFunction, a) = StepFunction(f.xs, f.y0^a, f.ys .^ a)

##
## arithmetic operations with two step functions
##

function (+)(fcts::StepFunction...)
    dom_it = SortedDomainIterator(map(f -> f.xs, fcts))
    xs = unique(dom_it)
    ys_its = map(f -> ValueSweepIterator(f, xs), fcts)
    ys = [+(y...) for y in zip(ys_its...)]
    return StepFunction(xs, sum(f -> f.y0, fcts), ys)
end

function (-)(f::StepFunction, g::StepFunction)
    dom_it = SortedDomainIterator([f.xs, g.xs])
    xs = unique(dom_it)
    it_f = ValueSweepIterator(f, xs)
    it_g = ValueSweepIterator(g, xs)

    ys = [x - y for (x, y) in zip(it_f, it_g)]
    return StepFunction(xs, f.y0 - g.y0, ys)
end

function (*)(fcts::StepFunction...)
    dom_it = SortedDomainIterator(map(f -> f.xs, fcts))
    xs = unique(dom_it)
    ys_its = map(f -> ValueSweepIterator(f, xs), fcts)
    ys = [*(y...) for y in zip(ys_its...)]
    return StepFunction(xs, prod(f -> f.y0, fcts), ys)
end

function (/)(f::StepFunction, g::StepFunction)
    dom_it = SortedDomainIterator([f.xs, g.xs])
    xs = unique(dom_it)
    it_f = ValueSweepIterator(f, xs)
    it_g = ValueSweepIterator(g, xs)

    ys = [x / y for (x, y) in zip(it_f, it_g)]
    return StepFunction(xs, f.y0 / g.y0, ys)
end

function (//)(f::StepFunction, g::StepFunction)
    dom_it = SortedDomainIterator([f.xs, g.xs])
    xs = unique(dom_it)
    it_f = ValueSweepIterator(f, xs)
    it_g = ValueSweepIterator(g, xs)

    ys = [x // y for (x, y) in zip(it_f, it_g)]
    return StepFunction(xs, f.y0 // g.y0, ys)
end

function (^)(f::StepFunction, g::StepFunction)
    dom_it = SortedDomainIterator([f.xs, g.xs])
    xs = unique(dom_it)
    it_f = ValueSweepIterator(f, xs)
    it_g = ValueSweepIterator(g, xs)

    ys = [x^y for (x, y) in zip(it_f, it_g)]
    return StepFunction(xs, f.y0^g.y0, ys)
end

##
## Other operations
##

"""
    restrict(f::StepFunction, a::Real, b::Real)

Sets the values of `f` to zero outside the interval `[a,b]`.
"""
function restrict(f::StepFunction, a::Real, b::Real)
    if a >= b
        throw(ArgumentError("a must be less than b"))
    end
    return restrict_right(restrict_left(f, a), b)
end

function restrict_left(f::StepFunction{X,Y}, a::Real) where {X,Y}
    if a == -Inf
        return f
    end
    g = StepFunction([a], [zero(Y), one(Y)])

    return f * g
end

function restrict_right(f::StepFunction{X,Y}, b::Real) where {X,Y}
    if b == Inf
        return f
    end
    g = StepFunction([b], [one(Y), zero(Y)])

    return f * g
end

"""
    lines_data(f::StepFunction, a::Real, b::Real)

Returns series ``xs`` and ``ys`` that can be used to plot the step function `f` over the interval `[a,b]`.
"""
function lines_data(f::StepFunction, a, b)
    if b<= a
        throw(ArgumentError("b must be greater than a"))
    end

    xs = f.xs
    y0 = f.y0
    ys = f.ys

    i1 = findlast(x -> x <= a, xs)
    i2 = findlast(x -> x < b, xs)

    i1 = i1 === nothing ? 0 : i1
    plt_xs = [a;repeat(xs[i1+1:i2],inner=2);b]

    ys_all = [y0;ys]
    plt_ys = repeat([ys_all[i1+1:i2];ys[i2]], inner=2)
    return (plt_xs, plt_ys)
end

"""
    function to_minimal_stepfct_data!(xs, y0, ys)

Removess successive identical `xs` and `ys` values from the data of a step function.
"""
function to_minimal_stepfct_data(xs, y0, ys)
    xs, ys = no_successive_xs(xs, ys)
    xs, ys = no_successive_ys(xs, y0, ys)
    return xs, y0, ys
end

function no_successive_xs(xs, ys)
    # find all xs indices that are not equal to their successor
    if length(xs) <= 1
        return xs, ys
    end
    ind = [findall(i -> xs[i] != xs[i+1], 1:length(xs)-1); length(xs)]
    xs = xs[ind]
    ys = ys[ind]
    return xs, ys
end

function no_successive_ys(xs, y0, ys)
    if length(ys) <= 1
        return xs, ys
    end

    unequal_to_predecessor = [y0 != ys[1]; ys[2:end] .!= ys[1:end-1]]

    xs = xs[unequal_to_predecessor]
    ys = ys[unequal_to_predecessor]
    return xs, ys
end

export StepFunction, SortedDomainIterator, ValueSweepIterator
export restrict, lines_data

end
