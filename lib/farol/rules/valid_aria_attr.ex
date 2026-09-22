defmodule Farol.Rules.ValidAriaAttr do
  @moduledoc "aria-* attributes must exist in the ARIA specification (typo catcher)."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  # The ARIA 1.2 attribute vocabulary. The classic trap this catches:
  # aria-lable, aria-labeledby, aria-describeby.
  @valid_attrs ~w(
    aria-activedescendant aria-atomic aria-autocomplete aria-braillelabel
    aria-brailleroledescription aria-busy aria-checked aria-colcount
    aria-colindex aria-colindextext aria-colspan aria-controls aria-current
    aria-describedby aria-description aria-details aria-disabled
    aria-dropeffect aria-errormessage aria-expanded aria-flowto aria-grabbed
    aria-haspopup aria-hidden aria-invalid aria-keyshortcuts aria-label
    aria-labelledby aria-level aria-live aria-modal aria-multiline
    aria-multiselectable aria-orientation aria-owns aria-placeholder
    aria-posinset aria-pressed aria-readonly aria-relevant aria-required
    aria-roledescription aria-rowcount aria-rowindex aria-rowindextext
    aria-rowspan aria-selected aria-setsize aria-sort aria-valuemax
    aria-valuemin aria-valuenow aria-valuetext
  )

  @impl true
  def id, do: "valid-aria-attr"

  @impl true
  def wcag, do: "4.1.2"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "a misspelled aria attribute fails silently: the browser ignores it, no " <>
      "console warning, no error. You believe the element is labeled; the " <>
      "screen reader user knows it is not. This class of bug survives code " <>
      "review because it looks right."
  end

  @impl true
  def fix do
    "check the spelling against the ARIA attribute list. The usual " <>
      "suspects: aria-label (not aria-lable), aria-labelledby (with \"label\" " <>
      "in full), aria-describedby."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(fn node -> Node.attrs_with_prefix(node, "aria-") != [] end)
    |> Enum.flat_map(fn node ->
      node
      |> Node.attrs_with_prefix("aria-")
      |> Enum.reject(fn {name, _value} -> name in @valid_attrs end)
      |> Enum.map(fn {name, _value} -> finding(node, name) end)
    end)
  end

  defp finding(node, name) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "#{Node.snippet(node)} has unknown aria attribute \"#{name}\"",
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
