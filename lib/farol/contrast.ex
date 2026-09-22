defmodule Farol.Contrast do
  @moduledoc """
  WCAG 2.2 contrast math over hex colors.

  The formula is the one from the spec: convert each sRGB channel to linear
  light, weigh them into relative luminance (0.2126 R + 0.7152 G + 0.0722 B),
  then ratio = (L1 + 0.05) / (L2 + 0.05), lighter over darker. The result
  lands between 1:1 (same color) and 21:1 (black on white).

  Level AA asks for 4.5:1 for normal text and 3:1 for large text and UI
  components. Level AAA raises those to 7:1 and 4.5:1.
  """

  @aa_text 4.5
  @aa_large 3.0

  @doc """
  The contrast ratio between two hex colors, rounded to two decimals.
  Accepts `#rgb` and `#rrggbb`, case insensitive.
  """
  @spec ratio(String.t(), String.t()) :: {:ok, float()} | {:error, :invalid_color}
  def ratio(fg, bg) do
    with {:ok, fg_rgb} <- parse_hex(fg),
         {:ok, bg_rgb} <- parse_hex(bg) do
      l1 = luminance(fg_rgb)
      l2 = luminance(bg_rgb)
      {lighter, darker} = if l1 >= l2, do: {l1, l2}, else: {l2, l1}
      {:ok, Float.round((lighter + 0.05) / (darker + 0.05), 2)}
    end
  end

  @doc """
  Checks a foreground/background pair against level AA.

  `large: true` relaxes the threshold to 3:1, for text at least 24px, or
  18.66px bold (the WCAG definition of large scale).
  """
  @spec aa?(String.t(), String.t(), keyword()) :: {:ok, float()} | {:error, term()}
  def aa?(fg, bg, opts \\ []) do
    threshold = if Keyword.get(opts, :large, false), do: @aa_large, else: @aa_text

    with {:ok, ratio} <- ratio(fg, bg) do
      if ratio >= threshold do
        {:ok, ratio}
      else
        {:error, {:below_aa, ratio, threshold}}
      end
    end
  end

  @doc "Parses `#rgb` or `#rrggbb` into an `{r, g, b}` tuple of 0..255."
  def parse_hex("#" <> hex) do
    case String.length(hex) do
      3 -> parse_channels(for(<<c <- hex>>, do: <<c, c>>))
      6 -> parse_channels(for(<<r::binary-size(2) <- hex>>, do: r))
      _ -> {:error, :invalid_color}
    end
  end

  def parse_hex(_other), do: {:error, :invalid_color}

  defp parse_channels([_, _, _] = channels) do
    Enum.reduce_while(channels, {:ok, []}, fn channel, {:ok, acc} ->
      case Integer.parse(channel, 16) do
        {value, ""} -> {:cont, {:ok, [value | acc]}}
        _ -> {:halt, {:error, :invalid_color}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, values |> Enum.reverse() |> List.to_tuple()}
      error -> error
    end
  end

  defp parse_channels(_), do: {:error, :invalid_color}

  # Relative luminance per WCAG 2.2: linearize each sRGB channel, then weigh.
  defp luminance({r, g, b}) do
    0.2126 * linearize(r / 255) + 0.7152 * linearize(g / 255) + 0.0722 * linearize(b / 255)
  end

  defp linearize(channel) when channel <= 0.04045, do: channel / 12.92
  defp linearize(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)
end
