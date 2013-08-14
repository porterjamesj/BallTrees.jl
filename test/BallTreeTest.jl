balls = [Ball([1,1],1),Ball([3,3],2),Ball([6,2],1)]#,Ball([2,5],4)]

# test kd construction and its helpers

# test most_spread_coord
let balls = deepcopy(balls)
    @test BallTrees.most_spread_coord(balls) == 1
    balls[1].center[2] = -500
    @test BallTrees.most_spread_coord(balls) == 2
end

# test midpoint
@test BallTrees.midpoint([1,1],[3,3]) == [2,2]
@test BallTrees.midpoint([0,1],[4,-1]) == [2,0]

balls = [Ball([1,1],1), Ball([1,3],1)]

# test bounding_ball
begin
    boundb = BallTrees.bounding_ball(balls[1],balls[2])
    @test_approx_eq boundb.radius 2
    @test_approx_eq boundb.center[1] 1
    @test_approx_eq boundb.center[2] 2
end


# Construction

#test build_blt_for_range

# simple test
rootnode = BallTrees.build_blt_for_range(1,2,balls)
@test_approx_eq rootnode.ball.center[1] 1
@test_approx_eq rootnode.ball.center[2] 2
@test rootnode.left.ball.center == [1,1]
@test rootnode.right.right == nothing

# a bit harder
balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)]
rootnode = BallTrees.build_blt_for_range(1,3,balls)
@test_approx_eq rootnode.ball.center[1] 3.5
@test_approx_eq rootnode.ball.center[2] 3
@test_approx_eq rootnode.left.ball.center[1] 2
@test_approx_eq rootnode.left.ball.center[2] 3
@test rootnode.left.left.left == nothing
@test rootnode.right.right == nothing


# Querying

# contains / intersects
balls = [Ball([0,0],2),Ball([0,0],1),Ball([1,1],1),Ball([5,5],1)]
@test BallTrees.contains(balls[1],balls[2]) == true
@test BallTrees.contains(balls[1],balls[3]) == false
@test BallTrees.intersects(balls[1],balls[2]) == true
@test BallTrees.intersects(balls[1],balls[3]) == true
@test BallTrees.intersects(balls[1],balls[4]) == false

# contains should return true even if the edges kiss
@test BallTrees.contains(balls[1],Ball([0,1],1)) == true


# get all leaves containing a query ball
balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)]
rootnode = BallTrees.build_blt_for_range(1,3,balls)

temp = BallNode[]

BallTrees.push_containing_leaves(Ball([5,1],0),rootnode,temp)
@test temp == []

temp = BallNode[]
BallTrees.push_containing_leaves(Ball([2,1.5],0),rootnode,temp)
@test temp == [rootnode.left.right]


# get all leaves intersecting a query ball
balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)]
rootnode = BallTrees.build_blt_for_range(1,3,balls)

# should do nothing when no intersection
temp = BallNode[]
BallTrees.push_intersecting_leaves(Ball([5,1],0),rootnode,temp)
@test temp == []

# should return single ball
temp = BallNode[]
BallTrees.push_intersecting_leaves(Ball([6,2],1),rootnode,temp)
@test temp == [rootnode.right]

# should return multiple balls
temp = BallNode[]
BallTrees.push_intersecting_leaves(Ball([2,3],1),rootnode,temp)
@test temp == [rootnode.left.left,rootnode.left.right]


# get all leaves contained by a query ball

# should return nothing when no leaves are contained
temp = BallNode[]
BallTrees.push_contained_leaves(Ball([6,1],2),rootnode,temp)
@test temp == []

# should return one ball
temp = BallNode[]
BallTrees.push_contained_leaves(Ball([6,2],2),rootnode,temp)
@test temp == [rootnode.right]

temp = BallNode[]
BallTrees.push_contained_leaves(Ball([1,3],4),rootnode,temp)
@test temp == [rootnode.left.left,rootnode.left.right]

# test makebball
res = BallTrees.makebball([3,1],Ball([1,1],1))
@test_approx_eq res.center[1] 3
@test_approx_eq res.center[2] 1
@test_approx_eq res.radius 3

# test nnsearch
balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)]
rootnode = BallTrees.build_blt_for_range(1,3,balls)

pq = PriorityQueue{Ball,Real}()
query = [1,8]
bball = BallTrees.makebball(query,rootnode.ball)
nnsearch(rootnode,bball,pq,1)
@test dequeue!(pq).center == [2,4]

pq = PriorityQueue{Ball,Real}()
query = [7,8]
bball = BallTrees.makebball(query,rootnode.ball)
nnsearch(rootnode,bball,pq,1)
@test dequeue!(pq).center == [6,3]

# slightly harder test nnsearch
points = ([1,1],[3,3],[4,3],[2,5],[6,7],[7,2],[9,3])
balls::Array{Ball{Int}} = [Ball{Int}(p,0) for p in points]
rootnode = BallTrees.build_blt_for_range(1,7,balls)

pq = PriorityQueue{Ball,Real}()
query = [2,0.5]
bball = BallTrees.makebball(query,rootnode.ball)
nnsearch(rootnode,bball,pq,1)
@test dequeue!(pq).center == [1,1]

pq = PriorityQueue{Ball,Real}()
query = [3,4]
bball = BallTrees.makebball(query,rootnode.ball)
nnsearch(rootnode,bball,pq,3)
res = [b.center for b in keys(pq)]
@test contains(res, [3,3])
@test contains(res, [4,3])
@test contains(res, [2,5])

# done!
println("BallTree tests passed!")