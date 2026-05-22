/// 主页按住说话的语音识别引擎（可在设置中心切换并记忆）。
enum SpeechEngine {
  /// 端侧 Vosk（内置 zip 模型）。
  vosk,

  /// 系统 SpeechRecognizer（speech_to_text）。
  systemStt,

  /// 云端流式 ASR（WebSocket `/voice/asr/ws`）。
  cloudAsr,
}

extension SpeechEngineLabels on SpeechEngine {
  /// 设置页下拉与对外展示的简短名称。
  String get label => switch (this) {
        SpeechEngine.vosk => '本地识别',
        SpeechEngine.systemStt => '系统识别',
        SpeechEngine.cloudAsr => '云端识别',
      };
}
