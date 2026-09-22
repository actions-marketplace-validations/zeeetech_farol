defmodule Farol.Rules.LandmarkRegions do
  @moduledoc "Page content should live inside landmark regions."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "landmark-regions"

  @impl true
  def wcag, do: "1.3.1"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :warning

  @impl true
  def why do
    "landmarks are the table of contents of a page: screen reader users " <>
      "jump straight to <main> instead of tabbing through every nav item on " <>
      "every visit. Without them, navigation is a wall of undifferentiated " <>
      "content."
  end

  @impl true
  def fix do
    "wrap the primary content in <main> (or role=\"main\"). <header>, " <>
      "<nav>, <aside> and <footer> cover the rest of the classic regions."
  end

  @impl true
  def check(nodes) do
    # Only meaningful for full documents; a rendered component is a fragment
    # and is expected to live inside someone else's landmarks.
    if Node.find(nodes, &(&1.tag == "body")) == [] do
      []
    else
      case Node.find(nodes, &main?/1) do
        [] -> [finding()]
        _ -> []
      end
    end
  end

  defp main?(node) do
    node.tag == "main" or Node.attr(node, "role") == "main"
  end

  defp finding do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "document has a <body> but no <main> landmark"
    }
  end
end
