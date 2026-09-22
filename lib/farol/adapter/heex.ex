if Code.ensure_loaded?(Phoenix.LiveView.TagEngine.Parser) do
  defmodule Farol.Adapter.HEEx do
    @moduledoc """
    Parses HEEx template source into `Farol.Node` trees, statically.

    Uses `Phoenix.LiveView.TagEngine.Parser` (the parser behind the HEEx
    compiler), so what farol sees is exactly what LiveView compiles. This
    is an internal, undocumented LiveView module: it lives behind this
    adapter on purpose, so an upstream change touches one file, not the
    rule catalog.

    Dynamic content maps onto static structure like this:

      * `attr={@expr}` attributes keep the expression source as their value
        and land in `node.dynamic_attrs`. Presence-based rules (img-alt)
        count them; vocabulary checks (valid-role) skip them.
      * `{@attrs}` spread attributes are dropped: nothing static to check.
      * `<%= if/for ... do %> blocks` contribute their branch children, so
        markup inside conditionals is still audited.
      * Components (`<.badge>`, `<MyApp.Card>`) become nodes with their
        source tag spelling; rules that target HTML tags ignore them.
    """

    @behaviour Farol.Adapter

    alias Farol.Node
    alias Phoenix.LiveView.TagEngine.Parser

    @impl true
    def parse(source, opts \\ []) when is_binary(source) do
      file = Keyword.get(opts, :file, "nofile")

      case Parser.parse(source, tag_handler: Phoenix.LiveView.HTMLEngine, file: file) do
        {:ok, %Parser{nodes: nodes}} -> {:ok, to_nodes(nodes)}
        {:error, line, column, message} -> {:error, {line, column, message}}
      end
    end

    defp to_nodes(parser_nodes) do
      Enum.flat_map(parser_nodes, &to_node/1)
    end

    defp to_node({:block, _type, name, attrs, children, meta, _close_meta}) do
      [element(name, attrs, to_nodes(children), meta)]
    end

    defp to_node({:self_close, _type, name, attrs, meta}) do
      [element(name, attrs, [], meta)]
    end

    defp to_node({:text, text, _meta}), do: [text]

    # Conditionals and comprehensions: audit every branch's markup.
    defp to_node({:eex_block, _marker, clauses, _meta}) do
      Enum.flat_map(clauses, fn {branch_nodes, _end_marker, _meta} ->
        to_nodes(branch_nodes)
      end)
    end

    # eex expressions, body expressions and comments carry no static markup.
    defp to_node({_dynamic, _content, _meta}), do: []

    defp element(name, attrs, children, meta) do
      {static, dynamic} =
        for {attr_name, value, _attr_meta} <- attrs,
            is_binary(attr_name),
            reduce: {%{}, []} do
          {static, dynamic} ->
            case value do
              {:string, value, _} -> {Map.put(static, attr_name, value), dynamic}
              {:expr, code, _} -> {Map.put(static, attr_name, code), [attr_name | dynamic]}
              nil -> {Map.put(static, attr_name, ""), dynamic}
            end
        end

      %Node{
        tag: meta[:tag_name] || name,
        attrs: static,
        children: children,
        line: meta[:line],
        column: meta[:column],
        dynamic_attrs: Enum.reverse(dynamic)
      }
    end
  end
end
