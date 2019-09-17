
# class constructors
Quotient(X,::Type{R}) where R<:Ring = new_class(Quotient{sintern(X),R}, X)
Quotient(X::Integer,::Type{T}) where T<:Integer = T / T(X)

# convenience type constructor
# enable `Z / m` for anonymous quotient class constructor
/(::Type{R}, m) where R<:Ring = new_class(Quotient{sintern(m),R}, new_ideal(R, m))

# Constructors
basetype(::Type{<:Quotient{m,T}}) where {m,T} = T
depth(::Type{<:Quotient{m,T}}) where {m,T} = depth(T) + 1

function Quotient{X,R}(a::R) where {X,R<:Ring}
    m = modulus(Quotient{X,R})
    v = rem(a, m)
    Quotient{X,R}(v, NOCHECK)
end

# convert argument to given R
Quotient{X,R}(v::Quotient{X,R}) where {X,R<:Ring} = Quotient{X,R}(v.val)
Quotient{X,R}(v) where {X,R<:Ring} = Quotient{X,R}(R(v))

# promotion and conversion
_promote_rule(::Type{Quotient{X,R}}, ::Type{S}) where {X,R,S<:Ring} = Quotient{X,promote_type(R,S)}
promote_rule(::Type{Quotient{X,R}}, ::Type{S}) where {X,R,S<:Integer} = Quotient{X,promote_type(R,S)}

convert(Q::Type{Quotient{X,R}}, a::Quotient{X,R}) where {X,R} = a
convert(Q::Type{Quotient{X,R}}, a::S) where {X,R,S} = Q(convert(R, a))

Base.isless(p::T, q::T) where T<:Quotient = isless(p.val, q.val)

## Arithmetic

+(a::T, b::T) where T<:Quotient =  T(a.val + b.val)
-(a::T, b::T) where T<:Quotient =  T(a.val - b.val)
*(a::T, b::T) where T<:Quotient =  T(a.val * b.val)
*(a::Integer, b::T) where T<:Quotient =  T(a * b.val)
*(a::T, b::Integer) where T<:Quotient =  T(a.val * b)
-(a::T) where T<:Quotient =  T(-a.val)
inv(a::T) where T<:Quotient = T(invert(a.val, modulus(T)), NOCHECK)

isunit(a::T) where T<:Quotient = isunit(a.val) || isinvertible(modulus(T), a.val)
iszero(x::Quotient) = iszero(x.val)
isone(x::Quotient) = isone(x.val)
zero(::Type{<:Quotient{X,S}}) where {X,S} = Quotient{X,S}(zero(S), NOCHECK)
one(::Type{<:Quotient{X,S}}) where {X,S} = Quotient{X,S}(one(S), NOCHECK)

# induced homomorphism - invalid if Q = R/I and I not in kernel(F)
function (h::Hom{F,R,S})(a::Q) where {X,F,R,S,Q<:Quotient{X,<:R}}
    iszero(F(modulus(Q))) || throw(DomainError((F,R), "ideal not in kernel of homomorphism"))
    F(a.val)
end

# note:
# the real work is in the functions `new_ideal`, `rem`, `invert`, `isinvertible` which
# have all been delegated to Ideal

## Help functions

# return the ideal associated uniquely with this quotient ring
modulus(t::Type{<:Quotient{X,R}}) where {X,R} = gettypevar(t).modulus

# standard functions
==(a::Quotient{X},b::Quotient{X}) where X = a.val == b.val
hash(a::Quotient, h::UInt) = hash(a.val, hash(modulus(a), h))

function Base.show(io::IO, a::Quotient)
    v = a.val
    m = modulus(a)
    print(io, v, " mod(", m, ")")
end

