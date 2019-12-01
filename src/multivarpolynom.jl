
# class constructors
# convenience type constructor:
# enable `R[:x,:y,:z,...]` as short for `MultivariatePolynomial{R,N,Id}`
function getindex(R::Type{<:Ring}, s::Symbol, t::Symbol...)
    vs = collect((s, t...))
    N = length(vs)
    Id = sintern(vs)
    new_class(MultivariatePolynomial{R,N,Id,Int,Tuple{N}}, vs)
end
function getindex(R::Type{<:Ring}, s::AbstractVector{Symbol}, t::AbstractVector{Symbol}...)
    blocks = collect((s, t...))
    vs = vcat(blocks...)
    N = length(vs)
    Id = sintern(vs)
    n = length(blocks)
    T = n == 1 ? Int : NTuple{n,Int}
    B = Tuple{[length(x) for x in blocks]...}
    new_class(MultivariatePolynomial{R,N,Id,T,B}, vs)
end


import Base: copy, convert, promote_rule
import Base: +, -, *, zero, one, ==, isless

(::Type{P})(a) where {N,T,P<:MultivariatePolynomial{T,N}} = convert(P, a)
copy(a::MultivariatePolynomial) = a
basetype(::Type{<:MultivariatePolynomial{T}}) where T = T

# promotion and conversion
_promote_rule(::Type{<:MultivariatePolynomial{R,M,X}}, ::Type{<:Polynomial}) where {X,M,R} = Base.Bottom
_promote_rule(::Type{MultivariatePolynomial{R,N,X,T,B}}, ::Type{MultivariatePolynomial{S,N,X,T,B}}) where {X,N,R,S,T,B} = MultivariatePolynomial{promote_type(R,S),N,X,T,B}
_promote_rule(::Type{P}, ::Type{S}) where {R,N,X,B,T,S<:Ring,P<:MultivariatePolynomial{R,N,X,T,B}} = MultivariatePolynomial{promote_type(R,S),N,X,T,B}
promote_rule(::Type{P}, ::Type{S}) where {R,N,X,T,B,S<:Union{Integer,Rational},P<:MultivariatePolynomial{R,N,X,T,B}} = MultivariatePolynomial{promote_type(R,S),N,X,T,B}

function convert(P::Type{MultivariatePolynomial{R,N,X,T,B}}, a::MultivariatePolynomial{S,N,X,T,B}) where {R,N,X,T,B,S}
    P(a.ind, convert.(R, a.coeff))
end
function convert(P::Type{<:MultivariatePolynomial{S}}, a::S) where S
    iszero(a) ? zero(P) : P(one(P).ind, [a])
end
function convert(P::Type{<:MultivariatePolynomial{S}}, a::T) where {S,T}
    iszero(a) ? zero(P) : P(one(P).ind, [convert(S, a)])
end

deg(p::MultivariatePolynomial) = isempty(p.ind) ? -1 : sum(leading_index(p))
isunit(a::MultivariatePolynomial) = deg(a) == 0 && isunit(a.coeff[1])
ismonom(p::MultivariatePolynomial) = length(p.ind) <= 1

function monom(P::Type{<:MultivariatePolynomial{S,N}}, xv::Vector{<:Integer}) where {N,S}
    n = length(xv)
    n == 0 && return zero(P)
    length(xv) != N && throw(ArgumentError("multivariate monom needs exponents for all $N variables"))
    P([tuple2index(P, xv)], [1])
end

function leading_index(p::MultivariatePolynomial{S,N}) where {N,S}
    isempty(p.ind) ? Int[] : numbered_index(p, length(p.ind))
end

function numbered_index(p::MultivariatePolynomial{S,N,X,<:Integer}, i::Integer) where {S,N,X}
    index2tuple(p.ind[i], N)
end

function numbered_index(p::MultivariatePolynomial{S,N,X,<:Tuple,B}, i::Integer) where {S,N,X,B<:Tuple}
    vp = tupcon(B)
    m = length(vp)
    vcat([index2tuple(p.ind[i][k], vp[k]) for k = 1:m]...)
end

# arithmetic
function zero(::Type{<:T}) where {S,T<:MultivariatePolynomial{S}}
    T(Int[], S[])
end
function one(::Type{<:T}) where {S,T<:MultivariatePolynomial{S}}
    T([zeroindex(T)], S[1])
end

