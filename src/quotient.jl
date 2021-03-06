
# class constructors
Quotient(X::Integer,::Type{T}) where T<:Integer = T / T(X)

# convenience type constructor
# enable `Z / m` for anonymous quotient class constructor
function /(::Type{R}, m) where R<:Ring
    ideal = pseudo_ideal(R, m)
    p, r = characteristic(R), deg(ideal)
    o = r == 0 ? 0 : order(basetype(R))^r
    new_class(Quotient{R,typeof(ideal),sintern(m),(p,r,o)}, ideal)
end

# Constructors
basetype(::Type{<:Quotient{T}}) where T = T
depth(::Type{<:Quotient{T}}) where T = depth(T) + 1

function Quotient{R,I,X,Id}(a::R) where {I,X,R<:Ring,Id}
    m = modulus(Quotient{R,I,X,Id})
    v = rem(a, m)
    Quotient{R,I,X,Id}(v, NOCHECK)
end

# convert argument to given R
Quotient{R,I,X,Id}(v::Quotient{R,I,X,Id}) where {I,X,R<:Ring,Id} = Quotient{R,I,X,Id}(v.val)
Quotient{R,I,X,Id}(v) where {I,X,R<:Ring,Id} = Quotient{R,I,X,Id}(R(v))

# promotion and conversion
_promote_rule(::Type{<:Quotient}, ::Type{<:Quotient}) = Base.Bottom
_promote_rule(::Type{Quotient{R,I,X,Id}}, ::Type{S}) where {I,X,R,S<:Ring,Id} = Quotient{promote_type(R,S),I,X,Id}
promote_rule(::Type{Quotient{R,I,X,Id}}, ::Type{S}) where {I,X,R,S<:Integer,Id} = Quotient{R,I,X,Id}

convert(::Type{Q}, a::Q) where {R,Q<:Quotient{R}} = a
convert(::Type{Q}, a::S) where {S,R,Q<:Quotient{R}} = Q(convert(R, a))

Base.isless(p::T, q::T) where T<:Quotient = isless(p.val, q.val)

## Arithmetic

==(a::T, b::T) where T<:Quotient =  a.val == b.val
==(a::Quotient, b::Quotient) =  false
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
zero(::Type{Q}) where {S,Q<:Quotient{S}} = Q(zero(S), NOCHECK)
one(::Type{Q}) where {S,Q<:Quotient{S}} = Q(one(S), NOCHECK)
value(a::QuotientRing) = a.val
characteristic(::Type{Quotient{R,I,X,Id}}) where {R,I,X,Id} = Id[1]
dimension(::Type{Quotient{R,I,X,Id}}) where {R,I,X,Id} = Id[2]
order(::Type{Quotient{R,I,X,Id}}) where {R,I,X,Id} = Id[3]

# induced homomorphism - invalid if Q = R/I and I not in kernel(F)
function (h::Hom{F,R,S})(a::Q) where {F,R,S,Q<:Quotient{<:R}}
    iszero(F(modulus(Q))) || throw(DomainError((F,R), "ideal not in kernel of homomorphism"))
    F(a.val)
end

# note:
# the real work is in the functions `Ideal`, `rem`, `invert`, `isinvertible` which
# have all been delegated to Ideal

## Help functions

# return the ideal associated uniquely with this quotient ring
modulus(t::Type{<:Quotient{R}}) where R = gettypevar(t).modulus

# standard functions
==(a::Quotient{S,I,X},b::Quotient{T,I,X}) where {I,X,S,T} = a.val == b.val
hash(a::Quotient, h::UInt) = hash(a.val, hash(modulus(a), h))

function Base.show(io::IO, a::Quotient)
    v = a.val
    m = modulus(a)
    print(io, v, " mod(", m, ")")
end

//(a::G, b::G) where G<:QuotientRing = a / b
div(a::G, b::G) where G<:QuotientRing = a / b
rem(a::G, b::G) where G<:QuotientRing = zero(G)
gcd(a::G, b::G) where G<:QuotientRing = one(G)
gcdx(a::G, b::G) where G<:QuotientRing = one(G), zero(G), zero(G)
pgcd(a::G, b::G) where G<:QuotientRing = gcd(a, b)
pgcdx(a::G, b::G) where G<:QuotientRing = gcdx(a, b)
