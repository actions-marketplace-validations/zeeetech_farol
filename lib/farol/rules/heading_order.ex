defmodule Farol.Rules.HeadingOrder do
  @moduledoc "Heading levels must not skip: an h3 after an h1 means a missing h2."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @levels ~w(h1 h2 h3 h4 h5 h6)

  @impl true
  def id, do: "heading-order"

  @impl true
  def wcag, do: "1.3.1"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :warning

  @impl true
  def why do
    "screen reader users skim pages by jumping between headings, the way " <>
      "sighted users scan with their eyes. A skipped level (h1 straight to " <>
      "h3) reads like a missing chapter: something was announced as nested " <>
      "under a heading that does not exist."
  end

  @impl true
  def fix do
    "pick the heading level that matches the document structure, not the " <>
      "font size you want. Style it with CSS afterwards."
  end

  @impl true
  def check(nodes) do
    headings = Node.find(nodes, &(&1.tag in @levels))

    {_previous, findings} =
      Enum.reduce(headings, {nil, []}, fn heading, {previous, findings} ->
        level = level_of(heading)

        # The first heading sets the baseline: fragments legitimately start
        # at h2 or deeper because the page around them owns the h1.
        if previous != nil and level > previous + 1 do
          {level, [finding(heading, previous) | findings]}
        else
          {level, findings}
        end
      end)

    Enum.reverse(findings)
  end

  defp level_of(%Node{tag: "h" <> digit}), do: String.to_integer(digit)

  defp finding(node, previous) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "<#{node.tag}> follows an h#{previous}: heading levels skip",
      snippet: Node.snippet(node)
    }
  end
end
