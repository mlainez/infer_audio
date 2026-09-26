defmodule InferAudio.Backend do
  @moduledoc """
  Behaviour for audio I/O backends: file decode, resampling, Whisper
  input preparation, and WAV output.

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