-(p::T) where T<:MultivariatePolynomial = T(p.ind, -p.coeff)
-(a::T, b::T) where T<:MultivariatePolynomial = +(a, -b)
*(p::T, a::Integer) where T<:MultivariatePolynomial = T(p.ind, p.coeff .* a)
*(a::Integer, p::T) where T<:MultivariatePolynomial = T(p.ind, a .* p.coeff)
==(a::T, b::T) where T<:MultivariatePolynomial = a.ind == b.ind && a.coeff == a.coeff
isless(a::T, b::T) where T<:MultivariatePolynomial = a.ind[end] < b.ind[end]

function +(a::T...) where T<:MultivariatePolynomial
    n = length(a)
    n >  0 || throw(ArgumentError("+ requires at least one argument"))
    n == 1 && return a[1]
    c = similar(a[1].coeff)
    d = similar(a[1].ind)
    j = 0
    p = ones(Int, n)
    pm = [getindex(x, 1) for x in a]
    bound = maxindex(T)
    
    while true
        m, imin = findmin(pm)
        m == bound && break
        cj = a[imin].coeff[p[imin]]
        p[imin] += 1
        pm[imin] = getindex(a[imin], p[imin])
        for i = imin+1:n
            if pm[i] == m
                cj += a[i].coeff[p[i]]
                p[i] += 1
                pm[i] = getindex(a[i], p[i])
            end
        end
        if !iszero(cj)
            j += 1
            if j > length(d)
                resize!(d, 2*j)
                resize!(c, 2*j)
            end
            d[j] = m
            c[j] = cj
        end
    end
    resize!(c, j)
    resize!(d, j)
    T(d, c)
end

function *(a::T, b::T) where {N,S,T<:MultivariatePolynomial{S,N}}
    m = length(a.ind)
    n = length(b.ind)
    m >= n || return *(b, a)
    n == 0 && return zero(T)

    c = similar(a.coeff)
    d = similar(a.ind)
    j = 0
    p = ones(Int, n)
    pm = [numbered_sum(a, 1, b, j) for j in 1:n]
    bound = maxindex(T)

    while true
        min, imin = findmin(pm)
        min == bound && break
        cj = a.coeff[p[imin]] * b.coeff[imin]
        p[imin] += 1
        pm[imin] = numbered_sum(a, p[imin], b, imin)
        for i = imin+1:n
            if pm[i] == min
                cj += a.coeff[p[i]] * b.coeff[i]
                p[i] += 1
                pm[i] = numbered_sum(a, p[i], b, i)
            end
        end
        if !iszero(cj)
            j += 1
            if j > length(d)
                resize!(d, 2*j)
                resize!(c, 2*j)
            end
            d[j] = min
            c[j] = cj
        end
    end
    resize!(c, j)
    resize!(d, j)
    T(d, c)
end

function evaluate(p::T, a::Union{Ring,Int,Rational}...) where {N,S,T<:MultivariatePolynomial{S,N}}
    length(a) != N && throw(ArgumentError("wrong number of arguments of polynomial with $N variables"))
    n = length(p.ind)
    R = promote_type(S, typeof.(a)...)
    deg(p) < 0 && return zero(R)
    deg(p) == 1 && return R(p.coeff[1])
    vdeg = maximum(hcat(numbered_index.(p, 1:n)...), dims=2)
    xpot = [Vector{R}(undef, vdeg[i]) for i = 1:N]
    # precalculate all required monoms.
    for i = 1:N
        m = vdeg[i]
        if m > 0
            ai = bi = a[i]
            xpot[i][1] = bi
            for k = 2:m
                bi *= ai
                xpot[i][k] = bi
            end
        end
    end
    s = zero(R)
    for j = 1:n
        ex = numbered_index(p, j)
        t = p.coeff[j]
        for i = 1:N
            if ex[i] > 0
                t *= xpot[i][ex[i]]
            end
        end
        s += t
    end
    s
end

function tuple2index(::Type{P}, a::AbstractVector{<:Integer}) where {R,N,X,T,P<:MultivariatePolynomial{R,N,X,T,Tuple{N}}}
    tuple2index(a)
end

function tuple2index(::Type{P}, a::AbstractVector{<:Integer}) where {R,N,X,T,M,B,P<:MultivariatePolynomial{R,N,X,NTuple{M,T},B}}

    t = tupcon(B)
    res = Vector{T}(undef, M)
    j = 0
    for i = 1:M
        d = t[i]
        res[i] = tuple2index(a[j+1:j+d])
        j += d
    end
    tuple(res...)
