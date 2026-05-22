defmodule InferAudio.Backend do
  @moduledoc """
  Behaviour for audio inference + I/O backends.

  Implementations provide:

  * file decode + resample (symphonia/rubato, ffmpeg, GStreamer, …)
  * Silero VAD load + scoring
  * Piper TTS load + synthesis

  Each callback is intentionally *task-shaped* (`silero_vad_load`,
  `silero_vad_scores`, …) — **not** ONNX-shaped — so backends that
  bypass ONNX entirely can implement the same surface. Examples:

  * `ArmAI.AudioBackend` runs the models through tract-onnx
  * `OrtexAudio.Backend` (hypothetical) would use ONNX Runtime
  * `HailoAudio.Backend` (hypothetical) would use Hailo's HEF runtime
    on a Pi 5 + AI HAT
  * `FfmpegAudio.Backend` could provide decode_file via FFmpeg

  ## Configuring the active backend

      config :infer_audio, backend: ArmAI.AudioBackend
  """

  # ---------------- audio I/O ----------------

  @doc "Decode an audio file. Returns `{:ok, %{samples: tensor, sample_rate: int, channels: int}}`."
  @callback decode_file(path :: String.t()) :: {:ok, map()} | {:error, term()}

  @doc "Resample an Nx tensor of f32 samples between two sample rates."
  @callback resample(samples :: Nx.Tensor.t(), from :: pos_integer(), to :: pos_integer()) ::
              Nx.Tensor.t()

  @doc "Decode + downmix + resample for Whisper: mono 16 kHz f32."
  @callback load_for_whisper(path :: String.t()) :: Nx.Tensor.t() | {:error, term()}

  @doc "Write a mono or stereo Nx audio tensor to a WAV file."
  @callback write_wav(path :: String.t(), samples :: Nx.Tensor.t() | binary(), opts :: keyword()) :: :ok

  # ---------------- Silero VAD ----------------

  @doc """
  Load a Silero VAD model. The path is whatever the impl expects:
  ONNX file for ortex/tract, HEF for Hailo, etc.
  """
  @callback silero_vad_load(path :: String.t(), opts :: keyword()) ::
              {:ok, term()} | {:error, term()}

  @doc """
  Score a PCM tensor and return a per-window speech-probability
  tensor (one value per 30 ms / 16 kHz window).
  """
  @callback silero_vad_scores(handle :: term(), pcm :: Nx.Tensor.t(), opts :: keyword()) ::
              Nx.Tensor.t()

  # ---------------- Piper TTS ----------------

  @doc "Load a Piper TTS voice."
  @callback piper_load(path :: String.t(), opts :: keyword()) :: {:ok, term()} | {:error, term()}

  @doc "Synthesize a phoneme-id sequence into a mono f32 audio tensor."
  @callback piper_synthesize(handle :: term(), phoneme_ids :: [non_neg_integer()], opts :: keyword()) ::
              Nx.Tensor.t()

  # ---------------- resolution ----------------

  @doc """
  Return the configured backend module. Reads the `:backend`
  option, falling back to `Application.get_env(:infer_audio, :backend)`.
  Raises if neither is set.
  """
  @spec resolve(keyword()) :: module()
  def resolve(opts) do
    case Keyword.get(opts, :backend) || Application.get_env(:infer_audio, :backend) do
      nil ->
        raise """
        No InferAudio backend configured. Add one to your config:

            config :infer_audio, backend: ArmAI.AudioBackend

        Or pass `backend:` explicitly to the InferAudio.* call.
        """

      backend when is_atom(backend) ->
        backend
    end
  end
end
