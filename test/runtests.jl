using StepFunctions
using Test

@testset "StepFunctions.jl" begin
    @testset "StepFunction constructor" begin
        # internal constructor
        xs = [1,2,3,4]
        ys = [0,1,2,3,4]
        f = StepFunction(xs,ys[1],ys[2:end])
        @test f.xs == xs && f.y0 == ys[1] && f.ys == ys[2:end]

        # convenience constructor
        xs = [1,2,3,4]
        ys = [0,1,2,3,4]
        f = StepFunction(xs,ys)
        @test f.xs == xs && f.y0 == ys[1] && f.ys == ys[2:end]

        # test empty xs
        xs = Int[]
        ys = [0]
        f = StepFunction(xs,ys)
        @test f.xs == xs && f.y0 == ys[1] && f.ys == ys[2:end]

        # test incompatible lengths
        xs = [1,2,3,4]
        ys = [0,1,2,3]
        @test_throws ArgumentError StepFunction(xs,ys)

        # test unsorted xs
        xs = [1,3,2,4]
        ys = [0,1,2,3,4]
        @test_throws ArgumentError StepFunction(xs,ys)

        # test Inf in xs
        xs = [1,2,3,Inf]
        ys = [0,1,2,3,4]
        @test_throws ArgumentError StepFunction(xs,ys)
    end

    @testset "evaluation" begin
        # simple test
        xs = [1,2,3,4]
        ys = [0,1,2,3,4]
        f = StepFunction(xs,ys)
        @test f(-0.678) == 0
        @test f(0) == 0
        @test f(1) == 1
        @test f(1.5) == 1
        @test f(2) == 2
        @test f(2.5) == 2
        @test f(3) == 3
        @test f(3.5) == 3
        @test f(4) == 4
        @test f(5) == 4

        # test empty xs
        xs = Int[]
        ys = [0]
        f = StepFunction(xs,ys)
        @test f(0) == 0
        @test f(1) == 0
        @test f(2) == 0
    end

    @testset "Arithmetic Operations" begin
        @testset "addition" begin
            # simple test
            f = StepFunction([1,2],[0,1,2])
            g = StepFunction([1,2],[3,4,5])
            h = f + g
            @test h.xs == [1,2]
            @test h.y0 == 3
            @test h.ys == [5,7]
        
            # test type promotion
            f = StepFunction([1,2],[0.0,1,2])
            g = StepFunction([1,2],[3,4,5])
            h = f + g
            @test h.xs == [1,2]
            @test h.y0 == 3.0
            @test h.ys == [5.0,7.0]
    
            # todo: test different lengths, test non-overlapping xs
    
            @testset "Edge Cases" begin
                # test empty xs
                f = StepFunction(Int[],[1])
                g = StepFunction(Int[],[3])
                h = f + g
                @test h.xs == Int[]
                @test h.y0 == 4
                @test h.ys == Int[]
    
                # test empty xs with type promotion
                f = StepFunction(Int[],[1])
                g = StepFunction(Float64[],[3])
                h = f + g
                @test h.xs == Int[]
                @test h.y0 == 4
                @test h.ys == Float64[]
    
            end
        end

        @testset "subtraction" begin
            # simple test
            f = StepFunction([1,2],[0,1,2])
            g = StepFunction([1,2],[3,5,6])
            h = f - g

            @test h.xs == [1]
            @test h.y0 == -3
            @test h.ys == [-4]
    
            # test type promotion
            f = StepFunction([1,3],[0.0,1,2])
            g = StepFunction([1,2],[3,4,5])
            h = f - g
            f-h

            @test h.xs == [2,3]
            @test h.y0 == -3.0
            @test h.ys == [-4.0,-3.0]
    
        end
        @testset "multiplication" begin
            # simple test
            f = StepFunction([1,2],[0,1,2])
            g = StepFunction([1,2],[3,4,5])
            h = f * g
            @test h.xs == [1,2]
            @test h.y0 == 0
            @test h.ys == [4,10]
    
            # test type promotion
            f = StepFunction([1,2],[0.0,1,2])
            g = StepFunction([1,2],[3,4,5])
            h = f * g
            @test h.xs == [1,2]
            @test h.y0 == 0.0
            @test h.ys == [4.0,10.0]
            @test eltype(h.ys) == eltype(f.ys)    
        end
        @testset "division" begin
            # simple test
            f = StepFunction([1,2],[0,1,2])
            g = StepFunction([1,2],[3,4,5])
            h = f / g
            @test h.xs == [1,2]
            @test h.y0 == 0
            @test h.ys == [0.25,0.4]

            # test rational division
            f = StepFunction([1,3],[1,2,3])
            g = StepFunction([1,2],[3,6,5])
            h = f // g

            @test h.xs == [2,3]
            @test h.y0 == 1//3
            @test h.ys == [2//5,3//5]
        end

        @testset "exponentiation" begin
            # simple test
            f = StepFunction([1,2],[0,1,2])
            g = StepFunction([1,2],[3,4,5])
            h = f ^ g
            @test h.xs == [1,2]
            @test h.y0 == 0
            @test h.ys == [1,32]
        end
    end

    @testset "Unit Tests" begin
        @testset "Hash, == and isequal" begin
            # test hash
            f = StepFunction([1,2],[0.0,1,2])
            g = StepFunction([1,2],[0.0,1,2])
            h = StepFunction([1,2],[-0.0,1,2])

            @test hash(f) == hash(g)

            # test equality
            @test f == g
            @test f == h

            # test isequal
            @test isequal(f,g)
            @test !isequal(f,h)

            # test not equal
            h = StepFunction([1,2],[0,1,3])
            @test f != h

            # test hash with different types
            f = StepFunction([1.0,2.0],[0.0,1.0,2.0])
            g = StepFunction([1,2],[0,1,2])
            @test hash(f) == hash(g)
        end

        @testset "to_minimal_stepfct_data" begin
            # test that the rightmost y value is kept for equal xs
            xs = [1,1,1,4]
            ys = [1,2,3,4]
            xs_new, ys_new = StepFunctions.no_successive_xs(xs, ys)
            @test xs_new == [1,4]
            @test ys_new == [3,4]

            # test that the leftmost x-val is kept for equal ys
            xs = [1,2,3,4]
            ys = [1,1,1,4]
            y0 = 0
            xs_new, ys_new = StepFunctions.no_successive_ys(xs, y0, ys)
            @test xs_new == [1,4]
            @test ys_new == [1,4]

            # test that the leftmost x-val is kept for equal ys
            xs = [1,2,3,4]
            ys = [1,1,1,4]
            y0 = 1
            xs_new, ys_new = StepFunctions.no_successive_ys(xs, y0, ys)
            @test xs_new == [4]
            @test ys_new == [4]
        end
        @testset "SortedDomainIterator" begin
            xs_1 = [1,2,3,4]
            xs_2 = [0,1.0,2,3,4]
            it = SortedDomainIterator((xs_1,xs_2))
            @test length(it) == 9

            x, state = iterate(it)
            @test (x,state) == (0.0, [0,1])
            x, state = iterate(it,state)
            @test (x,state) == (1.0, [1,1])
            x, state = iterate(it,state)
            @test (x,state) == (1.0, [1,2])
            x, state = iterate(it,state)
            @test (x,state) == (2.0, [2,2])
            x, state = iterate(it,state)
            @test (x,state) == (2.0, [2,3])
            x, state = iterate(it,state)
            @test (x,state) == (3.0, [3,3])
            x, state = iterate(it,state)
            @test (x,state) == (3.0, [3,4])
            x, state = iterate(it,state)
            @test (x,state) == (4.0, [4,4])
            x, state = iterate(it,state)
            @test (x,state) == (4.0, [4,5])
            state = iterate(it,state)
            @test nothing === state

            # test empty xs
            xs = Int[]
            it = SortedDomainIterator([xs])
            @test length(it) == 0
            state = iterate(it)
            @test state === nothing
        end

        @testset "SortedDomainIterator type stability" begin
            dom_it = SortedDomainIterator(([1,2], [3,4]))
            vec = collect(dom_it)
            @test eltype(vec) == Int
            @test vec == [1,2,3,4]
        end

        @testset "ValueSweepIterator" begin
            # simple example
            f = StepFunction([1,2,3],[0.0,10,20,30])
            xs=[0,1,2,3]
            val_it = ValueSweepIterator(f, xs)

            @test length(val_it) == 4
            @test val_it.f == f
            @test val_it.xs == xs

            # test iteration
            y, state = iterate(val_it)
            @test (y,state[2]) == (0.0, 0)
            y, state = iterate(val_it,state)
            @test (y,state[2]) == (10.0, 1)
            y, state = iterate(val_it,state)
            @test (y,state[2]) == (20.0, 2)
            y, state = iterate(val_it,state)
            @test (y,state[2]) == (30.0, 3)
            state = iterate(val_it,state)
            @test state === nothing


            # more complicated example
            f = StepFunction([2,4,6],[0,1,2,3])
            xs = [1,2,3,6,7]
            val_it = ValueSweepIterator(f, xs)

            @test length(val_it) == 5
            @test val_it.f == f
            @test val_it.xs == xs

            # test iteration
            y, state = iterate(val_it)
            @test (y,state[2]) == (0, 0)
            for t in [(1,1), (1,1), (3,3), (3,3)]
                y, state = iterate(val_it,state)
                @test (y,state[2]) == t
            end
            @test iterate(val_it,state) === nothing

            # empty xs

        end
        @testset "ValueSweepIterator type stability" begin
            f = StepFunction([1,2,3],[0.0,10,20,30])
            xs = [0,1,2,3]
            val_it = ValueSweepIterator(f, xs)
            vec = collect(val_it)
            @test eltype(vec) == Float64
            @test vec == [0.0, 10.0, 20.0, 30.0]
        end
    end
end
