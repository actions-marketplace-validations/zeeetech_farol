defmodule Farol.Report.SARIF do
  @moduledoc """
  Renders findings as SARIF 2.1.0, the format GitHub code scanning (and
  most other CI annotation surfaces) consumes.

  Each built-in rule becomes a SARIF `rule` carrying its WCAG reference in
  `properties`, and each finding becomes a `result` with a file/line
  location when the static engine provided one.
  """

  alias Farol.Finding

  @schema "https://json.schemastore.org/sarif-2.1.0.json"

  @doc "Encodes findings as a SARIF 2.1.0 JSON string."
  @spec format([Finding.t()], [module()]) :: String.t()
  def format(findings, rules \\ Farol.rules()) do
    JSON.encode!(%{
      "$schema" => @schema,
      "version" => "2.1.0",
      "runs" => [
        %{
          "tool" => %{"driver" => driver(rules)},
          "results" => Enum.map(findings, &result/1)
        }
      ]
    })
  end

  defp driver(rules) do
    %{
      "name" => "farol",
      "version" => Application.spec(:farol, :vsn) |> to_string(),
      "informationUri" => "https://github.com/zeetech/farol",
      "rules" => Enum.map(rules, &sarif_rule/1)
    }
  end

  defp sarif_rule(rule) do
    %{
      "id" => rule.id(),
      "shortDescription" => %{"text" => rule.why()},
      "help" => %{"text" => rule.fix()},
      "properties" => %{"wcag" => rule.wcag(), "level" => rule.level()}
    }
  end

  defp result(%Finding{} = finding) do
    %{
      "ruleId" => finding.rule,
      "level" => to_string(finding.severity),
      "message" => %{"text" => finding.message},
      "locations" => [location(finding)]
    }
  end

  defp location(%Finding{} = finding) do
    %{
      "physicalLocation" => %{
        "artifactLocation" => %{"uri" => finding.file || "unknown"},
        "region" => %{"startLine" => finding.line || 1}
      }
    }
  end
end
