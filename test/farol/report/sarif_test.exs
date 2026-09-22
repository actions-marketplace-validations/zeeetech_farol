defmodule Farol.Report.SARIFTest do
  use ExUnit.Case, async: true

  alias Farol.{Finding, Report.SARIF}

  defp finding(overrides \\ []) do
    struct!(
      %Finding{
        rule: "img-alt",
        wcag: "1.1.1",
        level: "a",
        severity: :error,
        message: ~s(<img src="a.jpg"> has no alt text)
      },
      overrides
    )
  end

  test "produces valid sarif 2.1.0 with rules and results" do
    doc =
      [finding(file: "lib/app_web/card.ex", line: 12)]
      |> SARIF.format()
      |> JSON.decode!()

    assert doc["version"] == "2.1.0"
    assert doc["$schema"] =~ "sarif"

    [run] = doc["runs"]
    driver = run["tool"]["driver"]
    assert driver["name"] == "farol"
    assert length(driver["rules"]) == length(Farol.rules())

    rule = Enum.find(driver["rules"], &(&1["id"] == "img-alt"))
    assert rule["properties"]["wcag"] == "1.1.1"
    assert rule["shortDescription"]["text"] =~ "screen reader"

    [result] = run["results"]
    assert result["ruleId"] == "img-alt"
    assert result["level"] == "error"

    [location] = result["locations"]
    assert location["physicalLocation"]["artifactLocation"]["uri"] == "lib/app_web/card.ex"
    assert location["physicalLocation"]["region"]["startLine"] == 12
  end

  test "findings without a location degrade to a placeholder" do
    doc = [finding()] |> SARIF.format() |> JSON.decode!()

    [location] = doc["runs"] |> hd() |> get_in(["results"]) |> hd() |> Map.fetch!("locations")
    assert location["physicalLocation"]["artifactLocation"]["uri"] == "unknown"
    assert location["physicalLocation"]["region"]["startLine"] == 1
  end
end
