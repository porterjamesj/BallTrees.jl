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
function get_coord(coord::Int)
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
function bounding_ball(b1::Ball, b2::Ball;
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


# wrapper to construct a ball tree using the kd algorithm.
function kd_construct{T<:Real}(balls::Array{Ball{T}};metric::Metric=Euclidean())
    rootnode = build_blt_for_range(1,length(balls),balls,metric=metric)
    return BallTree(rootnode)
end
