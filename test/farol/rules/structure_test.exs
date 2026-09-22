defmodule Farol.Rules.StructureTest do
  use ExUnit.Case, async: true

  defp check(rule, html), do: Farol.check(html, only: [rule])

  describe "img-alt" do
    test "flags images without alt" do
      assert [%{rule: "img-alt", severity: :error}] = check("img-alt", ~s(<img src="a.jpg">))
    end

    test "passes with alt text, empty alt, or presentation role" do
      assert check("img-alt", ~s(<img src="a.jpg" alt="cat">)) == []
      assert check("img-alt", ~s(<img src="a.jpg" alt="">)) == []
      assert check("img-alt", ~s(<img src="a.jpg" role="presentation">)) == []
    end
  end

  describe "label-association" do
    test "flags inputs with no label" do
      assert [%{rule: "label-association"}] =
               check("label-association", ~s(<input type="text" name="email">))
    end

    test "passes with label[for], wrapping label, or aria-label" do
      assert check(
               "label-association",
               ~s(<label for="e">email</label><input type="text" id="e">)
             ) == []

      assert check(
               "label-association",
               ~s(<label>email <input type="text"></label>)
             ) == []

      assert check("label-association", ~s(<input type="text" aria-label="email">)) == []
    end

    test "ignores inputs that carry their own name or are hidden" do
      assert check("label-association", ~s(<input type="hidden" name="csrf">)) == []
      assert check("label-association", ~s(<input type="submit" value="go">)) == []
    end

    test "flags selects and textareas too" do
      assert [%{rule: "label-association"}] = check("label-association", ~s(<select></select>))

      assert [%{rule: "label-association"}] =
               check("label-association", ~s(<textarea></textarea>))
    end
  end

  describe "landmark-regions" do
    test "flags documents without main" do
      html = "<html><body><p>content</p></body></html>"

      assert [%{rule: "landmark-regions", severity: :warning}] =
               check("landmark-regions", html)
    end

    test "passes with main element or role" do
      assert check("landmark-regions", "<html><body><main>x</main></body></html>") == []

      assert check(
               "landmark-regions",
               ~s(<html><body><div role="main">x</div></body></html>)
             ) == []
    end

    test "ignores fragments" do
      assert check("landmark-regions", ~s(<p>component</p>)) == []
    end
  end

  describe "heading-order" do
    test "flags skipped levels" do
      assert [%{rule: "heading-order", message: message}] =
               check("heading-order", ~s(<h1>a</h1><h3>b</h3>))

      assert message =~ "h3"
      assert message =~ "h1"
    end

    test "the first heading sets the baseline, decreases are fine" do
      assert check("heading-order", ~s(<h2>a</h2><h3>b</h3>)) == []
      assert check("heading-order", ~s(<h1>a</h1><h2>b</h2><h1>c</h1>)) == []
    end
  end

  describe "duplicate-id" do
    test "flags repeated ids" do
      assert [%{rule: "duplicate-id", message: message}] =
               check("duplicate-id", ~s(<div id="x"></div><span id="x"></span>))

      assert message =~ ~s(id "x" appears 2 times)
    end

    test "passes with unique ids" do
      assert check("duplicate-id", ~s(<div id="a"></div><div id="b"></div>)) == []
    end
  end

  describe "html-lang" do
    test "flags documents without lang" do
      assert [%{rule: "html-lang"}] = check("html-lang", "<html><body>x</body></html>")
    end

    test "passes with lang, ignores fragments" do
      assert check("html-lang", ~s(<html lang="pt-BR"><body>x</body></html>)) == []
      assert check("html-lang", ~s(<section>x</section>)) == []
    end
  end

  describe "document-title" do
    test "flags missing or empty title" do
      assert [%{rule: "document-title"}] =
               check("document-title", "<html><head></head><body>x</body></html>")

      assert [%{rule: "document-title"}] =
               check("document-title", "<html><head><title> </title></head></html>")
    end

    test "passes with a title, ignores fragments" do
      assert check("document-title", "<html><head><title>hi</title></head></html>") == []
      assert check("document-title", ~s(<p>x</p>)) == []
    end
  end
end
