defmodule ArmAudio do
  @moduledoc """
  Nx-tensor audio I/O + model wrappers on ARM CPUs.

  * `ArmAudio.SileroVAD` — voice activity detection via tract-onnx
  * `ArmAudio.Piper` — text-to-speech via tract-onnx
  * `ArmAudio.Decoder` — file decode + resample (symphonia + rubato),
    returning Nx tensors
  """
end
