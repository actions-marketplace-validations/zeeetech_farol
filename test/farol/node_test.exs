defmodule Farol.NodeTest do
  use ExUnit.Case, async: true

  alias Farol.{Adapter.HTML, Node}

  defp parse(html), do: HTML.parse(html) |> elem(1)

  test "parses elements with attributes and text children" do
    [node] = parse(~s(<p class="intro">hello</p>))

    assert node.tag == "p"
    assert Node.attr(node, "class") == "intro"
    assert Node.text(node) == "hello"
  end

  test "flatten returns elements in document order, text excluded" do
    nodes = parse(~s(<div><span>a</span>text<b>b</b></div><i>c</i>))

    assert nodes |> Node.flatten() |> Enum.map(& &1.tag) == ["div", "span", "b", "i"]
  end

  test "has_attr? distinguishes empty values from absent attributes" do
    [img] = parse(~s(<img alt="" src="a.jpg">))

    assert Node.has_attr?(img, "alt")
    refute Node.has_attr?(img, "title")
  end

  test "attrs_with_prefix collects namespaced attributes" do
    [node] = parse(~s(<div aria-label="x" aria-hidden="true" id="y"></div>))

    assert node |> Node.attrs_with_prefix("aria-") |> Enum.sort() == [
             {"aria-hidden", "true"},
             {"aria-label", "x"}
           ]
  end

  test "snippet renders the opening tag" do
    [img] = parse(~s(<img src="avatar.jpg">))

    assert Node.snippet(img) == ~s(<img src="avatar.jpg">)
  end
end
