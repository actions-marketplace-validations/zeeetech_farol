defmodule Mix.Tasks.Farol do
  @moduledoc """
  Statically audits HEEx templates for accessibility issues.

      mix farol                          # audit lib/**/*.heex
      mix farol lib/my_app_web/live      # audit a specific path
      mix farol --format sarif --output farol.sarif
      mix farol --except phx-click-interactive

  Exits with a non-zero status when any error-severity finding or parse
  error is found, so it drops straight into CI. `--format sarif` plus
  `github/codeql-action/upload-sarif` annotates pull requests; the `farol`
  GitHub Action wraps exactly that.

  Requires `phoenix_live_view` (the HEEx parser lives there). It is an
  optional dependency of farol: add it to your project if it is not already
  a dependency.

  ## Options

    * `--format` - `terminal` (default) or `sarif`
    * `--output` - write the report to a file instead of stdout
    * `--except` - comma-separated rule ids to skip
    * `--only` - run just these comma-separated rule ids
  """

  use Mix.Task

  alias Farol.{Adapter, Finding}

  @shortdoc "Statically audits HEEx templates for accessibility issues"

  @switches [format: :string, output: :string, except: :string, only: :string]

  @impl true
  def run(argv) do
    ensure_live_view!()

    {opts, paths, _} = OptionParser.parse(argv, strict: @switches)
    files = Enum.flat_map(paths, &Path.wildcard/1) ++ default_paths(paths)

    if files == [] do
      Mix.raise(
        "no .heex templates found (looked in #{Enum.join(paths, ", ") || "lib/**/*.heex"})"
      )
    end

    check_opts = rule_opts(opts)
    {findings, parse_errors} = audit(files, check_opts)

    report(findings, parse_errors, opts)

    if parse_errors != [] or Enum.any?(findings, &(&1.severity == :error)) do
      Mix.raise("farol: accessibility audit failed")
    end
  end

  defp default_paths([]), do: Path.wildcard("lib/**/*.heex")
  defp default_paths(_given), do: []

  defp rule_opts(opts) do
    for {key, flag} <- [except: "--except", only: "--only"],
        value = opts[key] do
      ids = value |> String.split(",") |> Enum.map(&String.trim/1)

      if key == :except and opts[:only] do
        Mix.raise("#{flag} cannot be combined with --only")
      end

      {key, ids}
    end
  end

  defp audit(files, check_opts) do
    Enum.flat_map_reduce(files, [], fn file, parse_errors ->
      with {:ok, source} <- File.read(file),
           {:ok, nodes} <- Adapter.HEEx.parse(source, file: file) do
        findings =
          nodes
          |> Farol.run(check_opts)
          |> Enum.map(fn %Finding{} = finding ->
            %Finding{finding | file: finding.file || file}
          end)

        {findings, parse_errors}
      else
        {:error, {line, column, message}} ->
          parse_error(file, line, column, message, parse_errors)

        {:error, reason} ->
          parse_error(
            file,
            1,
            1,
            "could not read template: #{:file.format_error(reason)}",
            parse_errors
          )
      end
    end)
  end

  defp parse_error(file, line, column, message, parse_errors) do
    Mix.shell().error("#{file}:#{line}:#{column}: #{message}")
    {[], [{file, line, column, message} | parse_errors]}
  end

  defp report(findings, parse_errors, opts) do
    output =
      case Keyword.get(opts, :format, "terminal") do
        "terminal" -> Farol.Report.format(findings)
        "sarif" -> Farol.Report.SARIF.format(findings)
        other -> Mix.raise("unknown --format #{inspect(other)} (expected terminal or sarif)")
      end

    case Keyword.get(opts, :output) do
      nil ->
        Mix.shell().info(output)

      path ->
        File.write!(path, output)
        Mix.shell().info("farol: wrote #{path}")
    end

    if parse_errors != [] do
      Mix.shell().error("farol: #{length(parse_errors)} template(s) failed to parse")
    end
  end

  defp ensure_live_view! do
    unless Code.ensure_loaded?(Adapter.HEEx) do
      Mix.raise("""
      the HEEx engine requires phoenix_live_view (it provides the template parser).
      Add it to your deps:

          {:phoenix_live_view, "~> 1.0"}
      """)
    end
  end
end
