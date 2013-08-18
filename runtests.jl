# Script to run all tests

using BallTrees
using Base.Test
using Base.Collections

tests = ["test/construction.jl",
         "test/querying.jl"]

println("Running tests:")

for test in tests
    include(test)
end
println("All tests passed!")