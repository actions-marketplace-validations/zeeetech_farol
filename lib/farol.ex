defmodule Farol do
  @moduledoc """
  Farol is accessibility testing for Phoenix LiveView, in pure Elixir.

  The public surface is deliberately small: `check/2` runs the rule catalog
  against rendered HTML and returns findings, `rules/0` lists the catalog.
  `Farol.Assertions` turns that into `assert_accessible/2` for ExUnit, and
  `Farol.Report` renders findings into the didactic output you see when a
  test fails.

      html = render_component(&user_card/1, user: user)
      assert_accessible html

  Every rule is a plain module implementing the `Farol.Rule` behaviour, so
  the catalog is also the extension point: build your own rule, add it to
  the `:only` list, and it runs alongside the built-ins.
  """

  alias Farol.{Adapter, Finding}

  @rules [
    Farol.Rules.ImgAlt,
    Farol.Rules.LabelAssociation,
    Farol.Rules.LandmarkRegions,
    Farol.Rules.HeadingOrder,
    Farol.Rules.DuplicateId,
    Farol.Rules.ValidRole,
    Farol.Rules.ValidAriaAttr,
    Farol.Rules.NoAriaOnHidden,
    Farol.Rules.PhxClickInteractive,
    Farol.Rules.ToggleAriaPairing,
    Farol.Rules.FocusAfterPatch,
    Farol.Rules.LiveRegionUsage,
    Farol.Rules.HtmlLang,
    Farol.Rules.DocumentTitle,
    Farol.Rules.ButtonName,
    Farol.Rules.LinkName,
    Farol.Rules.IframeTitle,
    Farol.Rules.ContrastToken
  ]

  @doc "The built-in rule catalog: one module per rule, all `Farol.Rule` implementations."
  @spec rules() :: [module()]
  def rules, do: @rules

  @doc """
  Runs rules against a source document and returns a list of `Farol.Finding`.

  An empty list means the markup passed. Findings come back in document
  order per rule, grouped by rule, errors and warnings interleaved; the
  report layer handles presentation.

  Raises `ArgumentError` when the source cannot be parsed. Callers handling
  untrusted or broken templates (like `mix farol`) should call the adapter
  directly and feed the nodes to `run/2` instead.

  ## Options

    * `:adapter` - module implementing `Farol.Adapter`, defaults to
      `Farol.Adapter.HTML`. Use `Farol.Adapter.HEEx` for template source.
    * `:except` - rule ids to skip, as strings or atoms. Explicit and
      greppable on purpose, so exceptions survive code review.
    * `:only` - run just these rule ids. Useful for testing a custom rule
      or focusing a test on one concern.
  """
  @spec check(binary, keyword) :: [Finding.t()]
  def check(source, opts \\ []) when is_binary(source) do
    adapter = Keyword.get(opts, :adapter, Adapter.HTML)

    case adapter.parse(source, opts) do
      {:ok, nodes} ->
        run(nodes, opts)

      {:error, reason} ->
        raise ArgumentError, "farol could not parse the source: #{inspect(reason)}"
    end
  end

  @doc """
  Runs the selected rules against an already-parsed node forest.

  This is the second half of `check/2`, exposed so callers that parse on
  their own (the static engine in `mix farol`) can handle parse errors
  gracefully and still get the same rule selection semantics.
  """
  @spec run([Farol.Node.t()], keyword) :: [Finding.t()]
  def run(nodes, opts \\ []) when is_list(nodes) do
    opts
    |> select_rules()
    |> Enum.flat_map(& &1.check(nodes))
  end

  defp select_rules(opts) do
    only = opts |> Keyword.get(:only) |> normalize_ids()
    except = opts |> Keyword.get(:except) |> normalize_ids()

    Enum.filter(@rules, fn rule ->
      id = rule.id()
      (is_nil(only) or id in only) and (is_nil(except) or id not in except)
    end)
  end

  # Atoms like :img_alt are accepted as a convenience; hyphens are not
  # valid in bare atoms, so underscores map back to them.
  defp normalize_ids(nil), do: nil

  defp normalize_ids(ids) do
    MapSet.new(Enum.map(ids, &(&1 |> to_string() |> String.replace("_", "-"))))
  end
end
