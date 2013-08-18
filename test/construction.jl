# test construction routines and helpers

# test most_spread_coord
let balls = [Ball([1,1],1),Ball([3,3],2),Ball([6,2],1)]
    @test BallTrees.most_spread_coord(balls) == 1
    balls[1].center[2] = -500
    @test BallTrees.most_spread_coord(balls) == 2
end

# test midpoint
let
    @test BallTrees.midpoint([1,1],[3,3]) == [2,2]
    @test BallTrees.midpoint([0,1],[4,-1]) == [2,0]
end

# test bounding_ball
let balls = [Ball([1,1],1), Ball([1,3],1)],
    boundb = BallTrees.bounding_ball(balls[1],balls[2])
    @test_approx_eq boundb.radius 2
    @test_approx_eq boundb.center[1] 1
    @test_approx_eq boundb.center[2] 2
end


#test build_blt_for_range

# simple test
let balls = [Ball([1,1],1), Ball([1,3],1)],
    rootnode = BallTrees.build_blt_for_range(1,2,balls)
    @test_approx_eq rootnode.ball.center[1] 1
    @test_approx_eq rootnode.ball.center[2] 2
    @test rootnode.left.ball.center == [1,1]
    @test rootnode.right.right == nothing
end

# a bit harder
let balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)],
    rootnode = BallTrees.build_blt_for_range(1,3,balls)
    @test_approx_eq rootnode.ball.center[1] 3.5
    @test_approx_eq rootnode.ball.center[2] 3
    @test_approx_eq rootnode.left.ball.center[1] 2
    @test_approx_eq rootnode.left.ball.center[2] 3
    @test rootnode.left.left.left == nothing
    @test rootnode.right.right == nothing
end

println("construction tests passed!")