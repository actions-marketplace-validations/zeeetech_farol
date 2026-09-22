defmodule Farol.Adapter do
  @moduledoc """
  Turns a source format into a forest of `Farol.Node`.

  Two engines, one rule catalog: the runtime engine parses rendered HTML
  (`Farol.Adapter.HTML`), the static engine walks the HEEx parser output
  (`Farol.Adapter.HEEx`). Both normalize into the same node struct, so
  rules are written once and never know which engine fed them.

  `parse/2` returns an error tuple for malformed sources: HTML from a
  running app is always parseable, but a broken template is a real
  possibility for the static engine, and it should surface as a report
  entry, not a crash.
  """

  @callback parse(source :: binary, opts :: keyword) ::
              {:ok, [Farol.Node.t()]} | {:error, term()}
end
