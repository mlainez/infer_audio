defmodule InferAudio.Piper do
  @moduledoc """
  Text-to-speech — generic API delegating to a configured
  `InferAudio.Backend`.

  Piper distributes voices as `<voice>.onnx` + `<voice>.onnx.json`
  config. The graph takes phoneme IDs and emits f32 audio samples
  at the model's sample rate (typically 22050 Hz).

      {:ok, piper} = InferAudio.Piper.load("/root/en_US-amy-medium.onnx")
      # phoneme_ids: list of integers (user / their phonemiser
      # produces these; eSpeak NG is the canonical source).
      samples = InferAudio.Piper.synthesize(piper, phoneme_ids)
      InferAudio.Decoder.write_wav("/data/out.wav", samples,
                                   sample_rate: piper.sample_rate)

  Phonemisation is **not** done here — eSpeak NG is a C library and
  on-device phonemisation is rare. For most Nerves use cases the
  phonemes are computed on the host or via a service, then sent
  to the device.
  """

  defstruct [:handle, :backend, :sample_rate]

  @doc """
  Load a Piper voice. `:sample_rate` defaults to 22050 (Piper's
  default for medium-quality voices; some voices use 16000 — pass
  the value from the voice's `.onnx.json` config).

  ## Options

    * `:sample_rate` — voice output rate (default 22050)
    * `:backend` — override the configured `InferAudio.Backend`
  """
  @spec load(Path.t(), keyword()) :: {:ok, %__MODULE__{}} | {:error, term()}
  def load(path, opts \\ []) do
    backend = InferAudio.Backend.resolve(opts)
    sample_rate = Keyword.get(opts, :sample_rate, 22_050)

    case backend.piper_load(path, opts) do
      {:ok, handle} ->
        {:ok, %__MODULE__{handle: handle, backend: backend, sample_rate: sample_rate}}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Synthesize audio from a list of phoneme IDs. Returns the f32
  audio tensor (shape `{n_samples}`) at the model's sample rate.

  ## Options

    * `:speaker_id` — multi-speaker voices (default 0)
    * `:length_scale` — speech rate (1.0 = normal, < 1 faster)
    * `:noise_scale` — Piper VITS noise injection (default 0.667)
    * `:noise_w` — duration predictor noise (default 0.8)
  """
  @spec synthesize(%__MODULE__{}, [non_neg_integer()], keyword()) :: Nx.Tensor.t()
  def synthesize(%__MODULE__{handle: handle, backend: backend}, phoneme_ids, opts \\ []) do
    backend.piper_synthesize(handle, phoneme_ids, opts)
  end
end
