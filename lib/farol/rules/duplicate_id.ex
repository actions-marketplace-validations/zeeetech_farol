defmodule Farol.Rules.DuplicateId do
  @moduledoc "Ids must be unique per document."

  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  @impl true
  def id, do: "duplicate-id"

  @impl true
  def wcag, do: "4.1.1"

  @impl true
  def level, do: "a"

  @impl true
  def severity, do: :error

  @impl true
  def why do
    "label[for], aria-describedby, aria-controls and anchor links all " <>
      "resolve by id, and they all stop at the first match. A duplicated id " <>
      "silently points assistive tech at the wrong element: the label " <>
      "describes one field while the user edits another."
  end

  @impl true
  def fix do
    "rename one of them. If the duplication comes from rendering a " <>
      "component in a loop, derive the id from the item: id={\"user-\#{user.id}\"}."
  end

  @impl true
  def check(nodes) do
    nodes
    |> Node.find(&Node.has_attr?(&1, "id"))
    |> Enum.group_by(&Node.attr(&1, "id"))
    |> Enum.filter(fn {_id, occurrences} -> length(occurrences) > 1 end)
    |> Enum.sort_by(fn {id, _occurrences} -> id end)
    |> Enum.map(fn {id, occurrences} -> finding(id, occurrences) end)
  end

  defp finding(id, occurrences) do
    %Finding{
      rule: id(),
      wcag: wcag(),
      level: level(),
      severity: severity(),
      message: "id \"#{id}\" appears #{length(occurrences)} times in the document",
      snippet: Node.snippet(hd(occurrences)),
      line: hd(occurrences).line
    }
  end
end
