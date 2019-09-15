
# promotions and conversions
function promote_rule(T::Type{<:Ring}, S::Type{<:Ring})
    depth(T) < depth(S) ? _promote_rule(S, T) : _promote_rule(T, S)
end

for op in (:+, :-, :*, :/, :(==), :divrem, :div, :rem, :gcd, :gcdx, :pgcd, :pgcdx)
    @eval begin
        ($op)(a::Ring, b::Ring) = ($op)(promote(a, b)...)
        ($op)(a::Ring, b::Union{Integer,Rational}) = ($op)(promote(a, b)...)
        ($op)(a::Union{Integer,Rational}, b::Ring) = ($op)(promote(a, b)...)
    end
end

# generic operations
basetype(::T) where T<:Ring = basetype(T)

function /(a::T, b::T) where T<:Ring
    if b isa Union{FractionField,QuotientRing}
        a * inv(b)
    else
        d, r = divrem(a, b)
        iszero(r) || throw(DomainError((a, b), "not dividable a/b."))
        T(d)
    end
end
\(a::Ring, b::Ring) = b / a
^(a::Ring, n::Integer) = Base.power_by_squaring(a, n)
zero(x::Ring) = zero(typeof(x))
one(x::Ring) = one(typeof(x))
inv(a::Ring) = isunit(a) ? 1 / a : throw(DomainError(a, "cannot divide by non-unit."))
# enable generic matrix factorization
abs(a::Ring) = isunit(a) ? 1 : 0

"""
    order(Z::Type{<:Ring})

Returns the number of elements of (finite) ring `Z` or `0` if `|Z| == inf`. 
"""
order(::Type{Z}) where Z<:ZZmod = modulus(Z)
function order(::Type{T}) where {m,X,Z,T<:Quotient{m,UnivariatePolynomial{X,Z}}}
    order(Z) ^ deg(modulus(T))
end
order(::Type{<:Ring}) = 0

"""
    characteristic(Z::Type{<:Ring})

Returns the characteristic `c` of ring `Z`. `c` is the smallest positive integer
with `c * one(Z) == 0`, or `0` if `c * one(Z) != 0` for all positive integers `c`.
"""
characteristic(::Type{Z}) where Z<:ZZmod = order(Z)
characteristic(::Type{T}) where {m,Z,T<:Quotient{m,Z}} = characteristic(Z)
characteristic(::Type{T}) where {Z,T<:Frac{Z}} = characteristic(Z)
characteristic(::Type{T}) where {Z,T<:Polynomial{Z}} = characteristic(Z)
characteristic(::Type{<:Ring}) = 0

"""
    deg(r::Ring)

Return the degree of ring element `r`. For zero elements, that is `-1`, otherwise `0`
for non-polynomials, the ordinary degree for univariate polynomials and the
maximum degree for multivariate polynomials.
"""
deg(x::Ring) = iszero(x) ? -1 : 0 # fallback

divrem(a::T, b::T) where T<:Ring =  throw(MethodError(divrem, (a, b)))
div(a::T, b::T) where T<:Ring = divrem(a, b)[1]
rem(a::T, b::T) where T<:Ring = divrem(a, b)[2]
"""
    isdiv(a, b)

Return if ring element `a` is dividable by `b` without remainder.
"""
isdiv(a::T, b::T) where T <: Ring = iszero(rem(a, b))

"""
    iscoprime(a, b)

Return if there is a non-unit common divisor of `a` and `b`.
"""
iscoprime(a::T, b::T) where T<:Ring = isunit(a) || isunit(b)

divrem(a::T, b::T) where T<:QuotientRing = (a / b, zero(a))
"""
    lc(r::Ring)

Return the leading coefficient of `r`. For non-polynomials return `r` itself.
"""
lc(x::Ring) = x

"""
    lcunit(r::Ring)

Return `r` if it's a unit, otherwise return a unit element `s` of the same ring or of
an object, which may be promoted to this ring, so `r / s` has a simplified form.
Example, for a polynomial over a field, the the leading coefficient.
"""
lcunit(x::Ring) = isunit(x) ? x : _lcunit(x)
_lcunit(x::Ring) = one(x)

modulus(::T) where T<:Ring = modulus(T)
copy(p::QuotientRing) = typeof(p)(p.val)
# make Ring elements behave like scalars with broadcasting
Base.broadcastable(x::Ring) = Ref(x)

# apply homimorphism
(h::Hom{F,R,S})(a::R) where {F,R,S} = F(a)::S

# generic Euclid's algorithm
function gcd(a::T, b::T) where T<:Ring
    while !iszero(b)
        a, b = b, rem(a, b)
        issimpler(b, a) || throw(DomainError((a,b), "b is not simpler than a"))
    end
    u = lcunit(a)
    isone(a) ? a : a * inv(u)
end

# extension to array
function gcd(aa::Union{AbstractVector{T},NTuple{N,T}}) where {N,T<:Ring}
    n = length(aa)
    n == 0 && return zero(T)
    n == 1 && return aa[1]
    g = gcd(aa[1], aa[2])
    for i = 3:n
        isunit(g) && break
        g = gcd(aa[i], g)
    end
    g
end
gcd(a::T...) where T<:Ring = gcd(a)

# generic extended Euclid's algorithm
function gcdx(a::T, b::T) where T<:Ring
    s0, s1 = one(T), zero(T)
    t0, t1 = s1, s0
    # invariant: a * s0 + b * t0 == gcd(a, b)
    while !iszero(b)
        q, r = divrem(a, b)
        a, b = b, r
        issimpler(b, a) || throw(DomainError((a,b), "b is not simpler than a"))
        s0, s1 = s1, s0 - q * s1
        t0, t1 = t1, t0 - q * t1
    end
    if isunit(a)
        a, s0, t0 = one(T), s0 / a, t0 / a
    end
    a, s0, t0
end

function gcdx(a::Union{AbstractVector{T},NTuple{N,T}}) where {N,T<:Ring}
    n = length(a)
    n == 0 && return zero(T), zero(T), zero(T)
    u = similar(a)
    g = a[1]
    u[1] = one(T)
    for i = 2:n
        g, s, u[i] = gcdx(g, a[i])
        for j = 1:i-1
            u[j] *= s
        end
    end
    g, u
end
gcdx(a::T...) where T<:Ring = gcdx([a...])

# least common multiplier derived from gcd
function lcm(a::T, b::T) where T<:Ring
    div(a, gcd(a, b)) * b
end

function lcm(aa::AbstractVector{T}) where T<:Ring
    n = length(aa)
    n == 0 && return one(T)
    n == 1 && return aa[1]
    g = lcm(aa[1], aa[2])
    for i = 3:n
        g = lcm(aa[i], g)
    end
    g
end

function Base.powermod(x::R, p::Integer, m::R) where R<:Ring
    if p == 1
        return copy(x)
    elseif p == 0
        return one(x)
    elseif p == 2
        return rem(x * x, m)
    elseif p < 0
        isone(x) && return copy(x)
        isone(-x) && return iseven(p) ? one(x) : copy(x)
        throw(ArgumentError("negative powers not supported"))
    end
    t = trailing_zeros(p) + 1
    p >>= t
    while (t -= 1) > 0
        x  = rem(x * x, m)
    end
    y = x
    while p > 0
        t = trailing_zeros(p) + 1
        p >>= t
        while (t -= 1) >= 0
            x  = rem(x * x, m)
        end
        y = rem(y * x, m)
    end
    return y
end

