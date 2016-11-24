defmodule ExStatsD.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_statsd,
     version: "0.6.0",
     elixir: "~> 1.3",
     package: package,
     deps: deps,

     # Documentation
     name: "ex_statsd",
     source_url: "https://github.com/CargoSense/ex_statsd",
     docs: [readme: true, main: "overview"]]
  end

  defp package do
    [description: "A StatsD client for Elixir",
     maintainers: ["Bruce Williams", "Leszek Zalewski"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/driv3r/ex_statsd"}]
  end

  def application do
    application(Mix.env)
  end

  def application(:test) do
    [applications: []]
  end

  def application(_) do
    [applications: [:config_ext],
     mod: {ExStatsD.Application, []}]
  end

  defp deps do
    [
      {:config_ext, "~> 0.3"},
      {:ex_doc, "~> 0.10", only: :dev},
      {:earmark, "~> 0.1", only: :dev}
    ]
  end
end
