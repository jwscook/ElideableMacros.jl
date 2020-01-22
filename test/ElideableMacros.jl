using Test, ElideableMacros

ENV["ELIDE_ASSERTS"] = "yes"
ENV["ELIDE_NANZEROER"] = "1"

@testset "HelpfulMacros" begin

  @testset "elidableassert" begin
    try
      @elidableassert 1 == 1 # pass
      @test true
    catch
      @test false
    end
    try
      @elidableassert 1 == 2 # elide
      @test true
    catch
      @test false
    end
  end

  @testset "elidableenv has two" begin
    env = @elidableenv
    @test length(env) == 2
    @test env["ELIDE_ASSERTS"] == "yes"
    @test env["ELIDE_NANZEROER"] == "1"
  end

  @testset "elidablenanzeroer" begin
    @test 1.0 == @elidablenanzeroer 1.0
    @test isnan(@elidablenanzeroer NaN)
  end

  @testset "elidableenv has two" begin
    @test length(@elidableenv) == 2
  end

end
