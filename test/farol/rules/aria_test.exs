defmodule Farol.Rules.AriaTest do
  use ExUnit.Case, async: true

  defp check(rule, html), do: Farol.check(html, only: [rule])

  describe "valid-role" do
    test "flags unknown roles" do
      assert [%{rule: "valid-role", message: message}] =
               check("valid-role", ~s(<div role="buton">x</div>))

      assert message =~ ~s(role "buton")
    end

    test "passes with spec roles" do
      assert check("valid-role", ~s(<div role="button">x</div>)) == []
      assert check("valid-role", ~s(<nav role="navigation">x</nav>)) == []
    end
  end

  describe "valid-aria-attr" do
    test "flags misspelled aria attributes" do
      assert [%{rule: "valid-aria-attr", message: message}] =
               check("valid-aria-attr", ~s(<button aria-lable="close">x</button>))

      assert message =~ "aria-lable"
    end

    test "passes with spec attributes" do
      assert check(
               "valid-aria-attr",
               ~s(<button aria-label="close" aria-expanded="false">x</button>)
             ) ==
               []
    end
  end

  describe "no-aria-on-hidden" do
    test "flags aria on hidden elements" do
      assert [%{rule: "no-aria-on-hidden"}] =
               check("no-aria-on-hidden", ~s(<div hidden aria-label="secret">x</div>))

      assert [%{rule: "no-aria-on-hidden"}] =
               check(
                 "no-aria-on-hidden",
                 ~s(<div style="display: none" role="alert">x</div>)
               )
    end

    test "aria-hidden alone is redundant but honest" do
      assert check("no-aria-on-hidden", ~s(<div hidden aria-hidden="true">x</div>)) == []
    end

    test "visible elements keep their aria" do
      assert check("no-aria-on-hidden", ~s(<div aria-label="shown">x</div>)) == []
    end
  end
end
