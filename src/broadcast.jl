using Base.Broadcast

import Base.Broadcast: BroadcastStyle, Broadcasted, ArrayStyle

BroadcastStyle(::Type{T}) where T <: GPUArray = ArrayStyle{T}()

function Base.similar(bc::Broadcasted{<:ArrayStyle{GPU}}, ::Type{ElType}) where {GPU <: GPUArray, ElType}
    similar(GPU, ElType, axes(bc))
end

@inline function Base.copyto!(dest::GPUArray, bc::Broadcasted{Nothing})
    axes(dest) == axes(bc) || Broadcast.throwdm(axes(dest), axes(bc))
    bc′ = Broadcast.preprocess(dest, bc)
    gpu_call(dest, (dest, bc′)) do state, dest, bc′
        let I = CartesianIndex(@cartesianidx(dest))
            @inbounds dest[I] = bc′[I]
        end
    end

    return dest
end

function mapidx(f, A::GPUArray, args::NTuple{N, Any}) where N
    gpu_call(A, (f, A, args)) do state, f, A, args
        ilin = @linearidx(A, state)
        f(ilin, A, args...)
    end
end
