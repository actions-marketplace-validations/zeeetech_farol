defmodule Farol.Assertions do
  @moduledoc """
  ExUnit integration: `assert_accessible/2` for rendered HTML.

  The flow fits the test suite you already have. Render with the usual
  LiveView test helpers, assert on the result:

      import Farol.Assertions

      test "user card is accessible" do
        html = render_component(&user_card/1, user: user)
        assert_accessible html
      end

  On failure, the test fails with the full didactic report: every finding
  with its WCAG reference, why it matters, and how to fix it.

  Escape hatches are explicit on purpose, so exceptions stay greppable:

      assert_accessible html, except: ["landmark-regions"]
      assert_accessible html, only: [:img_alt, :label_association]
  """

  @doc """
  Asserts that rendered HTML passes the accessibility rule catalog.

  Accepts the same options as `Farol.check/2`. Fails when any finding is
  reported; use `except:` for rules you have consciously waived.
  """
  defmacro assert_accessible(html, opts \\ []) do
    quote do
      import ExUnit.Assertions

      case Farol.check(unquote(html), unquote(opts)) do
        [] ->
          :ok

        findings ->
          flunk("""
          expected the markup to be accessible, found #{length(findings)} issue(s)

          #{Farol.Report.format(findings)}
          """)
      end
    end
  end
end
