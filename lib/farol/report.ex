defmodule Farol.Report do
  @moduledoc """
  Renders findings into the didactic terminal report.

  Every finding gets three layers: what was found (message + WCAG ref), why
  it matters to humans (the rule's `why/0`), and how to fix it (`fix/0`).
  The output is plain ASCII with ANSI colors, so it reads the same in a
  terminal, in CI logs, and pasted into an issue.
  """

  alias Farol.Finding

  @purple 99
  @yellow 229
  @gray 245

  @doc "Formats a list of findings as a printable report string."
  @spec format([Finding.t()], [module()]) :: String.t()
  def format(findings, rules \\ Farol.rules()) do
    by_id = Map.new(rules, &{&1.id(), &1})
    rendered = Enum.map_join(findings, "\n\n", &format_finding(&1, by_id))

    """
    #{summary(findings)}

    #{rendered}
    """
  end

  defp summary(findings) do
    errors = Enum.count(findings, &(&1.severity == :error))
    warnings = length(findings) - errors

    "#{length(findings)} accessibility finding(s): #{errors} error(s), #{warnings} warning(s)"
  end

  defp format_finding(%Finding{} = finding, by_id) do
    rule = Map.get(by_id, finding.rule)
    {marker, color} = marker(finding.severity)

    header =
      "#{marker} [#{finding.rule}] #{finding.message}"

    meta =
      "  wcag #{finding.wcag} (level #{finding.level}) - #{finding.severity}" <>
        location(finding)

    body =
      if rule do
        """

          why: #{indent(rule.why())}

          fix: #{indent(rule.fix())}
        """
      else
        ""
      end

    colorize(color, header) <> "\n" <> colorize(@gray, meta) <> body
  end

  defp marker(:error), do: {"x", @purple}
  defp marker(:warning), do: {"!", @yellow}

  # Static findings know where they came from; runtime ones do not.
  defp location(%Finding{file: nil}), do: ""
  defp location(%Finding{file: file, line: nil}), do: " - #{file}"
  defp location(%Finding{file: file, line: line}), do: " - #{file}:#{line}"

  # Soft-wraps prose at 72 columns with a hanging indent, so the report
  # stays readable in narrow terminals.
  defp indent(text) do
    text
    |> String.split(" ", trim: true)
    |> Enum.reduce([""], fn word, [line | rest] ->
      if line != "" and String.length(line) + String.length(word) + 1 > 72 do
        ["    " <> word, line | rest]
      else
        [if(line == "", do: word, else: line <> " " <> word) | rest]
      end
    end)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp colorize(color, text) do
    IO.ANSI.color(color) <> text <> IO.ANSI.reset()
  end
end
