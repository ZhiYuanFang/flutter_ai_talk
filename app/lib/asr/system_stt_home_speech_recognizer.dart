import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../audio/pcm_level.dart';
import 'home_speech_recognizer.dart';

const _kFallbackChineseLocaleId = 'zh_CN';

/// 系统 [speech_to_text]（主要用于 iOS「系统语音识别」选项）。
class SystemSttHomeSpeechRecognizer implements HomeSpeechRecognizer {
  final _speech = stt.SpeechToText();
  var _ready = false;
  String _chineseLocaleId = _kFallbackChineseLocaleId;
  HomeSpeechPrepareFailure? _lastFailure;

  @override
  HomeSpeechPrepareFailure? get lastPrepareFailure => _lastFailure;

  @override
  Future<bool> prepare() async {
    _lastFailure = null;
    if (_ready) return true;
    final ok = await _speech.initialize(onError: (_) {});
    _ready = ok;
    if (!ok) {
      _lastFailure = HomeSpeechPrepareFailure.engineError;
      return false;
    }
    await _cacheChineseLocaleId();
    return true;
  }

  @override
  Future<void> startSession(
    void Function(String partial) onPartial, {
    void Function(double level)? onLevel,
    PcmDiagnosticsCallback? onPcmDiagnostics,
  }) async {
    await _speech.listen(
      localeId: _chineseLocaleId,
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

  Future<void> _cacheChineseLocaleId() async {
    try {
      final locales = await _speech.locales();
      _chineseLocaleId = _pickChineseLocaleId(locales);
    } catch (_) {
      _chineseLocaleId = _kFallbackChineseLocaleId;
    }
  }

  static String _pickChineseLocaleId(List<stt.LocaleName> locales) {
    bool matches(String localeId, String target) =>
        _normalizeLocaleId(localeId) == _normalizeLocaleId(target);

    for (final locale in locales) {
      if (matches(locale.localeId, 'zh_CN')) return locale.localeId;
    }
    for (final locale in locales) {
      if (matches(locale.localeId, 'cmn-Hans-CN')) return locale.localeId;
    }
    for (final locale in locales) {
      final normalized = _normalizeLocaleId(locale.localeId);
      if (normalized.startsWith('zh') || normalized.startsWith('cmn_hans')) {
        return locale.localeId;
      }
    }
    return _kFallbackChineseLocaleId;
  }

  static String _normalizeLocaleId(String localeId) =>
      localeId.replaceAll('-', '_').toLowerCase();
}