end

# extract constants from Tuple{1,2,3...}
tupcon(::Type{Tuple{A}}) where A = (A,)
tupcon(::Type{Tuple{A,B}}) where {A,B} = (A, B)
tupcon(A::Type{<:Tuple}) = tuple(A.parameters...)

#= Tuple mappings. See for reference:
https://stackoverflow.com/questions/26932409/compact-storage-coefficients-of-a-multivariate-polynomial
https://en.wikipedia.org/wiki/Combinatorial_number_system

This constructs the degrevlex total ordering of monomials.
=#

"""
    tuple2index(a)

bijective mapping from tuples of non-negative integers to positive integers.
"""
function tuple2index(a::AbstractVector{<:Integer})
    c = similar(a)
    d = length(a)
    d == 0 && return c + 1
    ci = s = sum = a[1]
    for i = 2:d
        s += a[i]
        ci = s + i - 1
        sum += binomial(ci, i)
    end
    sum + 1
end

"""
    index2tuple(n, d)

bijective mapping from integers to `d`-tuples of integers.

"""
function index2tuple(n::T, d::Int) where T<:Integer
    c = Vector{T}(undef, d)
    n < 1 && throw(ArgumentError("index must be positive but is $n"))
    n -= 1
    for i = d:-1:1
        ci, b = cbin(n, i)
        c[i] = ci
        n -= b
    end
    ci = c[d]
    for i = d:-1:2
        cp = c[i-1]
        c[i] = ci - cp - 1
        ci = cp
    end
    c
end

"""
Caculate the greatest integer `c` such that `binomial(c, d) <= n`
"""
function cbin(n::T, d::Int) where T<:Integer
    d <= 0 && throw(ArgumentError("tuple size > 0 required, but is $d"))
    d == 1 && return n, n
    n == 0 && return d-1, n
    n == 1 && return d, n
    c = T(floor((n * sqrt(2pi*d))^(1/d) * d / ℯ + d/2))
    if c <= d
        c = d
        b = T(1)
    else
        b = binomial(c, d)
    end
    b == n && return c, b
    bp = b
    while b <= n
        bp = b
        c += 1
        b = b * c ÷ (c-d)
    end
    b >= n > bp && return c-1, bp
    while b > n
        bp = b
        b = b * (c-d) ÷ c
        c -= 1
    end
    return c, b
end

function indexsum(x::T, y::T, d::Int) where T<:Integer
    x > 0 && y > 0 || return 0
    tuple2index(index2tuple(x, d) + index2tuple(y, d))
end

zeroindex(P::Type{<:MultivariatePolynomial}) = fillindex(one, P)
maxindex(P::Type{<:MultivariatePolynomial}) = fillindex(typemax, P)

function fillindex(f, ::Type{<:P}) where {R,N,X,T,P<:MultivariatePolynomial{R,N,X,T,Tuple{N}}}
    f(T)
end
function fillindex(f, ::Type{<:P}) where {R,N,X,T,M,P<:MultivariatePolynomial{R,N,X,NTuple{M,T}}}
    ft = f(T)
    ntuple(x->ft, M)
end

function numbered_sum(pa::P, i::Integer, pb::P, j::Integer) where {R,N,X,T,P<:MultivariatePolynomial{R,N,X,T,Tuple{N}}}
    a = pa.ind
    b = pb.ind
    (isassigned(a, i) && isassigned(b, j)) || return maxindex(P)
    indexsum(a[i], b[j], N)
end

function numbered_sum(pa::P, i::Integer, pb::P, j::Integer) where {R,N,X,T,B,P<:MultivariatePolynomial{R,N,X,T,B}}
    a = pa.ind
    b = pb.ind
    (isassigned(a, i) && isassigned(b, j)) || return maxindex(P)
    ai = a[i]
    bi = b[j]
    vp = tupcon(B)
    ntuple(k->indexsum(ai[k], bi[k], vp[k]), length(ai))
end

function getindex(pa::P, i::Integer) where P<:MultivariatePolynomial
    isassigned(pa.ind, i) ? pa.ind[i] : maxindex(P)
end

function divides(x::V, y::V) where V<:AbstractVector{<:Integer}
    all(x .<= y)
end

varnames(p::T) where T<:MultivariatePolynomial = gettypevar(T).varnames

