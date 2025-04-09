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
        y0::Y
        ys::Vector{Y}

        function StepFunction(xs::Vector{X},y0::Y,ys::Vector{Y}) where {X,Y}
            if length(ys) != length(xs)
                throw(ArgumentError("For inner constructor: length(xs) must be equal to length(ys)"))
            elseif !issorted(xs)
                throw(ArgumentError("xs must be sorted"))
            elseif  !isempty(xs) && xs[end] == Inf
                throw(ArgumentError("xs must not contain Inf"))
            else
                Base.require_one_based_indexing(xs)
                Base.require_one_based_indexing(ys)
                xs, y0, ys = to_minimal_stepfct_data(xs,y0,ys)
                new{X,Y}(xs,y0,ys)
            end
        end
    end

    function StepFunction(xs::Vector,ys::Vector)
        if length(ys) != length(xs)+1
            throw(ArgumentError("length(xs)+1 must be equal to length(ys)"))
        elseif !issorted(xs)
            throw(ArgumentError("xs must be sorted"))
        elseif !isempty(xs) && xs[end] == Inf
            throw(ArgumentError("xs must not contain Inf"))
        else
            Base.require_one_based_indexing(xs)
            Base.require_one_based_indexing(ys)
            StepFunction(xs,ys[1],ys[2:end])
        end
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
        return sum(xs-> length(xs),iter.xs_iter)
    end

    function iterate(iter::SortedDomainIterator)
        return iterate(iter,collect(map(xs-> firstindex(xs)-1, iter.xs_iter)))
    end

    function iterate(iter::SortedDomainIterator{S,T}, state) where {S,T}
        n = length(iter.xs_iter)
        xs_iter  = iter.xs_iter
        minval, min_ind = findmin(1:n) do i
            succ_i = state[i]+1
            xs = xs_iter[i]
            if succ_i <= lastindex(xs)
                return convert(S,xs[succ_i])
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

    function isdone(iter::SortedDomainIterator{T}, state) where {T}
        return state === nothing || all(zip(iter.fcts,state)) do t
            f,k = t
            return length(f.xs) == k
        end
    end


    

    struct StepFunctionIterator{T}
        fcts::T
    end

    function length(iter::StepFunctionIterator{T}) where T
        return sum(f-> length(f.xs),iter.fcts)
    end

    function iterate(iter::StepFunctionIterator{T}) where {T}
        return iterate(iter,map(f-> firstindex(f.xs)-1, iter.fcts))
    end

    function iterate(iter::StepFunctionIterator{T}, state) where {T}
        n = length(iter.fcts)
        minval, min_ind = findmin(1:n) do i
            succ_i = state[i]+1
            xs = iter.fcts[i].xs
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
        ys_new = ntuple(i -> state[i] == 0 ? iter.fcts[i].y0 : iter.fcts[i].ys[state[i]], length(iter.fcts))

        return (minval,ys_new), state
    end

    function isdone(iter::StepFunctionIterator{T}, state) where {T}
        return state === nothing || all(zip(iter.fcts,state)) do t
            f,k = t
            return length(f.xs) == k
        end
    end

    function (+)(f::StepFunction, g::StepFunction)
        it = StepFunctionIterator([f,g])
        xs = [i[1] for i in Iterators.drop(it,1)]
        ys = [i[2][1]+i[2][2] for i in it]

        return StepFunction(xs,ys)
    end

    #=
    function (+)(f::StepFunction, g::StepFunction)
        it = StepFunctionIterator([f,g])
        xs = promote_type(eltype(f.xs),eltype(g.xs))[]
        ys = promote_type(eltype(f.ys),eltype(g.ys))[]
        sizehint!(xs,length(f.xs)+length(g.xs)) # preallocate
        sizehint!(ys,length(f.xs)+length(g.xs)+1) # preallocate

        for (t,ys_new) in it
            t == -Inf || push!(xs,t)
            push!(ys,sum(ys_new))
        end
        return StepFunction(xs,ys)
    end=#

    """
        function to_minimal_stepfct_data!(xs, y0, ys)

    Given a vector of xs and a vector of ys
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
        ind = [findall( i-> xs[i] != xs[i+1] ,1:length(xs)-1) ; length(xs)]
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

    # basic operations: +,-,*,/(?)
    # for one f: max, min, abs, integrate, l_p norms
    # stats: (pointwise) mean


    export StepFunction, StepFunctionIterator, SortedDomainIterator
end
