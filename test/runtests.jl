using StepFunctions
using Test

@testset "StepFunctions.jl" begin
    @testset "StepFunction constructor" begin
        xs = [1,2,3,4]
        ys = [0,1,2,3,4]
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
end

#=

using StepFunctions
f = StepFunction([1,2,3,4],[0,1,2,3,4])
g = StepFunction([1,2,3,4],[0.0,1,2,3,4])

f+g
@code_warntype f+g

it = StepFunctionIterator([f,g])

a,b = iterate(it)
@code_warntype ntuple(a[2])

@code_warntype f+g

function test_fun()
    f = StepFunction([1,2,3,4],[rand(3) for i in 1:4])
    g = StepFunction([1,2,3,4],[rand(3) for i in 1:5])
    #it = StepFunctionIterator([f,g])

    return f+g#(f.ys[1] for f in it.fcts)
end
@code_warntype test_fun()

using Base
@which [[1;2;3];[1.0]]

using SparseArrays
SparseMatrixCSC([1.0 2.0; 3.0 4.0])
methods(SparseMatrixCSC)

Meta.@lower [1,2,3] ./ [2,3,4]
Base.broadcasted
=#