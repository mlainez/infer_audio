# infer_audio

> ### ⚠️ Very early work — built for a workshop, not for production
>
> This package was written for the **Goatmire Elixir workshop** on running
> Nerves on Fairphone 3 hardware. It exists for tinkering and teaching.
> There are no stability guarantees and APIs will change without notice.
>
> See [`nerves_ai`](https://github.com/mlainez/nerves_ai) for the full
> stack and the workshop context.

Audio I/O for Nerves devices, returning Nx tensors.

Part of the [`nerves_ai`](https://github.com/mlainez/nerves_ai) edge-AI
stack. This package is the generic API; native decoding sits behind the
`InferAudio.Backend` behaviour.

## What's here

| Module | What it does |
|---|---|
| `InferAudio.Decoder` | Decode audio files, downmix, resample, write WAV |

With `ArmAI.AudioBackend`, decoding is symphonia + rubato inside the NIF,
so WAV/MP3/FLAC/Ogg work without shelling out to `ffmpeg`.

## Install

```elixir
defp deps do
  [
    {:infer_audio, github: "mlainez/infer_audio"},
    # plus a backend — on ARM:
    {:arm_ai, github: "mlainez/arm_ai"}
  ]
end
```

```elixir
config :infer_audio, backend: ArmAI.AudioBackend
```

If you depend on `nerves_ai`, this wiring happens for you at boot.

## Usage

```elixir
{:ok, %{samples: raw, sample_rate: sr, channels: ch}} =
  InferAudio.Decoder.decode_file("/data/clip.mp3")

mono   = InferAudio.Decoder.to_mono(raw, ch)
pcm16k = InferAudio.Decoder.resample(mono, sr, 16_000)

# Or the one-liner for speech-to-text: decode → mono → 16 kHz
pcm = InferAudio.Decoder.load_for_whisper("/data/clip.mp3")

InferAudio.Decoder.write_wav("/data/out.wav", pcm, sample_rate: 16_000)
```

## Toolchain

Built and tested with Erlang/OTP 29.1.1 and Elixir 1.20.4, matching the
official Nerves systems (see `.tool-versions`).

## License

Apache-2.0
