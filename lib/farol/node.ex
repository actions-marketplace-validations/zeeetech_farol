defmodule Farol.Node do
  @moduledoc """
  The normalized element every rule sees.

  Adapters (HTML today, HEEx tomorrow) parse their input into this struct so
  rules are written once and run against any source. A node is an element:
  a tag name, its attributes, and its children. Text content stays as plain
  binaries inside `children`, so nothing from the original document is lost.

  The struct mirrors the classic `{tag, attributes, children}` HTML tree
  triple, with attributes as a map for cheap lookups.

  Static sources (HEEx templates) also carry `line`/`column` of the opening
  tag, and mark attributes written as Elixir expressions (`alt={@alt}`) in
  `dynamic_attrs`: the attr map holds the expression source for those, and
  rules treat them as "present but unknowable" rather than as literal text.
  """

  @type t :: %__MODULE__{
          tag: String.t(),
          attrs: %{String.t() => String.t()},
          children: [t() | String.t()],
          line: pos_integer() | nil,
          column: pos_integer() | nil,
          dynamic_attrs: [String.t()]
        }

  defstruct [:tag, :line, :column, attrs: %{}, children: [], dynamic_attrs: []]

  @doc """
  Builds a node from a `LazyHTML.Tree` tuple, keeping text children as
  binaries. Comments, doctypes and other non-element entries become `nil`
  so callers can reject them.
  """
  def from_tree({tag, attrs, children}) when is_binary(tag) and is_list(children) do
    %__MODULE__{
      tag: tag,
      attrs: Map.new(attrs),
      children: children |> Enum.map(&from_tree/1) |> Enum.reject(&is_nil/1)
    }
  end

  def from_tree(text) when is_binary(text), do: text
  def from_tree(_other), do: nil

  @doc "Returns the value of an attribute, or `nil` when absent."
  def attr(%__MODULE__{attrs: attrs}, name), do: Map.get(attrs, name)

  @doc "True when the attribute exists, even with an empty value (`<img alt=\"\">`)."
  def has_attr?(%__MODULE__{attrs: attrs}, name), do: Map.has_key?(attrs, name)

  @doc "All text inside the node, recursively, concatenated."
  def text(%__MODULE__{children: children}) do
    children
    |> Enum.map(fn
      %__MODULE__{} = child -> text(child)
      binary when is_binary(binary) -> binary
    end)
    |> IO.iodata_to_binary()
  end

  @doc """
  Flattens a forest into a list of elements in document order.
  Text binaries are dropped; only `%Farol.Node{}` elements remain.
  """
  def flatten(nodes) when is_list(nodes) do
    Enum.flat_map(nodes, fn
      %__MODULE__{} = node -> [node | flatten(node.children)]
      _text -> []
    end)
  end

  @doc "All elements in document order matching `pred`."
  def find(nodes, pred) when is_list(nodes) do
    nodes |> flatten() |> Enum.filter(pred)
  end

  @doc "All attribute names starting with a prefix (think `aria-`, `phx-`)."
  def attrs_with_prefix(%__MODULE__{attrs: attrs}, prefix) do
    for {name, value} <- attrs, String.starts_with?(name, prefix), do: {name, value}
  end

  @doc """
  True when the attribute was written as an Elixir expression in a template
  (`role={@role}`). The value in `attrs` is the expression source; rules
  that compare against a fixed vocabulary must skip dynamic values instead
  of flagging them.
  """
  def dynamic?(%__MODULE__{dynamic_attrs: dynamic}, name), do: name in dynamic

  @doc """
  A short rendering of the opening tag, for finding messages.
  Truncated so a wall of attributes never floods the report.
  """
  def snippet(%__MODULE__{tag: tag, attrs: attrs}) do
    attrs =
      attrs
      |> Enum.sort()
      |> Enum.map_join(" ", fn
        {name, ""} -> name
        {name, value} -> ~s(#{name}="#{value}")
      end)

    text = if attrs == "", do: "<#{tag}>", else: "<#{tag} #{attrs}>"
    String.slice(text, 0, 80)
  end
end
