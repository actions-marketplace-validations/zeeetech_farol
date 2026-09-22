defmodule Farol.AssertionsTest do
  use ExUnit.Case, async: true

  import Farol.Assertions

  test "passes on accessible markup" do
    assert_accessible(~s(<main><h1>hi</h1><img src="a.jpg" alt="cat"></main>))
  end

  test "fails with the didactic report" do
    error =
      assert_raise ExUnit.AssertionError, fn ->
        assert_accessible(~s(<img src="avatar.jpg">))
      end

    assert error.message =~ "img-alt"
    assert error.message =~ "wcag 1.1.1 (level a)"
    assert error.message =~ "why:"
    assert error.message =~ "fix:"
    assert error.message =~ "2.2 billion"
  end

  test "except: waives rules explicitly" do
    assert_accessible(~s(<img src="avatar.jpg">), except: ["img-alt"])
  end
end
