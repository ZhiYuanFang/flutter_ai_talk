import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'speech_engine.dart';

const _kSpeechEngineKey = 'speech_engine';
const _kLegacyIosKey = 'ios_speech_backend';

/// 持久化语音识别引擎；**Android 默认云端**，**iOS 默认系统**。
class SpeechEngineStore {
  static Future<SpeechEngine> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSpeechEngineKey);
    if (raw != null) {
      return _parse(raw) ?? _platformDefault();
    }
    final legacy = prefs.getString(_kLegacyIosKey);
    if (legacy != null) {
      return switch (legacy) {
        'vosk' => SpeechEngine.vosk,
        'systemStt' => SpeechEngine.systemStt,
        _ => _platformDefault(),
      };
    }
    return _platformDefault();
  }

  static SpeechEngine _platformDefault() {
    if (kIsWeb) return SpeechEngine.systemStt;
    if (Platform.isAndroid) return SpeechEngine.cloudAsr;
    if (Platform.isIOS) return SpeechEngine.systemStt;
    return SpeechEngine.systemStt;
  }

  static SpeechEngine? _parse(String raw) => switch (raw) {
        'vosk' => SpeechEngine.vosk,
        'systemStt' => SpeechEngine.systemStt,
        'cloudAsr' => SpeechEngine.cloudAsr,
        _ => null,
      };

  static Future<void> save(SpeechEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (engine) {
      SpeechEngine.vosk => 'vosk',
      SpeechEngine.systemStt => 'systemStt',
      SpeechEngine.cloudAsr => 'cloudAsr',
    };
    await prefs.setString(_kSpeechEngineKey, raw);
  }
}
