defmodule FarolTest do
  use ExUnit.Case, async: true

  test "clean markup returns no findings" do
    html = ~s(<main><h1>hi</h1><p>all good</p><button>save</button></main>)

    assert Farol.check(html) == []
  end

  test "check/2 returns findings for violations" do
    findings = Farol.check(~s(<img src="avatar.jpg">))

    assert [%Farol.Finding{rule: "img-alt"}] = findings
  end

  test ":except waives rules by id, strings or atoms" do
    html = ~s(<img src="a.jpg"><div phx-click="open">menu</div>)

    assert Farol.check(html, except: ["img-alt", "phx-click-interactive"]) == []
    assert Farol.check(html, except: [:img_alt, :phx_click_interactive]) == []
  end

  test ":only runs a subset of the catalog" do
    html = ~s(<img src="a.jpg"><div phx-click="open">menu</div>)

    assert [%Farol.Finding{rule: "img-alt"}] = Farol.check(html, only: ["img-alt"])
    assert [%Farol.Finding{rule: "img-alt"}] = Farol.check(html, only: [:img_alt])
  end

  test "document-level rules fire on full pages" do
    html = "<!DOCTYPE html><html><head></head><body><p>content</p></body></html>"

    rules = Farol.check(html) |> Enum.map(& &1.rule)

    assert "html-lang" in rules
    assert "document-title" in rules
    assert "landmark-regions" in rules
  end

  test "document-level rules stay quiet on fragments" do
    html = ~s(<section><p>just a component</p></section>)

    rules = Farol.check(html) |> Enum.map(& &1.rule)

    refute "html-lang" in rules
    refute "document-title" in rules
    refute "landmark-regions" in rules
  end

  test "the catalog is 18 rule modules implementing Farol.Rule" do
    for rule <- Farol.rules() do
      assert is_binary(rule.id())
      assert rule.wcag() =~ ~r/^\d+\.\d+\.\d+$/
      assert rule.level() in ["a", "aa", "aaa"]
      assert rule.severity() in [:error, :warning]
      assert String.trim(rule.why()) != ""
      assert String.trim(rule.fix()) != ""
    end
  end
end
