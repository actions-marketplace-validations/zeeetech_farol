defmodule Farol.Rules.ContrastToken do
  @moduledoc """
  Inline colors, resolved through a declared token map, checked against
  WCAG AA contrast ratios.

  Opt-in: the rule only runs when tokens are declared, since without a
  token map it cannot know what a color name means. Declare them once and
  your design system becomes the test fixture:

      config :farol, :tokens, %{
        "bg" => "#000A0F",
        "fg" => "#F7F7FF",
        "accent" => "#9655FF"
      }
  """

  @behaviour Farol.Rule

  alias Farol.{Contrast, Finding, Node}

  @impl true
  def id, do: "contrast-token"

  @impl true
  def wcag, do: "1.4.3"

  @impl true
  def level, do: "aa"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "low contrast text is invisible to people with low vision, and to " <>
      "everyone reading on a phone in sunlight. It is the single most " <>
      "common accessibility failure on the web (86% of home pages, per " <>
      "WebAIM's Million), and the easiest to catch mechanically."
  end

  @impl true
  def fix do
    "adjust one of the pair until the ratio clears 4.5:1 for text (3:1 " <>
      "for large text). Usually the background should win: it anchors the " <>
      "brand; the text exists to be read."
  end

  @impl true
  def check(nodes) do
    tokens = Application.get_env(:farol, :tokens, %{})

    if map_size(tokens) == 0 do
      []
    else
      nodes
      |> Node.find(&Node.has_attr?(&1, "style"))
      |> Enum.flat_map(&check_node(&1, tokens))
    end
  end

  defp check_node(node, tokens) do
    style = parse_style(Node.attr(node, "style"))

    with {:ok, fg} <- resolve(style["color"], tokens),
         {:ok, bg} <- resolve(style["background-color"] || style["background"], tokens),
         {:error, {:below_aa, ratio, threshold}} <-
           Contrast.aa?(fg, bg, large: large_text?(style)) do
      [finding(node, fg, bg, ratio, threshold)]
    else
      _ -> []
    end
  end

  # A style declaration is "key: value; key: value". Last write wins.
  defp parse_style(style) do
    for declaration <- String.split(style, ";", trim: true),
        [key, value] <- [String.split(declaration, ":", parts: 2)] do
      {String.trim(key), String.trim(value)}
    end
    |> Map.new()
  end

  # Values can be a hex literal, a declared token name, or var(--token)
  # pointing at a declared token. Anything else (rgb(), keywords) is out of
  # scope for 0.1 and silently skipped.
  defp resolve(nil, _tokens), do: :error

  defp resolve("#" <> _ = hex, _tokens) do
    case Contrast.parse_hex(hex) do
      {:ok, _} -> {:ok, hex}
      :error -> :error
      {:error, _} -> :error
    end
  end

  defp resolve("var(--" <> rest, tokens) do
    name = String.trim_trailing(rest, ")")
    fetch_token(tokens, name)
  end

  defp resolve(name, tokens), do: fetch_token(tokens, name)

  defp fetch_token(tokens, name) do
    case Map.fetch(tokens, name) do
      {:ok, "#" <> _ = hex} -> {:ok, hex}
      _ -> :error
    end
  end

  # WCAG large text: at least 24px, or 18.66px bold.
  defp large_text?(style) do
    size = px(style["font-size"])
    bold? = style["font-weight"] in ~w(bold 700 800 900)

    (size != nil and size >= 24) or (size != nil and size >= 18.66 and bold?)
  end

  defp px(nil), do: nil

  defp px(value) do
    case Float.parse(String.trim_trailing(value, "px")) do
      {number, _} -> number
      :error -> nil
    end
  end

  defp finding(node, fg, bg, ratio, threshold) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message:
        "#{Node.snippet(node)}: #{fg} on #{bg} has contrast #{ratio}:1, " <>
          "below the required #{threshold}:1",
      snippet: Node.snippet(node)
    }
  end
end
