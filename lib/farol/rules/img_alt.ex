defmodule Farol.Rules.ImgAlt do
  @moduledoc "Images need alternative text, or an explicit marker that they are decorative."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "img-alt"

  @impl true
  def wcag, do: "1.1.1"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "screen readers announce the filename (\"i m g underscore avatar dot " <>
      "jay peg\") or silence. 2.2 billion people live with some form of " <>
      "vision impairment; alt text is how the image reaches them."
  end

  @impl true
  def fix do
    "add alt=\"...\" describing what the image conveys - or alt=\"\" (empty) " <>
      "when the image is purely decorative, so screen readers skip it."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&(&1.tag == "img"))
    |> Enum.reject(&labeled?/1)
    |> Enum.map(&finding/1)
  end

  # alt="" is valid: it tells the screen reader the image is decorative.
  # role="presentation"/"none" opts out the same way.
  defp labeled?(node) do
    Node.has_attr?(node, "alt") or Node.attr(node, "role") in ["presentation", "none"]
  end

  defp finding(node) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "#{Node.snippet(node)} has no alt text",
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
