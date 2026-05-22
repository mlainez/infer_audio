defmodule InferAudio.Backend do
  @moduledoc """
  Behaviour for audio inference + I/O backends.

  An implementation provides:

  * file decode + resample (symphonia/rubato or equivalent)
  * Silero VAD load + detect
  * Piper TTS load + synthesize

  ## Configuring the active backend

      config :audio, backend: ArmAI.AudioBackend

  Override per-call with `backend:` on any `Audio.*` function.
  """

  @doc "Decode an audio file. Returns `{:ok, %{samples: tensor, sample_rate: int, channels: int}}`."
  @callback decode_file(path :: String.t()) :: {:ok, map()} | {:error, term()}

  @doc "Resample an Nx tensor of f32 samples from one sample-rate to another."
  @callback resample(samples :: Nx.Tensor.t(), from :: pos_integer(), to :: pos_integer()) ::
              Nx.Tensor.t()

  @doc "Decode + downmix + resample for Whisper: mono 16 kHz f32."
  @callback load_for_whisper(path :: String.t()) :: Nx.Tensor.t() | {:error, term()}

  @doc "Write a mono or stereo Nx audio tensor to a WAV file."
  @callback write_wav(path :: String.t(), samples :: Nx.Tensor.t() | binary(), opts :: keyword()) :: :ok

  @doc "Load a Silero VAD ONNX model."
  @callback silero_vad_load(path :: String.t()) :: {:ok, term()} | {:error, term()}

  @doc "Load a Piper TTS voice ONNX model."
  @callback piper_load(path :: String.t(), opts :: keyword()) :: {:ok, term()} | {:error, term()}

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
        No Audio backend configured. Add one to your config:

            config :audio, backend: ArmAI.AudioBackend

        Or pass `backend:` explicitly to the Audio.* call.
        """

      backend when is_atom(backend) ->
        backend
    end
  end
end
