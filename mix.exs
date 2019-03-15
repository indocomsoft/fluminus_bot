defmodule FluminusBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :fluminus_bot,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/indocomsoft/fluminus_bot",
      docs: [
        main: "readme",
        extras: ["REAMDE.md"]
      ],
      package: package(),
      description: description(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_gram, "~> 0.5.0"},
      {:fluminus, "~> 0.2.3"},
      # TODO: Remove when ex_gram merges hackney version relaxation
      {:hackney, "~> 1.13", override: true},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "A Telegram Bot that does push notification for LumiNUS announcements (https://luminus.nus.edu.sg)"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/indocomsoft/fluminus_bot"}
    ]
  end
end