function showvar(io::IO, var::MultivariatePolynomial{S,N}, n::Integer) where {N,S}
    ex = numbered_index(var, n)
    vn = varnames(var)
    start = true
    for i = 1:N
        x = ex[i]
        x <= 0 && continue
        !start && print(io, '⋅')
        print(io, vn[i])
        x > 1 && print(io, '^', x)
        start = false
    end
end

function isconstterm(p::P, n::Integer) where P<:MultivariatePolynomial
    n <= 0 || p.ind[n] == zeroindex(P)
end

# division and Gröbner base calculation

function red(f::P, g::P) where {T,N,P<:MultivariatePolynomial{T,N}}

    lig = leading_index(g)
    xif = 0
    lif = lig
    for i = length(f.ind):-1:1
        li = index2tuple(f.ind[i], N)
        if divides(lig, li)
            lif = li
            xif = i
            break
        end
    end
    xif == 0 && return f, zero(P), one(T)
    c = f.coeff[xif]
    d = lc(g)
    q = monom(P, lif .- lig)
    if isone(d)
        k = q * c
        f - g * k, k, one(T) 
    elseif isunit(d)
        k = q * (c / d)
        f - g * k, k, one(T)
    else
        h = gcd(c, d)
        k = q * (c / h )
        f * h - g * k, k, h
    end
end

function red(f::P, G::AbstractArray{P}) where {T,P<:MultivariatePolynomial{T}}
    f0 = f
    fp = zero(P)
    a = zeros(P, length(G))
    dd = one(T)
    while f !== fp && !iszero(f)
        fp = f
        for (i, g) in enumerate(G)
            ffp = f
            f, k, d = red(f, g)
            if f !== ffp
                if !isone(d)
                    a .*= d
                    dd *= d
                end
                a[i] += k
            elseif iszero(f)
                break
            end
        end
    end
    f, a, dd
end

function buchberger_s(f::P, g::P) where P<:MultivariatePolynomial
    lcf = lc(f)
    lcg = lc(g)
    lif = leading_index(f)
    lig = leading_index(g)

    h = gcd(lcf, lcg)
    af = lcf / h
    ag = lcg / h
    bf = max.(lif - lig, 0)
    bg = max.(lig - lif, 0)
    monom(P, bg) * ag * f - monom(P, bf) * af * g
end

using Base.Iterators

# find initial Gröbner base using Buchberger's algorithm
function buchberger(H::AbstractArray{P}) where P<:MultivariatePolynomial
    G = unique(H)
    K = empty(G)
    while K != G
        K = copy(G)
        for (p, q) in product(K, K)
            pq = buchberger_s(p, q)
            s, a, d = red(pq, G)
            if !iszero(s) && !in(s, G)
                push!(G, s)
            end
        end
    end
    G
end

# eliminiate generators with leading terms spanned by other leading terms
function minimize!(H::AbstractArray{P}) where P<:MultivariatePolynomial
    n = length(H)
    for i = 1:n
        f = H[i]
        if !iszero(f)
            lif = leading_index(H[i])
            for g in H
                if !iszero(g) && f != g
                    if all(lif .>= leading_index(g))
                        cf = lc(f)
                        cg = lc(g)
                        if iszero(rem(cf, cg))
                            H[i] = zero(P)
                        end
                    end
                end
            end
        end
    end
    j = 0
    for i = 1:n
        f = H[i]
        if !iszero(f)
            j += 1
            if i != j
                H[j] = f
            end
        end
    end
    resize!(H, j)
    for i = 1:j
        f = H[i]
        lcu = inv(lcunit(f))
        if !isone(lcu)
            f = f * lcu
        end
        H[i] = f
    end
    H
end

# reduced Gröbner base
function reduce!(H::AbstractArray{P}) where P<:Polynomial
    n = length(H)
    for i = 1:n
        f = H[i]
        g, a, c = red(f, [g for g in H if g != f])
        if g !== f
            H[i] = g
        end
    end
    sort!(H, rev=true)
end

"""
    groebnerbase(H::AbstractVector{<:Polynomial})

Calculate the reduced groebner base from a set of generators of an ideal `<H>`.

see for example:
https://en.wikipedia.org/wiki/Gr%C3%B6bner_basis
http://www.crypto.rub.de/imperia/md/content/may/12/ws1213/kryptanal12/13_buchberger.pdf
"""
function groebnerbase(H::AbstractArray{P}) where P<:Polynomial
    buchberger(H) |> minimize! |> reduce!
end