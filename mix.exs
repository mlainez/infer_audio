defmodule ArmAudio.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :arm_audio,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ArmAudio",
      description:
        "Nx-tensor audio I/O + model wrappers on ARM CPUs (Silero VAD / Piper TTS via tract-onnx, symphonia decode, rubato resample)",
      package: package(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:rustler, "~> 0.36", optional: true},
      {:rustler_precompiled, "~> 0.8"},
      {:nx, "~> 0.9"},
      {:arm_ai, path: "../arm_ai"},
      {:nx_arm, path: "../nx_arm"},
      {:arm_nx_primitives, path: "../arm_nx_primitives"},
      # SileroVAD + Piper drive their ONNX through ArmVision.Onnx.
      {:arm_vision, path: "../arm_vision"}
    ]
  end

  defp package do
    [
      name: :arm_audio,
      licenses: ["Apache-2.0"],
      files: ~w(lib mix.exs README.md),
      links: %{"GitHub" => "https://github.com/marclainez/arm_audio"}
    ]
  end
end
