defmodule Farol.Rules.HtmlLang do
  @moduledoc "The <html> element must declare the page language."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "html-lang"

  @impl true
  def wcag, do: "3.1.1"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "screen readers pick their pronunciation from the declared language. " <>
      "Without lang, a Portuguese page can be read aloud with English " <>
      "phonetics: every word technically spoken, none of it " <>
      "understandable. Translation tools and hyphenation engines rely on " <>
      "the same attribute."
  end

  @impl true
  def fix do
    "add lang to the html tag: <html lang=\"pt-BR\"> or lang=\"en\". " <>
      "Phoenix apps set it in the root layout."
  end

  @impl true
  def check(nodes) do
    case Node.find(nodes, &(&1.tag == "html")) do
      [] -> []
      htmls -> htmls |> Enum.reject(&Node.has_attr?(&1, "lang")) |> Enum.map(&finding/1)
    end
  end

  defp finding(node) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "<html> has no lang attribute",
      snippet: Node.snippet(node)
    }
  end
end
