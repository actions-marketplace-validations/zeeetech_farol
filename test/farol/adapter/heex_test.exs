defmodule Farol.Adapter.HEExTest do
  use ExUnit.Case, async: true

  alias Farol.{Adapter.HEEx, Node}

  defp parse(heex), do: HEEx.parse(heex) |> elem(1)

  test "parses elements with attributes, text and source lines" do
    [div] = parse(~s(<div class="p-4">\n  hello\n</div>))

    assert div.tag == "div"
    assert Node.attr(div, "class") == "p-4"
    assert Node.text(div) =~ "hello"
    assert div.line == 1
  end

  test "expression attributes keep their source and are marked dynamic" do
    [img] = parse(~s(<img src={@user.avatar} alt="avatar">))

    assert Node.attr(img, "src") == "@user.avatar"
    assert Node.dynamic?(img, "src")
    assert Node.attr(img, "alt") == "avatar"
    refute Node.dynamic?(img, "alt")
  end

  test "boolean attributes map to an empty string, like the HTML engine" do
    [input] = parse(~s(<input type="text" disabled>))

    assert Node.attr(input, "disabled") == ""
  end

  test "spread attributes are dropped" do
    [div] = parse(~s(<div {@rest} id="x"></div>))

    assert Node.attr(div, "id") == "x"
    refute Node.has_attr?(div, "@rest")
  end

  test "markup inside eex blocks is audited" do
    heex = """
    <%= if @show do %>
      <img src="a.jpg">
    <% else %>
      <span>nothing</span>
    <% end %>
    """

    tags = parse(heex) |> Node.flatten() |> Enum.map(& &1.tag)

    assert tags == ["img", "span"]
  end

  test "components keep their source spelling as the tag" do
    nodes = parse(~s(<.badge label="hi" /><MyApp.Card>text</MyApp.Card>))

    assert [badge, card] = Node.flatten(nodes)
    assert badge.tag == ".badge"
    assert Node.attr(badge, "label") == "hi"
    assert card.tag == "MyApp.Card"
  end

  test "nested elements keep their own line numbers" do
    [div] = parse("<div>\n  <span>x</span>\n</div>")
    [span] = Node.find([div], &(&1.tag == "span"))

    assert span.line == 2
  end

  test "malformed templates return an error tuple with position" do
    assert {:error, {line, column, message}} = HEEx.parse(~s(<div><span></div>))
    assert is_integer(line) and is_integer(column)
    assert message =~ "span"
  end

  describe "adapter equivalence" do
    # The property that justifies Farol.Node: one fixture, both engines,
    # identical findings.
    for {name, heex, html, rules} <- [
          {"img without alt", ~s(<div><img src="a.jpg"></div>), ~s(<div><img src="a.jpg"></div>),
           ["img-alt"]},
          {"phx-click on a div", ~s(<div phx-click="open">x</div>),
           ~s(<div phx-click="open">x</div>), ["phx-click-interactive"]},
          {"unknown role", ~s(<div role="boton">x</div>), ~s(<div role="boton">x</div>),
           ["valid-role"]}
        ] do
      test name do
        heex_findings = Farol.check(unquote(heex), adapter: HEEx, only: unquote(rules))
        html_findings = Farol.check(unquote(html), only: unquote(rules))

        strip = fn findings -> Enum.map(findings, &Map.take(&1, [:rule, :severity, :message])) end

        assert strip.(heex_findings) == strip.(html_findings)
        assert heex_findings != []
      end
    end
  end
end
