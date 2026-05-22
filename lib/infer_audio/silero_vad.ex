defmodule InferAudio.SileroVAD do
  @moduledoc """
  Voice activity detection — generic API delegating to a configured
  `InferAudio.Backend`.

  Silero VAD is a small NN that classifies 16 kHz audio windows as
  speech / non-speech. Use it to gate Whisper transcription on
  actually hearing a voice (saves cycles vs running Whisper on
  silence).

      {:ok, vad} = InferAudio.SileroVAD.load("/root/silero_vad.onnx")
      pcm = InferAudio.Decoder.load_for_whisper("/data/clip.wav")
      segments = InferAudio.SileroVAD.detect(vad, pcm, threshold: 0.5)
      # segments = [%{start_ms: 320, end_ms: 1840}, ...]
  """

  defstruct [:handle, :backend]

  @sample_rate 16_000
  @window_samples 512

  @doc """
  Load a Silero VAD model. Path interpretation is up to the active
  backend (ONNX file for ortex/tract, HEF for a Hailo impl, etc.).
  """
  @spec load(Path.t(), keyword()) :: {:ok, %__MODULE__{}} | {:error, term()}
  def load(path, opts \\ []) do
    backend = InferAudio.Backend.resolve(opts)

    case backend.silero_vad_load(path, opts) do
      {:ok, handle} -> {:ok, %__MODULE__{handle: handle, backend: backend}}
      {:error, _} = err -> err
    end
  end

  @doc """
  Per-window speech-probability tensor of shape `{n_windows}`.
  """
  @spec scores(%__MODULE__{}, Nx.Tensor.t(), keyword()) :: Nx.Tensor.t()
  def scores(%__MODULE__{handle: handle, backend: backend}, audio, opts \\ []) do
    backend.silero_vad_scores(handle, audio, opts)
  end

  @doc """
  Run VAD and return speech segments as `[%{start_ms, end_ms}]`.

  ## Options

    * `:threshold` — probability cutoff (default 0.5)
    * `:min_speech_ms` — drop segments shorter than this (default 250)
    * `:min_silence_ms` — gap below threshold needed to break a
      segment (default 100)
    * `:backend` — override the configured `InferAudio.Backend`
  """
  @spec detect(%__MODULE__{}, Nx.Tensor.t(), keyword()) ::
          [%{start_ms: non_neg_integer(), end_ms: non_neg_integer()}]
  def detect(%__MODULE__{} = vad, audio, opts \\ []) do
    threshold = Keyword.get(opts, :threshold, 0.5)
    min_speech_ms = Keyword.get(opts, :min_speech_ms, 250)
    min_silence_ms = Keyword.get(opts, :min_silence_ms, 100)

    window_ms = div(@window_samples * 1000, @sample_rate)

    probs = vad |> scores(audio, opts) |> Nx.to_flat_list()

    {_state, segments_rev} =
      Enum.with_index(probs)
      |> Enum.reduce({nil, []}, fn {p, i}, {state, segs} ->
        is_speech = p >= threshold
        t = i * window_ms

        case {state, is_speech} do
          {nil, true} ->
            {{:speech, t, t + window_ms, 0}, segs}

          {nil, false} ->
            {nil, segs}

          {{:speech, s, _e, _sil}, true} ->
            {{:speech, s, t + window_ms, 0}, segs}

          {{:speech, s, e, sil}, false} ->
            new_sil = sil + window_ms

            if new_sil >= min_silence_ms do
              if e - s >= min_speech_ms do
                {nil, [%{start_ms: s, end_ms: e} | segs]}
              else
                {nil, segs}
              end
            else
              {{:speech, s, e, new_sil}, segs}
            end
        end
      end)

    Enum.reverse(segments_rev)
  end
end
