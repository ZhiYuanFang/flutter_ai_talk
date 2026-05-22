import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../audio/pcm_level.dart';
import 'home_speech_recognizer.dart';

/// 系统 [speech_to_text]（主要用于 iOS「系统语音识别」选项）。
class SystemSttHomeSpeechRecognizer implements HomeSpeechRecognizer {
  final _speech = stt.SpeechToText();
  var _ready = false;
  HomeSpeechPrepareFailure? _lastFailure;

  @override
  HomeSpeechPrepareFailure? get lastPrepareFailure => _lastFailure;

  @override
  Future<bool> prepare() async {
    _lastFailure = null;
    if (_ready) return true;
    final ok = await _speech.initialize(
      onError: (e) => debugPrint('speech_to_text error: $e'),
    );
    _ready = ok;
    if (!ok) {
      _lastFailure = HomeSpeechPrepareFailure.engineError;
    }
    return ok;
  }

  @override
  Future<void> startSession(
    void Function(String partial) onPartial, {
    void Function(double level)? onLevel,
    PcmDiagnosticsCallback? onPcmDiagnostics,
  }) async {
    await _speech.listen(
      onResult: (r) => onPartial(r.recognizedWords),
      onSoundLevelChange: onLevel == null
          ? null
          : (db) => onLevel(sttSoundLevelNormalized(db)),
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  @override
  Future<String> endSession() async {
    await _speech.stop();
    // 最终结果由 home_screen 在 listen 回调中累积；此处由调用方传入 partial 快照。
    return '';
  }

  @override
  Future<void> cancelSession() async {
    await _speech.stop();
  }

  @override
  void dispose() {}
}
