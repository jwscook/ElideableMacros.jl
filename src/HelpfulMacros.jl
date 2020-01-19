module HelpfulMacros

export @isdefined, @elidableassert

macro elidableassert(assertion, messages...)
  esc(:(
    elideassert = if haskey($(ENV), "ELIDE_ASSERTS")
      $(ENV)["ELIDE_ASSERTS"] ∈ ("yes", "true", "1") ? true : false
    else
      false
    end;
    elideassert |= @isdefined(elideasserts) ? elideasserts() : false;
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

end
