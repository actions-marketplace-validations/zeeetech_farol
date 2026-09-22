defmodule Farol.Rules.DocumentTitle do
  @moduledoc "Documents need a non-empty <title>."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "document-title"

  @impl true
  def wcag, do: "2.4.2"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :warning

  @impl true
  def why do
    "the title is the first thing a screen reader announces when the page " <>
      "loads, and the only label a browser tab has. Someone with ten tabs " <>
      "open navigates by titles; \"MyApp\" on every page forces them to " <>
      "open each one to know where they are."
  end

  @impl true
  def fix do
    "render a descriptive <title> per page. In LiveView, @page_title plus " <>
      "<.live_title> keeps it in sync across patches."
  end

  @impl true
  def check(nodes) do
    # Fragments have no head, so this only fires on full documents.
    case Node.find(nodes, &(&1.tag == "head")) do
      [] ->
        []

      _head ->
        case Node.find(nodes, &(&1.tag == "title")) do
          [] ->
            [finding("document has a <head> but no <title>")]

          titles ->
            if Enum.all?(titles, &(Node.text(&1) |> String.trim() == "")) do
              [finding("<title> is empty")]
            else
              []
            end
        end
    end
  end

  defp finding(message) do
    %Finding{rule: id(), wcag: wcag(), level: level(), severity: severity(), message: message}
  end
end
