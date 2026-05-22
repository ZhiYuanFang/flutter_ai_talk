import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/speech_engine.dart';
import '../config/speech_engine_store.dart';
import '../providers/voice_asr_ws_provider.dart';
import 'cloud_asr_home_speech_recognizer.dart';
import 'home_speech_recognizer.dart';
import 'system_stt_home_speech_recognizer.dart';
import 'vosk_home_speech_recognizer.dart';

/// 按设置中心引擎创建识别器；Android 默认云端，iOS 默认系统。
Future<HomeSpeechRecognizer> createHomeSpeechRecognizer(WidgetRef ref) async {
  if (kIsWeb) {
    throw UnsupportedError('Web 不使用按住说话识别');
  }
  final engine = await SpeechEngineStore.load();
  return switch (engine) {
    SpeechEngine.vosk => VoskHomeSpeechRecognizer(),
    SpeechEngine.systemStt => SystemSttHomeSpeechRecognizer(),
    SpeechEngine.cloudAsr => CloudAsrHomeSpeechRecognizer(ref.read(voiceAsrWsClientProvider)),
  };
}

Future<String> describeActiveSpeechEngine() async {
  if (kIsWeb) return '文字输入';
  final engine = await SpeechEngineStore.load();
  return engine.label;
}

bool speechEngineUsesVoiceWs(SpeechEngine engine) => engine == SpeechEngine.cloudAsr;
