defmodule Farol.Rules.LiveRegionUsage do
  @moduledoc "Flash messages outside an aria-live region are announced to nobody."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @live_roles ~w(alert status log)

  @impl true
  def id, do: "live-region-usage"

  @impl true
  def wcag, do: "4.1.3"

  @impl true
  def level, do: "aa"

  @impl true
  def severity, do: :warning

  @impl true
  def why do
    "a flash message appears without any page load. Sighted users notice " <>
      "the toast; screen reader users get no event at all unless the " <>
      "container is a live region. \"Settings saved\" that nobody hears is " <>
      "the difference between confidence and guessing."
  end

  @impl true
  def fix do
    "put the flash container in an aria-live region: aria-live=\"polite\" " <>
      "for info, role=\"alert\" for errors. Phoenix's core components " <>
      "already do this - keep it when you restyle them."
  end

  @impl true
  def check(nodes) do
    walk(nodes, _inside_live? = false, [])
  end

  # Heuristic: flash containers are the ones carrying "flash" in id or class,
  # matching the convention from Phoenix's generated core_components.
  defp walk(nodes, inside_live?, findings) do
    Enum.reduce(nodes, findings, fn
      %Node{} = node, findings ->
        live_here? = inside_live? or live_region?(node)

        findings =
          if flash?(node) and not live_here? do
            [finding(node) | findings]
          else
            findings
          end

        walk(node.children, live_here?, findings)

      _text, findings ->
        findings
    end)
  end

  defp live_region?(node) do
    Node.has_attr?(node, "aria-live") or Node.attr(node, "role") in @live_roles
  end

  defp flash?(node) do
    ["id", "class"]
    |> Enum.map(&Node.attr(node, &1))
    |> Enum.any?(fn value -> value && String.contains?(String.downcase(value), "flash") end)
  end

  defp finding(node) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message:
        "#{Node.snippet(node)} looks like a flash container but lives outside any aria-live region",
      snippet: Node.snippet(node)
    }
  end
end
