defmodule Farol.Rules.ValidRole do
  @moduledoc "role values must come from the ARIA specification."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  # The ARIA 1.2 role vocabulary, minus abstract roles (never used directly).
  # "directory" is deprecated but still parses; better to keep it valid here
  # and let a deprecation rule care about it.
  @valid_roles ~w(
    alert alertdialog application article banner blockquote button caption cell
    checkbox code columnheader combobox complementary contentinfo definition
    deletion dialog directory document emphasis feed figure form generic grid
    gridcell group heading img insertion link list listbox listitem log main
    marquee math menu menubar menuitem menuitemcheckbox menuitemradio meter
    navigation none note option paragraph presentation progressbar radio
    radiogroup region row rowgroup rowheader scrollbar search searchbox
    separator slider spinbutton status strong subscript superscript switch tab
    table tablist tabpanel term textbox time timer toolbar tooltip tree
    treegrid treeitem
  )

  @impl true
  def id, do: "valid-role"

  @impl true
  def wcag, do: "4.1.2"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "assistive technologies map roles to platform accessibility APIs. An " <>
      "unknown role is not a graceful degradation: the element falls back " <>
      "to no role at all, so your \"button\" becomes a plain div that " <>
      "announces nothing."
  end

  @impl true
  def fix do
    "check the spelling against the ARIA role list. If you invented the " <>
      "role, the native element probably already exists: <button>, <nav>, " <>
      "<dialog> and friends ship their roles for free."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&Node.has_attr?(&1, "role"))
    # A dynamic role (role={@role}) is unknowable statically; skip rather
    # than flag the expression source as an unknown role.
    |> Enum.reject(&Node.dynamic?(&1, "role"))
    |> Enum.flat_map(fn node ->
      node
      |> Node.attr("role")
      |> String.split(~r/\s+/, trim: true)
      |> Enum.reject(&(&1 in @valid_roles))
      |> Enum.map(&finding(node, &1))
    end)
  end

  defp finding(node, role) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "#{Node.snippet(node)} has unknown role \"#{role}\"",
      snippet: Node.snippet(node),
      line: node.line
    }
  end
end
