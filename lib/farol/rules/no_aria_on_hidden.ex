defmodule Farol.Rules.NoAriaOnHidden do
  @moduledoc "aria on hidden elements is dead code: nothing announces it."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @hidden_style ~r/display\s*:\s*none|visibility\s*:\s*hidden/

  @impl true
  def id, do: "no-aria-on-hidden"

  @impl true
  def wcag, do: "4.1.2"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :warning

  @impl true
  def why do
    "elements removed from the accessibility tree (hidden, display:none, " <>
      "visibility:hidden) never reach a screen reader, so any aria on them " <>
      "is a promise the page does not keep. It also misleads the next " <>
      "developer, who believes the state is announced."
  end

  @impl true
  def fix do
    "if the element should be announced, unhide it. If it should stay " <>
      "hidden, drop the aria. To hide visually while keeping semantics, use " <>
      "a visually-hidden CSS class instead of display:none."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&hidden?/1)
    |> Enum.flat_map(fn node ->
      case flagged_attrs(node) do
        [] -> []
        attrs -> [finding(node, attrs)]
      end
    end)
  end

  defp hidden?(node) do
    Node.has_attr?(node, "hidden") or
      (Node.attr(node, "style") || "") =~ @hidden_style
  end

  # role counts too; aria-hidden is exempt since hiding an already hidden
  # element is redundant but honest.
  defp flagged_attrs(node) do
    aria =
      node
      |> Node.attrs_with_prefix("aria-")
      |> Enum.map(fn {name, _value} -> name end)
      |> Kernel.--(["aria-hidden"])

    if Node.has_attr?(node, "role"), do: ["role" | aria], else: aria
  end

  defp finding(node, attrs) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message:
        "#{Node.snippet(node)} is hidden but carries #{Enum.join(attrs, ", ")}: " <>
          "nothing will announce them",
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
