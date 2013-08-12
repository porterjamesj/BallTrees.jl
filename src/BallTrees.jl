module BallTrees
using Base.Order
using Distance

# exports

export Ball, BallNode, BallTree,
       kd_construct

# constants
const DEFAULT_METRIC = Euclidean()

# type definitions

type Ball{T<:Number}
    center::Array{T}
    radius::Number
end

type BallNode
    ball::Ball
    parent::Union(BallNode,Nothing)
    left::Union(BallNode,Nothing)
    right::Union(BallNode,Nothing)
end

Base.show(io::IO, bn::BallNode) =
    Base.show(io, "BallNode(" * string(bn.ball) * ")")

BallNode(b::Ball) = BallNode(b, nothing, nothing, nothing)

type BallTree
    tree::BallNode
end

# Construction Routines


# The K-d construction algorithm from the paper
# and associated helpers

# get the most spread coordinate of in an array of balls
function most_spread_coord{T<:Number}(balls::Array{Ball{T}})
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
function midpoint{T<:Number}(v1::Array{T}, v2::Array{T})
    @assert length(v1) == length(v2)
    result = Array(Float64,length(v1)) # better way to do this?
    for dim in 1:length(v1)
        result[dim] = (v1[dim] + v2[dim]) / 2
    end
    return result
end

# construct a bounding ball for any two given balls
function bounding_ball{T<:Number,W<:Number}(b1::Ball{T}, b2::Ball{W}, metric::Metric)
    span = b1.center - b2.center
    unitvec = span / norm(span)
    p1 = b1.center + (unitvec * b1.radius)
    p2 = b2.center - (unitvec * b2.radius)
    center = midpoint(p1,p2)
    return Ball(center,evaluate(metric,p1,p2)/2)
end

# recursive ball tree construction, works kind of a like a kd tree construction
function build_blt_for_range{T<:Number}(l::Int, u::Int,
                                        balls::Array{Ball{T}}, metric::Metric)
    if u == l
        return BallNode(balls[u])
    else
        spliton = most_spread_coord(balls)
        m = ifloor((l+u)/2)
        select!(balls, m, l, u, ord(isless, get_coord(spliton), false, Forward))
        left = build_blt_for_range(l, m, balls, metric)
        right = build_blt_for_range(m+1, u, balls, metric)
        resultball = bounding_ball(left.ball, right.ball, metric)
        resultnode = BallNode(resultball, Nothing(), left, right)
        # set parent correctly on child ballnodes
        left.parent = resultnode
        right.parent = resultnode
        return resultnode
    end
end


# wrapper to construct a ball tree using the kd-esque
# algorithm.
function kd_construct{T<:Number}(balls::Array{Ball{T}},metric::Metric)
    rootnode = build_blt_for_range(1,length(balls),balls,metric)
    return BallTree(rootnode)
end

# euclidean is the default metric
kd_construct{T<:Number}(balls::Array{Ball{T}}) = kd_construct(balls,DEFAULT_METRIC)


# Querying

function contains(outer::Ball,inner::Ball,metric::Metric)
    dist = evaluate(metric::Metric,outer.center,inner.center)
    dist + inner.radius <= outer.radius
end
contains(outer::Ball,inner::Ball) = contains(outer,inner,DEFAULT_METRIC)


function intersects(b1::Ball,b2::Ball,metric::Metric)
    dist = evaluate(metric::Metric,b1.center,b2.center)
    dist < b1.radius+ b2.radius
end
intersects(b1::Ball,b2::Ball) = intersects(b1,b2,DEFAULT_METRIC)



end # module BallTrees