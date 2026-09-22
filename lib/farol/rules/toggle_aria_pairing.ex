defmodule Farol.Rules.ToggleAriaPairing do
  @moduledoc "JS.toggle/show/hide triggers must announce the state they control."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @js_commands ~r/JS\.(toggle|show|hide)\b/

  @impl true
  def id, do: "toggle-aria-pairing"

  @impl true
  def wcag, do: "4.1.2"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :warning

  @impl true
  def why do
    "JS.toggle flips visibility on the client, but nothing tells assistive " <>
      "tech that anything happened. Sighted users see the panel open; " <>
      "screen reader users activate the button and hear silence. They " <>
      "cannot know whether the menu expanded, the modal opened, or nothing " <>
      "worked at all."
  end

  @impl true
  def fix do
    "pair the trigger with aria-expanded (true/false, kept in sync with the " <>
      "toggled state) and aria-controls pointing at the target id. For " <>
      "modals, role=\"dialog\" plus focus management does the heavier " <>
      "lifting."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&toggles?/1)
    |> Enum.flat_map(fn node ->
      case missing_pairing(node) do
        [] -> []
        missing -> [finding(node, missing)]
      end
    end)
  end

  defp toggles?(node) do
    (Node.attr(node, "phx-click") || "") =~ @js_commands
  end

  defp missing_pairing(node) do
    ["aria-expanded", "aria-controls"]
    |> Enum.reject(&Node.has_attr?(node, &1))
  end

  defp finding(node, missing) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message:
        "#{Node.snippet(node)} toggles content with JS commands but lacks " <>
          "#{Enum.join(missing, " and ")}",
      snippet: Node.snippet(node)
    }
  end
end
