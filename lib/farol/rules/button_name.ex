defmodule Farol.Rules.ButtonName do
  @moduledoc "Buttons need an accessible name."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "button-name"

  @impl true
  def wcag, do: "4.1.2"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "icon-only buttons are the classic offender: a trash-can SVG announces " <>
      "as \"button\" with no hint of what it does. Voice control users " <>
      "cannot say \"click delete\" because there is no name to speak. The " <>
      "icon communicates to sighted users only."
  end

  @impl true
  def fix do
    "put text inside the button when you can. For icon buttons, add " <>
      "aria-label=\"delete item\" (and title for a tooltip, they compose " <>
      "well)."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&button?/1)
    |> Enum.reject(&named?/1)
    |> Enum.map(&finding/1)
  end

  defp button?(node) do
    node.tag == "button" or Node.attr(node, "role") == "button"
  end

  defp named?(node) do
    has_text?(node) or
      Node.has_attr?(node, "aria-label") or
      Node.has_attr?(node, "aria-labelledby") or
      Node.has_attr?(node, "title") or
      has_labeled_image?(node)
  end

  defp has_text?(node) do
    Node.text(node) |> String.trim() != ""
  end

  # A button wrapping a labeled image borrows the image's alt as its name.
  defp has_labeled_image?(node) do
    [node]
    |> Node.find(&(&1.tag == "img"))
    |> Enum.any?(fn img -> (Node.attr(img, "alt") || "") |> String.trim() != "" end)
  end

  defp finding(node) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "#{Node.snippet(node)} has no accessible name",
      snippet: Node.snippet(node)
    }
  end
end
