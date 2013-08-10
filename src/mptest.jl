p1 = [1,2,6,4,90]
p2 = [4,5,-3,50,-2]

function midpoint{T<:Number}(v1::Array{T},v2::Array{T})
    @assert length(v1) == length(v2)
    result = Array(T,length(v1))
    for dim in 1:length(v1)
        result[dim] = (v1[dim] + v2[dim]) / 2
    end
    return result
end