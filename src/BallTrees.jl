module BallTrees

using Base.Order
using Distance

# exports

export Ball, BallNode, BallTree,
       kd_construct, nnsearch

# type definitions

type Ball{T<:Real}
    center::Array{T}
    radius::T
end

# promoting constructor for balls
function Ball{T<:Real,S<:Real}(center::Array{T},radius::S)
    U = promote_type(T,S)
    Ball(convert(Array{U},center),convert(U,radius))
end


type BallNode
    ball::Ball
    parent::Union(BallNode,Nothing)
    left::Union(BallNode,Nothing)
    right::Union(BallNode,Nothing)
end

BallNode(b::Ball) = BallNode(b, nothing, nothing, nothing)

Base.show(io::IO, bn::BallNode) =
    Base.show(io, "BallNode(" * string(bn.ball) * ")")

type BallTree
    tree::BallNode
end

# Construction Routines


# The K-d construction algorithm from the paper
# and associated helpers

# get the most spread coordinate of in an array of balls
function most_spread_coord{T<:Real}(balls::Array{Ball{T}})
    centers = [ball.center for ball in balls]
    spreads = max(centers) - min(centers)
    return findmax(spreads)[2]
end

# returns a curried function to return a specific coord from a
# ball's center
function get_coord(coord)
    return function(b::Ball)
        return b.center[coord]
    end
end

# compute the midpoint of any two points
function midpoint{T<:Real}(v1::Array{T}, v2::Array{T})
    @assert length(v1) == length(v2)
    result = Array(Float64,length(v1)) # better way to do this?
    for dim in 1:length(v1)
        result[dim] = (v1[dim] + v2[dim]) / 2
    end
    return result
end

# construct a bounding ball for any two given balls
function bounding_ball{T<:Real,W<:Real}(b1::Ball{T}, b2::Ball{W};
                                        metric::Metric = Euclidean())
    span = b1.center - b2.center
    unitvec = span / norm(span)
    p1 = b1.center + (unitvec * b1.radius)
    p2 = b2.center - (unitvec * b2.radius)
    center = midpoint(p1,p2)
    return Ball(center,evaluate(metric,p1,p2)/2)
end

# recursive ball tree construction, works kind of a like a kd tree construction
function build_blt_for_range{T<:Real}(l::Int, u::Int,
                                      balls::Array{Ball{T}};
                                      metric::Metric=Euclidean())
    if u == l
        return BallNode(balls[u])
    else
        spliton = most_spread_coord(balls)
        m = ifloor((l+u)/2)
        select!(balls, m, l, u, ord(isless, get_coord(spliton), false, Forward))
        left = build_blt_for_range(l, m, balls, metric=metric)
        right = build_blt_for_range(m+1, u, balls, metric=metric)
        resultball = bounding_ball(left.ball, right.ball, metric=metric)
        resultnode = BallNode(resultball, nothing, left, right)
        # set parent correctly on child ballnodes
        left.parent = resultnode
        right.parent = resultnode
        return resultnode
    end
end


# wrapper to construct a ball tree using the kd-esque
# algorithm.
function kd_construct{T<:Real}(balls::Array{Ball{T}};metric::Metric=Euclidean())
    rootnode = build_blt_for_range(1,length(balls),balls,metric=metric)
    return BallTree(rootnode)
end


# Querying

function contains(outer::Ball,inner::Ball;metric::Metric=Euclidean())
    dist = evaluate(metric::Metric,outer.center,inner.center)
    dist + inner.radius <= outer.radius
end


function intersects(b1::Ball,b2::Ball;metric::Metric=Euclidean())
    dist = evaluate(metric::Metric,b1.center,b2.center)
    dist < b1.radius+ b2.radius
end


function push_containing_leaves(query::Ball,
                                  node::BallNode,
                                  accum::Array{BallNode},
                                  metric::Metric=Euclidean())
    if intersects(node.ball,query,metric=metric)
        if node.left == node.right == nothing #leaf node, add it
            push!(accum,node)
        else # internal node
            push_containing_leaves(query,node.left,accum)
            push_containing_leaves(query,node.right,accum)
        end
    end
end


function push_intersecting_leaves(query::Ball,
                                  node::BallNode,
                                  accum::Array{BallNode},
                                  metric::Metric=Euclidean())
    if intersects(node.ball,query,metric=metric)
        if node.left == node.right == nothing #leaf node, add it
            push!(accum,node)
        else # internal node
            push_intersecting_leaves(query,node.left,accum)
            push_intersecting_leaves(query,node.right,accum)
        end
    end
end


function push_contained_leaves(query::Ball,
                               node::BallNode,
                               accum::Array{BallNode},
                               metric::Metric=Euclidean())
    if node.left == nothing && node.right == nothing
        if contains(query,node.ball)
            push!(accum,node)
        end
    elseif intersects(query,node.ball)
        push_contained_leaves(query,node.left,accum)
        push_contained_leaves(query,node.right,accum)
    end
end


# stuff for nearnest neighbor search


# make a "bball" for a query point and a root node
# at which to start the search. The bball is the ball
# whose center is the query point and whose radius
# is just big enough to contain the root node's ball.
function makebball{T<:Real}(query::Array{T}, ball::Ball;
                            metric=Euclidean())
    Ball(query, evaluate(metric,query,ball.center) + ball.radius)
end


function nnsearch(node::BallNode,bball::Ball;
                  metric=Euclidean())
    if node.left == nothing && node.right == nothing # leaf
        d = evaluate(metric,bball.center,node.ball.center)
        if d < bball.radius
            bball.radius = d
            nn = node.ball
        end
    else # internal node
        ld = evaluate(metric,node.left.ball.center,bball.center)
        rd = evaluate(metric,node.right.ball.center,bball.center)
        if ld < bball.radius && rd < bball.radius # look here
            if ld <= rd # search nearer node first
                nn = nnsearch(node.left,bball)
                if rd < bball.radius
                    nn = nnsearch(node.right,bball)
                end
            else
                nn = nnsearch(node.right,bball)
                if rd < bball.radius
                    nn = nnsearch(node.left,bball)
                end
            end
        end
    end
    return nn
end


end # module BallTrees