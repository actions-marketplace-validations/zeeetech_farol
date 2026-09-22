defmodule Farol.Rules.LiveViewTest do
  use ExUnit.Case, async: true

  defp check(rule, html), do: Farol.check(html, only: [rule])

  describe "phx-click-interactive" do
    test "flags phx-click on a plain div" do
      assert [%{rule: "phx-click-interactive", message: message}] =
               check("phx-click-interactive", ~s(<div phx-click="open">menu</div>))

      assert message =~ "not keyboard accessible"
    end

    test "passes on natively interactive elements" do
      assert check("phx-click-interactive", ~s(<button phx-click="save">save</button>)) == []
      assert check("phx-click-interactive", ~s(<a href="/x" phx-click="track">x</a>)) == []
    end

    test "flags anchors without href" do
      assert [%{rule: "phx-click-interactive"}] =
               check("phx-click-interactive", ~s(<a phx-click="open">x</a>))
    end

    test "passes with role, tabindex and keyboard handler combined" do
      html =
        ~s(<div phx-click="open" role="button" tabindex="0" phx-keydown="open" phx-key="Enter">x</div>)

      assert check("phx-click-interactive", html) == []
    end

    test "reports only the missing pieces" do
      assert [%{message: message}] =
               check(
                 "phx-click-interactive",
                 ~s(<div phx-click="open" tabindex="0">x</div>)
               )

      assert message =~ "missing: an interactive role, a keyboard handler (phx-keydown)"
    end
  end

  describe "toggle-aria-pairing" do
    test "flags JS.toggle triggers without aria state" do
      html = ~s|<button phx-click="JS.toggle(to: '#menu')">menu</button>|

      assert [%{rule: "toggle-aria-pairing", severity: :warning}] =
               check("toggle-aria-pairing", html)
    end

    test "flags JS.show and JS.hide too" do
      assert [%{rule: "toggle-aria-pairing"}] =
               check("toggle-aria-pairing", ~s|<button phx-click="JS.show(to: '#m')">m</button>|)
    end

    test "passes with aria-expanded and aria-controls" do
      html =
        ~s|<button phx-click="JS.toggle(to: '#menu')" aria-expanded="false" aria-controls="menu">menu</button>|

      assert check("toggle-aria-pairing", html) == []
    end
  end

  describe "focus-after-patch" do
    test "flags patchable containers with focusable children" do
      html = ~s(<div phx-update="replace" id="feed"><button>like</button></div>)

      assert [%{rule: "focus-after-patch", severity: :warning}] =
               check("focus-after-patch", html)
    end

    test "passes with a phx-hook or autofocus, or without focusables" do
      assert check(
               "focus-after-patch",
               ~s(<div phx-update="replace" phx-hook="KeepFocus"><button>like</button></div>)
             ) == []

      assert check(
               "focus-after-patch",
               ~s(<div phx-update="stream" id="s"><button autofocus>new</button></div>)
             ) == []

      assert check(
               "focus-after-patch",
               ~s(<div phx-update="replace"><p>text only</p></div>)
             ) == []
    end
  end

  describe "live-region-usage" do
    test "flags flash containers outside aria-live" do
      assert [%{rule: "live-region-usage"}] =
               check("live-region-usage", ~s(<div id="flash">saved!</div>))
    end

    test "passes inside a live region or with aria-live on itself" do
      assert check(
               "live-region-usage",
               ~s(<div aria-live="polite"><div id="flash">saved!</div></div>)
             ) == []

      assert check(
               "live-region-usage",
               ~s(<div id="flash-group" role="alert">saved!</div>)
             ) == []
    end

    test "ignores elements without flash naming" do
      assert check("live-region-usage", ~s(<div id="notice">saved!</div>)) == []
    end
  end
end
