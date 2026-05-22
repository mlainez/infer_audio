defmodule ArmAudio.DecoderTest do
  use ExUnit.Case, async: true

  describe "decode_file/1" do
    test "returns {:error, _} on a missing path" do
      assert {:error, msg} = ArmAudio.Decoder.decode_file("/tmp/__no_such_audio.wav")
      assert is_binary(msg)
    end
  end

  describe "to_mono/2" do
    test "single-channel input passes through unchanged" do
      mono = Nx.tensor([1.0, 2.0, 3.0, 4.0], type: :f32)
      out = ArmAudio.Decoder.to_mono(mono, 1)
      assert Nx.shape(out) == {4}
      assert Nx.to_flat_list(out) == [1.0, 2.0, 3.0, 4.0]
    end

    test "two-channel interleaved gets averaged" do
      # [L0, R0, L1, R1] → [(L0+R0)/2, (L1+R1)/2]
      stereo = Nx.tensor([1.0, 3.0, 2.0, 4.0], type: :f32)
      out = ArmAudio.Decoder.to_mono(stereo, 2)
      assert Nx.shape(out) == {2}
      flat = Nx.to_flat_list(out)
      assert_in_delta Enum.at(flat, 0), 2.0, 1.0e-6
      assert_in_delta Enum.at(flat, 1), 3.0, 1.0e-6
    end
  end

  describe "resample/3" do
    test "from == to is a passthrough (shape preserved)" do
      s = Nx.tensor([1.0, 2.0, 3.0, 4.0], type: :f32, backend: NxArm.Backend)
      out = ArmAudio.Decoder.resample(s, 16_000, 16_000)
      assert Nx.shape(out) == Nx.shape(s)
    end

    test "upsampling produces more samples" do
      s = Nx.tensor(List.duplicate(0.0, 100), type: :f32, backend: NxArm.Backend)
      out = ArmAudio.Decoder.resample(s, 8_000, 16_000)
      assert Nx.size(out) > Nx.size(s)
    end

    test "downsampling produces fewer samples" do
      s = Nx.tensor(List.duplicate(0.0, 200), type: :f32, backend: NxArm.Backend)
      out = ArmAudio.Decoder.resample(s, 16_000, 8_000)
      assert Nx.size(out) < Nx.size(s)
    end
  end

  describe "load_for_whisper/1" do
    test "returns {:error, _} on missing file (or raises cleanly)" do
      result =
        try do
          ArmAudio.Decoder.load_for_whisper("/tmp/__no_such_audio.wav")
        rescue
          _ -> :raised
        catch
          :error, _ -> :raised
        end

      assert match?({:error, _}, result) or result == :raised
    end
  end
end
