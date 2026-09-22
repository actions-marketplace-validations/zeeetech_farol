defmodule Farol.Finding do
  @moduledoc """
  One accessibility violation, tied to the rule that caught it.

  A finding carries the instance-specific part (`message`, `snippet`): what
  was found, where. The didactic part (`why`, `fix`) lives on the rule
  module, since it is the same for every instance of the same violation.
  `Farol.Report` joins the two when rendering.
  """

  @type t :: %__MODULE__{
          rule: String.t(),
          wcag: String.t(),
          level: String.t(),
          severity: :error | :warning,
          message: String.t(),
          snippet: String.t() | nil
        }

  @enforce_keys [:rule, :wcag, :level, :severity, :message]
  defstruct [:rule, :wcag, :level, :severity, :message, :snippet]
end
