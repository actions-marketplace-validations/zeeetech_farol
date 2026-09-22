defmodule Farol.ContrastTest do
  use ExUnit.Case, async: true

  alias Farol.Contrast

  describe "ratio/2 against WCAG reference values" do
    test "black on white is the maximum, 21:1" do
      assert {:ok, 21.0} = Contrast.ratio("#000000", "#FFFFFF")
    end

    test "same color is 1:1" do
      assert {:ok, 1.0} = Contrast.ratio("#9655FF", "#9655FF")
    end

    test "short hex works" do
      assert {:ok, 21.0} = Contrast.ratio("#000", "#fff")
    end

    test "the zeetech palette says what the design directive promised" do
      # accent on default surface: the tool can prove the brand pairing.
      assert {:ok, ratio} = Contrast.ratio("#9655FF", "#000A0F")
      assert ratio > 4.5

      # off-white on default surface is comfortable body text.
      assert {:ok, ratio} = Contrast.ratio("#F7F7FF", "#000A0F")
      assert ratio > 7.0
    end

    test "invalid colors error instead of crashing" do
      assert {:error, :invalid_color} = Contrast.ratio("purple", "#000000")
      assert {:error, :invalid_color} = Contrast.ratio("#GGGGGG", "#000000")
    end
  end

  describe "aa?/3" do
    test "4.5:1 for normal text, 3:1 for large" do
      assert {:error, {:below_aa, _, 4.5}} = Contrast.aa?("#777777", "#888888")
      assert {:ok, _} = Contrast.aa?("#000000", "#FFFFFF")
    end
  end

  describe "contrast-token rule" do
    setup do
      previous = Application.get_env(:farol, :tokens)

      Application.put_env(:farol, :tokens, %{
        "bg" => "#000A0F",
        "fg" => "#F7F7FF",
        "accent" => "#9655FF"
      })

      on_exit(fn ->
        if previous,
          do: Application.put_env(:farol, :tokens, previous),
          else: Application.delete_env(:farol, :tokens)
      end)

      :ok
    end

    test "hex literals in inline styles are checked" do
      html = ~s(<p style="color: #777777; background-color: #888888">mush</p>)

      assert [%{rule: "contrast-token", message: message}] =
               Farol.check(html, only: ["contrast-token"])

      assert message =~ "below the required 4.5:1"
    end

    test "token names and var() references resolve through the map" do
      assert Farol.check(
               ~s(<p style="color: fg; background-color: bg">readable</p>),
               only: ["contrast-token"]
             ) == []

      assert Farol.check(
               ~s|<p style="color: var(--accent); background-color: var(--bg)">readable</p>|,
               only: ["contrast-token"]
             ) == []
    end

    test "large text relaxes to 3:1" do
      # #636363 on black is ~3.5:1 - fails normal text, passes as large.
      assert [%{rule: "contrast-token"}] =
               Farol.check(
                 ~s(<p style="color: #636363; background-color: #000000">small</p>),
                 only: ["contrast-token"]
               )

      assert Farol.check(
               ~s(<p style="color: #636363; background-color: #000000; font-size: 24px">big</p>),
               only: ["contrast-token"]
             ) == []
    end

    test "elements without both colors are skipped" do
      assert Farol.check(
               ~s(<p style="color: #777777">no background here</p>),
               only: ["contrast-token"]
             ) == []
    end
  end

  test "the rule stays off without declared tokens" do
    Application.delete_env(:farol, :tokens)

    assert Farol.check(
             ~s(<p style="color: #777777; background-color: #888888">mush</p>),
             only: ["contrast-token"]
           ) == []
  end
end
