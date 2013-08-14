# Script to run all tests

using BallTrees
using Base.Test
using Base.Collections

tests = ["test/BallTreeTest.jl"]

println("Running tests:")

for test in tests
    include(test)
end