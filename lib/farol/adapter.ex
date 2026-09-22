defmodule Farol.Adapter do
  @moduledoc """
  Turns a source format into a forest of `Farol.Node`.

  Two engines, one rule catalog: the runtime engine parses rendered HTML
  (`Farol.Adapter.HTML`), the static engine (planned for 0.2) will walk the
  HEEx tokenizer output. Both normalize into the same node struct, so rules
  are written once and never know which engine fed them.
  """

  @callback parse(source :: binary) :: [Farol.Node.t()]
end
