defmodule Farol.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/zeetech/farol"

  def project do
    [
      app: :farol,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Farol",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:lazy_html, "~> 0.1"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Accessibility testing for Phoenix LiveView. Pure Elixir, zero node, " <>
      "with rules that understand phx-click and friends."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "Farol",
      extras: ["README.md"]
    ]
  end
end
