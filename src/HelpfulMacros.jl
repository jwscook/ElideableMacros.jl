module HelpfulMacros

export @elidableassert, @elidablenanzeroer

"""
The Julia @assert macro, except it can be compiled by one of two ways:
1) Set `ENV["ELIDE_ASSERTS"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elideasserts() = true` in the module that calls @elidableassert
but not both
"""
macro elidableassert(assertion, messages...)
  elide = haskey(ENV, "ELIDE_ASSERTS") &&
    ENV["ELIDE_ASSERTS"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elideasserts) ? elideasserts() : false;
  if @isdefined(elideasserts) && haskey(ENV, "ELIDE_ASSERTS") &&
    ENV["ELIDE_ASSERTS"] ∈ ("yes", "true", "1", "on");
    error("Set only ENV[\"ELIDE_ASSERTS\"] or elideasserts(), not both.");
  end
  if !elide
    esc(:(
      if !isempty($messages)
        @assert $assertion $messages
      else
        @assert $assertion
      end
      ))
  end
end

"""
Replace NaNs with zeros
Compile out this macro by one of two ways:
1) Set `ENV["ELIDE_NAN_ZEROER"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elidenanzeroer() = false` in the module that calls @elidablenanzeroer
but not both
"""
macro elidablenanzeroer(value)
  elide = haskey(ENV, "ELIDE_NAN_ZEROER") &&
    ENV["ELIDE_NAN_ZEROER"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elidenanzeroer) ? elidenanzeroer() : false;
  if @isdefined(elidenanzeroer) && haskey(ENV, "ELIDE_NAN_ZEROER") &&
    ENV["ELIDE_NAN_ZEROER"] ∈ ("no", "false", "0", "off");
    error("Set only ENV[\"ELIDE_NAN_ZEROER\"] or elidenanzeroer(), not both.");
  end;
  if !elide
    esc(:(
      _replace(x::T) where {T<:Real} = isnan(x) ? zero(T) : x;
      function _replace(x::T) where {T<:Complex};
      local r = real(x);
      local i = imag(x);
      local br = isnan(r);
      local bi = isnan(i);
      (!br && !bi) && return x;
      (!br && bi) && return T(r, 0);
      (br && !bi) && return T(0, i);
      (br && bi) && return T(0, 0);
      end;
      return _replace.($value)
      ))
  else
    esc(:(return $value))
  end
end
end
