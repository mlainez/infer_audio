defmodule InferAudio do
  @moduledoc """
  Nx-tensor audio I/O + model wrappers on ARM CPUs.

  * `InferAudio.SileroVAD` — voice activity detection via tract-onnx
  * `InferAudio.Piper` — text-to-speech via tract-onnx
  * `InferAudio.Decoder` — file decode + resample (symphonia + rubato),
    returning Nx tensors
  """
end
