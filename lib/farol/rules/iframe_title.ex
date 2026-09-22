defmodule Farol.Rules.IframeTitle do
  @moduledoc "Iframes need a title describing their content."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "iframe-title"

  @impl true
  def wcag, do: "4.1.2"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "an iframe is a page inside the page. Screen readers announce the title " <>
      "before entering it, so users can decide whether to go in or skip. " <>
      "Without it they hear the src URL (\"i frame, h t t p s colon slash " <>
      "slash...\") or nothing at all."
  end

  @impl true
  def fix do
    "add a title that says what the frame contains: " <>
      "title=\"shipping calculator\" beats title=\"iframe\"."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&(&1.tag == "iframe"))
    |> Enum.reject(fn node ->
      (Node.attr(node, "title") || "") |> String.trim() != "" or
        Node.has_attr?(node, "aria-label")
    end)
    |> Enum.map(&finding/1)
  end

  defp finding(node) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "#{Node.snippet(node)} has no title",
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
