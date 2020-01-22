module ElideableMacros

export @elidableassert, @elidableclamp, @elidableenv, @elidablenanzeroer
export @elidetimeandfilepath

"""
Show the environment variables
"""
macro elidableenv()
  quote
    filter(x -> occursin("ELIDE", first(x)), $(esc(ENV)))
  end
end


"""
The Julia @assert macro, except it can be compiled by one of two ways:
1) Set `ENV["ELIDE_ASSERTS"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elideasserts() = true` in the module that calls @elidableassert
but not both
"""
macro elidableassert(assertion, messages...)
  local elide = haskey(ENV, "ELIDE_ASSERTS") &&
    ENV["ELIDE_ASSERTS"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elideasserts) ? elideasserts() : false;
  if @isdefined(elideasserts) && haskey(ENV, "ELIDE_ASSERTS") &&
    ENV["ELIDE_ASSERTS"] ∈ ("yes", "true", "1", "on");
    error("Set only ENV[\"ELIDE_ASSERTS\"] or elideasserts(), not both.");
  end
  if !elide
    quote
      if !isempty($(esc(messages)))
        @assert $(esc(assertion)) $(esc(messages))
      else
        @assert $(esc(assertion))
      end
    end
  end
end

"""
Replace NaNs with zeros
Compile out this macro by one of two ways:
1) Set `ENV["ELIDE_NANZEROER"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elidenanzeroer() = false` in the module that calls @elidablenanzeroer
but not both
"""
macro elidablenanzeroer(value)
  local elide = haskey(ENV, "ELIDE_NANZEROER") &&
    ENV["ELIDE_NANZEROER"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elidenanzeroer) ? elidenanzeroer() : false;
  if @isdefined(elidenanzeroer) && haskey(ENV, "ELIDE_NANZEROER") &&
    ENV["ELIDE_NANZEROER"] ∈ ("no", "false", "0", "off");
    error("Set only ENV[\"ELIDE_NANZEROER\"] or elidenanzeroer(), not both.");
  end;
  if !elide
    return quote
      @inline _replace(x::T) where {T<:Real} = ifelse(isnan(x), zero(T), x);
      @inline function _replace(x::T) where {T<:Complex};
      r, i = reim(x);
      br = isnan(r);
      bi = isnan(i);
      (!br && !bi) && return x;
      (!br && bi) && return T(r, 0);
      (br && !bi) && return T(0, i);
      (br && bi) && return T(0, 0);
      end;
      _replace.($(esc(value)))
    end
  else
    return quote $(esc(value)) end
  end
end

"""
Clamp values to within ± value or between lower and upper bounds
Compile out this macro by one of two ways:
1) Set `ENV["ELIDE_CLAMP"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elideclamp() = false` in the module that calls @elideclamp
but not both
"""
macro elidableclamp(value, valueorlower, nothingorupper=nothing)
  isnothing(nothingorupper) && @assert valueorlower >= 0
  local lower = isnothing(nothingorupper) ? -valueorlower : valueorlower
  local upper = isnothing(nothingorupper) ? valueorlower : nothingorupper
  local elide = haskey(ENV, "ELIDE_CLAMP") &&
    ENV["ELIDE_CLAMP"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elideclamp) ? elideclamp() : false;
  if @isdefined(elideclamp) && haskey(ENV, "ELIDE_CLAMP") &&
    ENV["ELIDE_CLAMP"] ∈ ("no", "false", "0", "off");
    error("Set only ENV[\"ELIDE_CLAMP\"] or elideclamp(), not both.");
  end;
  if !elide
    return quote
      _replace(x::T) where {T<:Real} = clamp(x, $(lower), $(upper));
      _replace(x::T) where {T<:Complex} = T(_replace(real(x)),
                                            _replace(imag(x)))
      _replace.($(esc(value)))
    end
  else
    return quote $(esc(value)) end
  end
end

"""
Display the time, and the file path
Compile out this macro by one of two ways:
1) Set `ENV["ELIDE_TIMEANDFILEPATH"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elidetimeandfilepath() = false` in the module that calls @elidetimeandfilepath
but not both
"""
macro timeandfilepath()
  local elide = haskey(ENV, "ELIDE_TIMEANDFILEPATH") &&
    ENV["ELIDE_TIMEANDFILEPATH"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elideclamp) ? elideclamp() : false;
  if @isdefined(elidetimeandfilepath) &&
      haskey(ENV, "ELIDE_TIMEANDFILEPATH") &&
      ENV["ELIDE_TIMEANDFILEPATH"] ∈ ("no", "false", "0", "off");
    error("Set only ENV[\"ELIDE_TIMEANDFILEPATH\"] or elidetimeandfilepath(), not both.");
  end;
  if !elide
    quote
      using Dates; println("$(now()) $(@__FILE__)")
    end
  end
end

end
