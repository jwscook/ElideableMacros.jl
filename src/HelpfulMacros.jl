module HelpfulMacros

export @isdefined, @elidableassert

macro elidableassert(assertion, messages...)
  esc(:(
    local elideassert = if haskey(ENV, "ELIDE_ASSERTS")
      ENV["ELIDE_ASSERTS"] ∈ ("yes", "true", "1") ? true : false
    else
      false
    end;
    local elideassert |= @isdefined(elideasserts) ? elideasserts() : false;
    if !elideassert && !isempty($messages)
      @assert $assertion $messages
    elseif !elideassert
      @assert $assertion
    end
    ))
end

macro isdefined(variable)
  esc(:(
    try
      local _ = $(variable)
      true
    catch err
      isa(err, UndefVarError) ? false : rethrow(err)
    end
    ))
end

macro zeronan(value)
  esc(:(
    local zero_nans = if haskey(ENV, "ZERO_NANS")
      ENV["ZERO_NANS"] ∈ ("yes", "true", "1") ? true : false
    else
      false
    end;
    local zero_nans |= @isdefined(zeronans) ? zeronans() : false;
    replace(x::T) where {T<:Real} = isnan(x) ? zero(T) : x;
    function replace(x::T) where {T<:Complex};
      r, i = reim(x);
      br, bi = isnan(r), isnan(i);
      (!br && !bi) && return x;
      (!br && bi) && return T(r, 0);
      (br && !bi) && return T(0, i);
      (br && bi) && return T(0, 0);
    end;
    return zero_nans ? replace.($value) : $value
    ))
end

end
