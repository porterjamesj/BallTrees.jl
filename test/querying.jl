
# Querying

# contains / intersects
let balls = [Ball([0,0],2),Ball([0,0],1),Ball([1,1],1),Ball([5,5],1)]
    @test BallTrees.contains(balls[1],balls[2]) == true
    @test BallTrees.contains(balls[1],balls[3]) == false
    @test BallTrees.intersects(balls[1],balls[2]) == true
    @test BallTrees.intersects(balls[1],balls[3]) == true
    @test BallTrees.intersects(balls[1],balls[4]) == false
    # regression: contains should return true even if the edges kiss
    @test BallTrees.contains(balls[1],Ball([0,1],1)) == true
end

#test push_containing_leaves
let balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)],
    rootnode = BallTrees.build_blt_for_range(1,3,balls)

    let temp = BallNode[]
        BallTrees.push_containing_leaves(Ball([5,1],0),rootnode,temp)
        @test temp == []
    end

    let temp = BallNode[]
        BallTrees.push_containing_leaves(Ball([2,1.5],0),rootnode,temp)
        @test temp == [rootnode.left.right]
    end
end


# test push_intersecting_leaves
let balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)],
    rootnode = BallTrees.build_blt_for_range(1,3,balls)

    # should do nothing when no intersection
    let temp = BallNode[]
        BallTrees.push_intersecting_leaves(Ball([5,1],0),rootnode,temp)
        @test temp == []
    end

    # should return single ball
    let temp = BallNode[]
        BallTrees.push_intersecting_leaves(Ball([6,2],1),rootnode,temp)
        @test temp == [rootnode.right]
    end

    # should return multiple balls
    let temp = BallNode[]
        BallTrees.push_intersecting_leaves(Ball([2,3],1),rootnode,temp)
        @test temp == [rootnode.left.left,rootnode.left.right]
    end
end

# test push_contained_leaves
let balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)],
    rootnode = BallTrees.build_blt_for_range(1,3,balls)

    # should return nothing when no leaves are contained
    let temp = BallNode[]
        BallTrees.push_contained_leaves(Ball([6,1],2),rootnode,temp)
        @test temp == []
    end

    # should return one ball
    let temp = BallNode[]
        BallTrees.push_contained_leaves(Ball([6,2],2),rootnode,temp)
        @test temp == [rootnode.right]
    end

    let temp = BallNode[]
        BallTrees.push_contained_leaves(Ball([1,3],4),rootnode,temp)
        @test temp == [rootnode.left.left,rootnode.left.right]
    end
end


# test makebball
let res = BallTrees.makebball([3,1],Ball([1,1],1))
    @test_approx_eq res.center[1] 3
    @test_approx_eq res.center[2] 1
    @test_approx_eq res.radius 3
end

# test nnsearch
let balls = [Ball([2,2],1),Ball([2,4],1),Ball([6,3],1)],
    rootnode = BallTrees.build_blt_for_range(1,3,balls),
    tree = BallTree(rootnode)

    @test nnsearch(tree,[1,8],1)[1].center == [2,4]
    @test nnsearch(BallTree(rootnode),[7,7],1)[1].center == [6,3]
end

# slightly harder test nnsearch
let points = ([1,1],[3,3],[4,3],[2,5],[6,7],[7,2],[9,3]),
    balls::Array{Ball{Int}} = [Ball{Int}(p,0) for p in points],
    rootnode = BallTrees.build_blt_for_range(1,7,balls),
    tree = BallTree(rootnode)

    @test nnsearch(tree,[2,0.5],1)[1].center == [1,1]

    # finds multiple neighbors
    let res = nnsearch(tree,[3,4],3),
        centers = [b.center for b in res]
        @test contains(centers, [3,3])
        @test contains(centers, [4,3])
        @test contains(centers, [2,5])
    end
end

# done!
println("querying tests passed!")