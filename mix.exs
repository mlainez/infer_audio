defmodule InferAudio.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :infer_audio,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Audio",
      description:
        "Generic Nx-tensor audio I/O + model wrappers (Silero VAD / Piper TTS) with a pluggable native backend (see `InferAudio.Backend`).",
      package: package(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nx, "~> 0.9"},
      {:nx_primitives, github: "mlainez/nx_primitives"},
      # No dep on infer_vision — the backend handles VAD/Piper
      # scoring internally so a Hailo / DSP / non-ONNX impl can
      # plug in without dragging the vision stack along.
      {:arm_ai, github: "mlainez/arm_ai", only: [:dev, :test]},
      {:nx_arm, github: "mlainez/nx_arm", only: [:dev, :test]},
      {:rustler, "~> 0.36", optional: true},
      {:rustler_precompiled, "~> 0.8"}
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
