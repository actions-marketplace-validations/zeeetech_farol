defmodule Farol.Rule do
  @moduledoc """
  The contract every accessibility rule implements.

  This behaviour is the whole extension point of farol. A rule is a plain
  module: it names itself, points at the WCAG criterion it enforces, and
  receives the parsed document as a list of `Farol.Node` trees (a forest).
  It returns findings; it never raises and never performs IO.

  `why/0` and `fix/0` are as important as the check itself. Farol's promise
  is that every finding teaches: `why` explains the human impact in plain
  words (who is affected and how), and `fix` shows the way out. Write them
  for the developer reading a failing test at 5pm, not for a compliance
  auditor.
  """

  alias Farol.{Finding, Node}

  @doc "Unique, stable, kebab-case identifier, like `\"img-alt\"`. Greppable on purpose."
  @callback id() :: String.t()

  @doc "The WCAG 2.2 success criterion number, like `\"1.1.1\"`."
  @callback wcag() :: String.t()

  @doc "The WCAG conformance level of the criterion: `\"a\"`, `\"aa\"` or `\"aaa\"`."
  @callback level() :: String.t()

  @doc "`:error` breaks `assert_accessible/2` by default; `:warning` only informs."
  @callback severity() :: :error | :warning

  @doc "Human-first explanation of the impact. Shown verbatim in every report."
  @callback why() :: String.t()

  @doc "Generic way out of the violation. Shown verbatim in every report."
  @callback fix() :: String.t()

  @doc "Runs the rule against the parsed document forest."
  @callback check(nodes :: [Node.t()]) :: [Finding.t()]
end
