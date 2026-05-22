ExUnit.start()
Application.put_env(:infer_audio, :backend, ArmAI.AudioBackend)
Application.put_env(:infer_vision, :backend, ArmAI.VisionBackend)
