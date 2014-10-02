defmodule ExStatsD.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_statsd,
     version: "0.1.0",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    application(Mix.env)
  end
  def application(:test) do
    [applications: []]
  end
  def application(_) do
    [applications: [],
     mod: {ExStatsD.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:ex_doc, "~> 0.5", only: :dev}]
  end

end