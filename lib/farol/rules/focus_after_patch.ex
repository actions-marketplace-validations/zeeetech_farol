defmodule Farol.Rules.FocusAfterPatch do
  @moduledoc """
  Containers patched by LiveView can swallow the user's focus.
  """

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "focus-after-patch"

  @impl true
  def wcag, do: "2.4.3"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :warning

  @impl true
  def why do
    "when LiveView patches a container, the DOM nodes inside it are " <>
      "replaced. If one of them had focus, focus falls back to <body>: the " <>
      "keyboard user is teleported to the top of the page mid-task. On " <>
      "chat-like or form-heavy screens this makes the app unusable without " <>
      "a mouse."
  end

  @impl true
  def fix do
    "restore focus after the patch: a phx-hook that re-focuses the active " <>
      "element, or autofocus on the node that should own it. Sometimes the " <>
      "right fix is narrowing the phx-update container so focused elements " <>
      "sit outside it."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&patchable_container?/1)
    |> Enum.reject(&Node.has_attr?(&1, "phx-hook"))
    |> Enum.filter(fn container -> Node.find([container], &focusable?/1) != [] end)
    |> Enum.reject(fn container ->
      Node.find([container], &Node.has_attr?(&1, "autofocus")) != []
    end)
    |> Enum.map(&finding/1)
  end

  defp patchable_container?(node) do
    Node.attr(node, "phx-update") in ["replace", "stream"]
  end

  defp focusable?(%Node{tag: "a"} = node), do: Node.has_attr?(node, "href")

  defp focusable?(%Node{tag: tag} = node) do
    tag in ~w(button input select textarea) or Node.has_attr?(node, "tabindex")
  end

  defp finding(node) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message:
        "#{Node.snippet(node)} patches a subtree containing focusable " <>
          "elements, with no phx-hook or autofocus to restore focus",
      snippet: Node.snippet(node)
    }
  end
end
