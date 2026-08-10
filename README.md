# infer_audio

> ### ⚠️ Very early work — built for a workshop, not for production
>
> This package was written for the **Goatmire Elixir workshop** on running
> Nerves on Fairphone 3 hardware. It exists for tinkering and teaching.
>
> It is **not an actively maintained project** (yet). There are no
> stability guarantees, APIs will change without notice, and parts of it
> are wired-but-unproven. Treat it as a starting point to hack on, not as
> a dependency to build a product on.
>
> See [`nerves_ai`](https://github.com/mlainez/nerves_ai) for the full
> stack and the workshop context.

Audio I/O and audio-model wrappers for Nerves devices, returning Nx
tensors.

Part of the [`nerves_ai`](https://github.com/mlainez/nerves_ai) edge-AI
stack. This package is the generic API; native decoding and inference sit
behind the `InferAudio.Backend` behaviour.

## What's here

| Module | What it does |
|---|---|
| `InferAudio.Decoder` | Decode audio files, downmix, resample, write WAV |
| `InferAudio.SileroVAD` | Voice activity detection (ONNX) |
| `InferAudio.Piper` | Text-to-speech (Piper VITS, ONNX) |

Decoding is symphonia + rubato behind the NIF, so MP3/FLAC/WAV/OGG all
work without shelling out to `ffmpeg`.

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

### Decode and resample

```elixir
samples = InferAudio.Decoder.decode_file("/data/clip.mp3")
mono    = InferAudio.Decoder.to_mono(samples, 2)
pcm16k  = InferAudio.Decoder.resample(mono, 44_100, 16_000)

# Or the one-liner for STT: decode → mono → 16 kHz
pcm = InferAudio.Decoder.load_for_whisper("/data/clip.mp3")
```

### Voice activity detection

```elixir
{:ok, vad} = InferAudio.SileroVAD.load("/data/models/silero_vad.onnx")
segments   = InferAudio.SileroVAD.detect(vad, pcm, threshold: 0.5)
```

### Text to speech

```elixir
{:ok, piper} = InferAudio.Piper.load("/data/models/en_US-amy-medium.onnx",
                 sample_rate: 22_050)

audio = InferAudio.Piper.synthesize(piper, phoneme_ids, length_scale: 1.0)
InferAudio.Decoder.write_wav("/data/out.wav", audio, sample_rate: 22_050)
```

## Caveats

**Piper takes phoneme IDs, not text.** Getting from a string to those IDs
needs a grapheme-to-phoneme step plus the `phoneme_id_map` from the
voice's `.onnx.json` file. `ArmAI.Phonemizer` provides
`to_phoneme_ids/2` for the mapping and a demo-grade
`simple_english_phonemize/1` for the G2P — good enough for a
demonstration, but it mangles proper nouns. Production deployments
should phonemize with eSpeak NG (off-device, or via your own NIF) and
pass the IDs in.

**Check your voice's sample rate.** `load/2` defaults to 22050, which is
right for Piper medium voices; some voices are 16000. The real value is
in the voice's `.onnx.json`.

## License

Apache-2.0
