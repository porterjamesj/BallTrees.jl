module BallTrees
    import Base.Order: Forward, ord
    import Distance: evaluate, Metric, Euclidean
    import Base.Collections: PriorityQueue, dequeue!, enqueue!

    # exports
    export Ball, BallNode, BallTree,
    kd_construct, nnsearch

    include("typedefs.jl")
    include("construction.jl")
    include("querying.jl")
end