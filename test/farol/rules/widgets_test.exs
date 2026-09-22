defmodule Farol.Rules.WidgetsTest do
  use ExUnit.Case, async: true

  defp check(rule, html), do: Farol.check(html, only: [rule])

  describe "button-name" do
    test "flags icon-only buttons with no name" do
      assert [%{rule: "button-name"}] =
               check("button-name", ~s(<button><svg></svg></button>))
    end

    test "passes with text, aria-label, or a labeled image" do
      assert check("button-name", ~s(<button>save</button>)) == []
      assert check("button-name", ~s(<button aria-label="close"><svg></svg></button>)) == []
      assert check("button-name", ~s(<button><img alt="search"></button>)) == []
    end

    test "role=button counts as a button" do
      assert [%{rule: "button-name"}] =
               check("button-name", ~s(<div role="button"></div>))
    end
  end

  describe "link-name" do
    test "flags empty links" do
      assert [%{rule: "link-name"}] = check("link-name", ~s(<a href="/x"></a>))
    end

    test "passes with text, aria-label, or a labeled image" do
      assert check("link-name", ~s(<a href="/x">read the docs</a>)) == []
      assert check("link-name", ~s(<a href="/x" aria-label="home"><svg></svg></a>)) == []
      assert check("link-name", ~s(<a href="/x"><img alt="logo"></a>)) == []
    end

    test "anchors without href are not links" do
      assert check("link-name", ~s(<a name="section"></a>)) == []
    end
  end

  describe "iframe-title" do
    test "flags iframes without title" do
      assert [%{rule: "iframe-title"}] =
               check("iframe-title", ~s(<iframe src="/calc"></iframe>))
    end

    test "passes with title or aria-label" do
      assert check("iframe-title", ~s(<iframe src="/calc" title="shipping calculator"></iframe>)) ==
               []
    end
  end
end
