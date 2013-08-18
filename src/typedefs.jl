# type definitions

type Ball{T<:Real}
    center::Array{T}
    radius::T
end

# promoting constructor for balls
function Ball{T<:Real,S<:Real}(center::Array{T},radius::S)
    U = promote_type(T,S)
    Ball{U}(convert(Array{U},center),convert(U,radius))
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
