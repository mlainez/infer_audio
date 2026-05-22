defmodule InferAudio.Decoder do
  @moduledoc """
  Audio decode + resample — generic API delegating to a configured
  `InferAudio.Backend`.

      # One-shot: file path → Whisper-ready 16 kHz mono f32 tensor.
      samples = InferAudio.Decoder.load_for_whisper("/data/clip.mp3")
      # samples is an Nx tensor, shape {n_samples}.

      # Or step-by-step:
      {:ok, %{samples: raw, sample_rate: sr, channels: ch}} =
        InferAudio.Decoder.decode_file("/data/clip.wav")
      mono = InferAudio.Decoder.to_mono(raw, ch)
      sixteen = InferAudio.Decoder.resample(mono, sr, 16_000)
  """

  @doc """
  Decode an audio file (any format the backend understands) into
  interleaved f32 samples + the source sample rate + channel count.
  Returns `{:ok, %{samples: tensor, sample_rate: int, channels: int}}`.
  """
  @spec decode_file(Path.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def decode_file(path, opts \\ []) do
    InferAudio.Backend.resolve(opts).decode_file(path)
  end

  @doc "Mix multi-channel interleaved samples to mono by averaging."
  @spec to_mono(Nx.Tensor.t(), pos_integer()) :: Nx.Tensor.t()
  def to_mono(samples, 1), do: samples

  def to_mono(samples, channels) when channels > 1 do
    # Pure Nx — no backend needed.
    samples
    |> Nx.reshape({:auto, channels})
    |> Nx.mean(axes: [-1])
  end

  @doc "Sinc-resample mono f32 samples from `from_hz` to `to_hz`."
  @spec resample(Nx.Tensor.t(), pos_integer(), pos_integer(), keyword()) :: Nx.Tensor.t()
  def resample(samples, from_hz, to_hz, opts \\ []) do
    InferAudio.Backend.resolve(opts).resample(samples, from_hz, to_hz)
  end

  @doc """
  One-shot: decode → mono → resample to 16 kHz. Returns an Nx
  tensor of shape `{n_samples}` ready for Whisper / wav2vec2 /
  any 16 kHz speech model.
  """
  @spec load_for_whisper(Path.t(), keyword()) :: Nx.Tensor.t() | {:error, term()}
  def load_for_whisper(path, opts \\ []) do
    InferAudio.Backend.resolve(opts).load_for_whisper(path)
  end

  @doc """
  Write mono f32 samples in `[-1.0, 1.0]` to a 16-bit PCM WAV file.
  Used for saving TTS output, Whisper round-trips, etc.
  """
  @spec write_wav(Path.t(), Nx.Tensor.t() | binary(), keyword()) :: :ok
  def write_wav(path, samples, opts \\ []) do
    InferAudio.Backend.resolve(opts).write_wav(path, samples, opts)
  end
end
