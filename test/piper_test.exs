defmodule ArmAudio.PiperTest do
  use ExUnit.Case, async: true

  describe "load/2" do
    test "missing voice file returns {:error, _}" do
      assert {:error, _} = ArmAudio.Piper.load("/tmp/__no_such_piper.onnx")
    end

    test "accepts sample_rate option without crashing on the error path" do
      assert {:error, _} =
               ArmAudio.Piper.load("/tmp/__no_such_piper.onnx", sample_rate: 22_050)
    end
  end

  describe "module surface" do
    test "defined and loaded" do
      assert Code.ensure_loaded?(ArmAudio.Piper)
    end
  end
end
