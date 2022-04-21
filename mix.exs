defmodule Hello.MixProject do
  use Mix.Project

  def project do
    [
      app: :hello,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        hello: [
          cookie: "39bPwSZPBA9sWwWAMMBeMaEuwFNA0N7Eq7L4aCp7jjDVuJoOcCB9PQ==",
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mnesia],
      included_applications: [:mnesia],
      mod: {Hello.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3"},
      {:libcluster, "~> 3.3"},
      {:plug_cowboy, "~> 2.0"},
      {:timex, "~> 3.0"}
    ]
  end
end
