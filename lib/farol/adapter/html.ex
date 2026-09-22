defmodule Farol.Adapter.HTML do
  @moduledoc """
  Parses rendered HTML strings into `Farol.Node` trees via `lazy_html`
  (the lexbor engine, through a precompiled NIF).

  `LazyHTML.from_fragment/1` is used deliberately: LiveView test helpers
  like `render_component/2` return fragments, and lexbor still keeps
  `<html>`, `<head>` and `<body>` as regular elements when a full document
  shows up. One code path serves both shapes.
  """

  @behaviour Farol.Adapter

  alias Farol.Node

  @impl true
  def parse(html, _opts \\ []) when is_binary(html) do
    nodes =
      html
      |> parse_document()
      |> LazyHTML.to_tree()
      |> Enum.map(&Node.from_tree/1)
      |> Enum.reject(&is_nil/1)

    {:ok, nodes}
  end

  # Fragment parsing drops <html>/<head>/<body> (invalid in fragment
  # context), which would blind the document-level rules. Full pages parse
  # as documents; rendered components parse as fragments.
  defp parse_document(html) do
    if html =~ ~r/<html[\s>]/i or html =~ ~r/<!doctype/i do
      LazyHTML.from_document(html)
    else
      LazyHTML.from_fragment(html)
    end
  end
end
