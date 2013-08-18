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


# Find nearest neighbors of the query point (the center of the bball),
# starting the search at the given node, storing them in the given
# priority queue. The bball should be large enough to encompass the
# start node.
function nnsearch(node::BallNode,bball::Ball,nns::PriorityQueue,k::Int;
                  metric=Euclidean())
    if node.left == nothing && node.right == nothing # leaf
        d = evaluate(metric,bball.center,node.ball.center)
        if d < bball.radius
            # enqueue and dequeue if necessayr
            enqueue!(nns,node.ball,d)
            if length(nns) > k
                dequeue!(nns)
            end
            # adjust the radius of the bball if necessary
            if length(nns) == k
                bball.radius = max(values(nns))
            end
        end
    else # internal node
        ld = evaluate(metric,node.left.ball.center,bball.center)
        rd = evaluate(metric,node.right.ball.center,bball.center)
        if ld < bball.radius && rd < bball.radius # look here
            if ld <= rd # search nearer node first
                nnsearch(node.left,bball,nns,k)
                if rd < bball.radius # still worth looking?
                    nnsearch(node.right,bball,nns,k)
                end
            else
                nnsearch(node.right,bball,nns,k)
                if ld < bball.radius # still worth looking?
                    nnsearch(node.left,bball,nns,k)
                end
            end
        end
    end
end


# more convenient nnsearch
# assumes that the distances between different points in your data
# are measured using the same type of number that your data is
# represented in. could this be a problem?
function nnsearch{T<:Real}(tree::BallTree,point::Array{T},k::Int)
    # make a priority queue
    pq = PriorityQueue{Ball,Real}()
    # make a bball
    bball = makebball(point,tree.tree.ball)
    nnsearch(tree.tree,bball,pq,k::Int)
    return collect(keys(pq))
end
