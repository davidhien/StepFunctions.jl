module StepFunctions
    import Base: iterate, isdone, length
    import Base: (+), (-), (*), (/), (^)

    """
        struct StepFunction{X<:Real,Y}
    
    A step function is a piecewise constant function.
    It is represented by vectors `xs` and `ys` as follows:
    ``f(t) = \\begin{cases} ys[i+1] & \\text{if } xs[i] \\leq t < xs[i+1] \\\\ ys[1]   & \\text{if } t < xs[1] \\\\ ys[end] & \\text{if } t \\geq xs[end] \\end{cases}``

    In particular, we must have `length(xs)+1 == length(ys)`. Furthermore, `xs` must be sorted and must not contain `Inf`.
    """
    struct StepFunction{X<:Real,Y}
        xs::Vector{X}
        ys::Vector{Y}

        function StepFunction(xs,ys)
            if length(ys) != length(xs)+1
                throw(ArgumentError("length(xs)+1 must be equal to length(ys)"))
            elseif !issorted(xs)
                throw(ArgumentError("xs must be sorted"))
            elseif xs[end] == Inf
                throw(ArgumentError("xs must not contain Inf"))
            else
                Base.require_one_based_indexing(xs)
                Base.require_one_based_indexing(ys)
                new{eltype(xs),eltype(ys)}(xs,ys)
            end
        end
    end

    struct StepFunctionIterator{T}
        fcts::T
    end

    function length(iter::StepFunctionIterator{T}) where T
        return 1 + sum(f-> length(f.xs),iter.fcts)
    end

    function iterate(iter::StepFunctionIterator{T}) where {T}
        return (-Inf,map(f->f.ys[1],iter.fcts)), map(f-> firstindex(f.xs)-1, iter.fcts)
    end

    function iterate(it::StepFunctionIterator{T}, state) where {T}
        n = length(it.fcts)
        minval, min_ind = findmin(1:n) do i
            succ_i = state[i]+1
            xs = it.fcts[i].xs
            if succ_i <= lastindex(xs)
                return xs[succ_i]
            else
                return Inf
            end
        end
        if minval == Inf
            return nothing
        end
        state[min_ind] += 1
        ys_new = map(t-> t[1].ys[t[2]+1], zip(it.fcts,state))

        return (minval,ys_new), state
    end

    function isdone(iter::StepFunctionIterator{T}, state) where {T}
        return state === nothing || all(zip(iter.fcts,state)) do t
            f,k = t
            return length(f.xs) == k
        end
    end

    export StepFunction, StepFunctionIterator
end
