defmodule InferAudio.DecoderTest do
  use ExUnit.Case, async: true

  describe "decode_file/1" do
    test "returns {:error, _} on a missing path" do
      assert {:error, msg} = InferAudio.Decoder.decode_file("/tmp/__no_such_audio.wav")
      assert is_binary(msg)
    end
  end

  describe "to_mono/2" do
    test "single-channel input passes through unchanged" do
      mono = Nx.tensor([1.0, 2.0, 3.0, 4.0], type: :f32)
      out = InferAudio.Decoder.to_mono(mono, 1)
      assert Nx.shape(out) == {4}
      assert Nx.to_flat_list(out) == [1.0, 2.0, 3.0, 4.0]
    end

    test "two-channel interleaved gets averaged" do
      # [L0, R0, L1, R1] → [(L0+R0)/2, (L1+R1)/2]
      stereo = Nx.tensor([1.0, 3.0, 2.0, 4.0], type: :f32)
      out = InferAudio.Decoder.to_mono(stereo, 2)
      assert Nx.shape(out) == {2}
      flat = Nx.to_flat_list(out)
      assert_in_delta Enum.at(flat, 0), 2.0, 1.0e-6
      assert_in_delta Enum.at(flat, 1), 3.0, 1.0e-6
    end
  end

  describe "resample/3" do
    test "from == to is a passthrough (shape preserved)" do
      s = Nx.tensor([1.0, 2.0, 3.0, 4.0], type: :f32, backend: NxArm.Backend)
      out = InferAudio.Decoder.resample(s, 16_000, 16_000)
      assert Nx.shape(out) == Nx.shape(s)
    end

    test "upsampling produces more samples" do
      s = Nx.tensor(List.duplicate(0.0, 100), type: :f32, backend: NxArm.Backend)
      out = InferAudio.Decoder.resample(s, 8_000, 16_000)
      assert Nx.size(out) > Nx.size(s)
    end

    test "downsampling produces fewer samples" do
      s = Nx.tensor(List.duplicate(0.0, 200), type: :f32, backend: NxArm.Backend)
      out = InferAudio.Decoder.resample(s, 16_000, 8_000)
      assert Nx.size(out) < Nx.size(s)
    end
  end

  describe "load_for_whisper/1" do
    test "returns {:error, _} on a missing file" do
      assert {:error, _} = InferAudio.Decoder.load_for_whisper("/tmp/__no_such_audio.wav")
    end
  end

  describe "write_wav/3 + decode_file/1 round trip" do
    @tag :tmp_dir
    test "a written WAV decodes back to the same samples", %{tmp_dir: dir} do
      path = Path.join(dir, "tone.wav")
      tone = Nx.tensor(Enum.map(0..799, &(0.5 * :math.sin(&1 * 2 * :math.pi() / 40))), type: :f32)

      :ok = InferAudio.Decoder.write_wav(path, tone, sample_rate: 8_000)
      assert {:ok, %{samples: back, sample_rate: 8_000, channels: 1}} =
               InferAudio.Decoder.decode_file(path)

      assert Nx.size(back) == 800
      # 16-bit PCM quantization error is at most 1/32768 per sample.
      assert Nx.to_number(Nx.reduce_max(Nx.abs(Nx.subtract(back, tone)))) < 1.0e-3
    end

    @tag :tmp_dir
    test "load_for_whisper resamples to 16 kHz mono", %{tmp_dir: dir} do
      path = Path.join(dir, "tone.wav")
      :ok = InferAudio.Decoder.write_wav(path, Nx.broadcast(Nx.tensor(0.1, type: :f32), {8_000}), sample_rate: 8_000)
      pcm = InferAudio.Decoder.load_for_whisper(path)
      assert_in_delta Nx.size(pcm), 16_000, 200
    end
  end
end
