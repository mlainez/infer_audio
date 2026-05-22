defmodule InferAudio.SileroVADTest do
  use ExUnit.Case, async: true

  describe "load/1" do
    test "missing model file returns {:error, _}" do
      assert {:error, _} = InferAudio.SileroVAD.load("/tmp/__no_such_silero.onnx")
    end
  end

  describe "module surface" do
    test "defined and loaded" do
      assert Code.ensure_loaded?(InferAudio.SileroVAD)
    end
  end
end
