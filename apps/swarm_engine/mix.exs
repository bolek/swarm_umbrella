defmodule SwarmEngine.Mixfile do
  use Mix.Project

  def project do
    [
      app: :swarm_engine,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :calendar,
        :goth,
        :hackney,
        :logger,
        :timex
      ],
      mod: {SwarmEngine.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:calendar, "~> 0.17.2"},
      {:csv, "~> 2.0.0"},
      {:ecto, "~> 2.2"},
      {:goth, "~> 0.4.0"},
      {:hackney, "~> 1.9"},
      {:postgrex, ">= 0.0.0"},
      {:timex, "~> 3.1"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
