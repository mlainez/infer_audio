defmodule InferAudio.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :infer_audio,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "InferAudio",
      description:
        "Generic Nx-tensor audio I/O (decode, resample, WAV) with a pluggable native backend (see `InferAudio.Backend`).",
      package: package(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp elixirc_paths(:test), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nx, "~> 0.12.0"},
      # The ARM backend, for tests.
      {:arm_ai, github: "mlainez/arm_ai", only: [:dev, :test]},
      {:nx_arm, github: "mlainez/nx_arm", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      name: :infer_audio,
      licenses: ["Apache-2.0"],
      files: ~w(lib mix.exs README.md LICENSE),
      links: %{"GitHub" => "https://github.com/mlainez/infer_audio"}
    ]
  end
end
