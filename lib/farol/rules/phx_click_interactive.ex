defmodule Farol.Rules.PhxClickInteractive do
  @moduledoc "phx-click on a non-interactive element is mouse-only by default."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @interactive_tags ~w(button input select textarea summary option)
  @interactive_roles ~w(button link switch checkbox menuitem tab option radio)

  @keyboard_handlers ~w(
    phx-keydown phx-keyup phx-window-keydown phx-window-keyup
  )

  @impl true
  def id, do: "phx-click-interactive"

  @impl true
  def wcag, do: "2.1.1"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "phx-click answers to a mouse. Keyboard users (and switch devices, and " <>
      "voice control) activate elements through focus plus Enter or Space, " <>
      "which only works on elements that are focusable and expose the right " <>
      "role. A <div phx-click> is invisible to all of them: it is not in " <>
      "the tab order and announces as plain text."
  end

  @impl true
  def fix do
    "reach for <button> first: it gives you focus, keyboard activation and " <>
      "the role for free. If the element truly cannot be a button, add " <>
      "role=\"button\", tabindex=\"0\" and a phx-keydown handler for " <>
      "Enter/Space."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&Node.has_attr?(&1, "phx-click"))
    |> Enum.flat_map(fn node ->
      case missing_pieces(node) do
        [] -> []
        missing -> [finding(node, missing)]
      end
    end)
  end

  defp missing_pieces(%Node{tag: tag}) when tag in @interactive_tags, do: []

  # <a> without href is not focusable either.
  defp missing_pieces(%Node{tag: "a"} = node) do
    if Node.has_attr?(node, "href"), do: [], else: ["href"]
  end

  defp missing_pieces(node) do
    [
      role_missing(node),
      tabindex_missing(node),
      keyboard_missing(node)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp role_missing(node) do
    # A dynamic role is given the benefit of the doubt: it may resolve to a
    # perfectly interactive role at runtime.
    cond do
      Node.dynamic?(node, "role") -> nil
      Node.attr(node, "role") in @interactive_roles -> nil
      true -> "an interactive role"
    end
  end

  defp tabindex_missing(node) do
    if Node.has_attr?(node, "tabindex"), do: nil, else: "tabindex"
  end

  defp keyboard_missing(node) do
    if Enum.any?(@keyboard_handlers, &Node.has_attr?(node, &1)) do
      nil
    else
      "a keyboard handler (phx-keydown)"
    end
  end

  defp finding(node, missing) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message:
        "#{Node.snippet(node)} handles phx-click but is not keyboard " <>
          "accessible (missing: #{Enum.join(missing, ", ")})",
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
