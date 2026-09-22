defmodule Farol.Rules.LabelAssociation do
  @moduledoc "Every form control needs a programmatically associated label."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  # Types whose value already acts as the accessible name (buttons), or that
  # are never exposed to assistive tech (hidden).
  @excluded_types ~w(hidden submit button reset image)

  @impl true
  def id, do: "label-association"

  @impl true
  def wcag, do: "1.3.1"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "placeholder text is not a label: it vanishes as soon as the field has " <>
      "content, and many screen readers never announce it. Without a real " <>
      "label, someone filling your form hears \"edit text, blank\" with no " <>
      "idea of what belongs there."
  end

  @impl true
  def fix do
    "give the control an id and point a <label for=\"that-id\"> at it, or " <>
      "wrap the control inside the <label>. aria-label works for icon-only " <>
      "fields, but visible text helps everyone."
  end

  @impl true
  def check(nodes) do
    labels = Node.find(nodes, &(&1.tag == "label"))

    for_targets =
      labels
      |> Enum.map(&Node.attr(&1, "for"))
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    # A control wrapped in a <label> is associated even without for/id.
    wrapped =
      labels
      |> Enum.flat_map(fn label -> Node.find([label], &control?/1) end)
      |> MapSet.new()

    nodes
    |> Node.find(&control?/1)
    |> Enum.reject(&labeled?(&1, for_targets, wrapped))
    |> Enum.map(&finding/1)
  end

  defp control?(%Node{tag: "input"} = node) do
    Node.attr(node, "type") not in @excluded_types
  end

  defp control?(%Node{tag: tag}), do: tag in ~w(select textarea)

  defp labeled?(node, for_targets, wrapped) do
    # A dynamic id may well be targeted by a dynamic for elsewhere; the
    # static engine cannot prove otherwise, so it stays silent.
    MapSet.member?(wrapped, node) or
      Node.has_attr?(node, "aria-label") or
      Node.has_attr?(node, "aria-labelledby") or
      Node.dynamic?(node, "id") or
      (Node.attr(node, "id") != nil and Node.attr(node, "id") in for_targets)
  end

  defp finding(node) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "#{Node.snippet(node)} has no associated label",
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
