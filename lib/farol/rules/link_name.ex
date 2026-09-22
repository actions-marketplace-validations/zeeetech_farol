defmodule Farol.Rules.LinkName do
  @moduledoc "Links need an accessible name that makes sense out of context."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "link-name"

  @impl true
  def wcag, do: "2.4.4"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "screen reader users browse links as a list, ripped out of the " <>
      "surrounding paragraph. An empty link announces just its href; a " <>
      "\"click here\" announces nothing about where it goes. Links are " <>
      "navigation: their name is the destination."
  end

  @impl true
  def fix do
    "give the link meaningful text (\"download the annual report\", not " <>
      "\"click here\"). Icon links take aria-label. If the link wraps an " <>
      "image, the image's alt becomes the link name."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&(&1.tag == "a" and Node.has_attr?(&1, "href")))
    |> Enum.reject(&named?/1)
    |> Enum.map(&finding/1)
  end

  defp named?(node) do
    Node.text(node) |> String.trim() != "" or
      Node.has_attr?(node, "aria-label") or
      Node.has_attr?(node, "aria-labelledby") or
      Node.has_attr?(node, "title") or
      has_labeled_image?(node)
  end

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
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
