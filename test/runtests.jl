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

    @testset "StepFunctionIterator" begin
        fs = map(i->StepFunction([i],[i,i+1]),1:4)
        it = StepFunctionIterator(fs)
        @test length(it) == 5

        state = zeros(Int,4)
        @test iterate(it) == ((-Inf,(1,2,3,4)), state)
        t,state = iterate(it,state)
        @test (t,state) == ((1,(2,2,3,4)), [1,0,0,0])
        t,state = iterate(it,state)
        @test (t,state) == ((2,(2,3,3,4)), [1,1,0,0])
        t,state = iterate(it,state)
        @test (t,state) == ((3,(2,3,4,4)), [1,1,1,0])
        t,state = iterate(it,state)
        @test (t,state) == ((4,(2,3,4,5)), [1,1,1,1])
        @test nothing === iterate(it,state)
    end

    @testset "Unit Tests" begin
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
    end
end
