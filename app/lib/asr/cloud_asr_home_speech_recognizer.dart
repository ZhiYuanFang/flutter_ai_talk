import '../voice/voice_asr_ws_client.dart';
import 'home_speech_recognizer.dart';

class CloudAsrHomeSpeechRecognizer implements HomeSpeechRecognizer {
  CloudAsrHomeSpeechRecognizer(this._ws);

  final VoiceAsrWsClient _ws;
  HomeSpeechPrepareFailure? _lastFailure;

  @override
  HomeSpeechPrepareFailure? get lastPrepareFailure => _lastFailure;

  @override
  Future<bool> prepare() async {
    _lastFailure = null;
    if (_ws.wsUrl.isEmpty) {
      _lastFailure = HomeSpeechPrepareFailure.engineError;
      return false;
    }
    final ok = await _ws.connect();
    if (!ok) {
      _lastFailure = HomeSpeechPrepareFailure.voiceWsDisconnected;
    }
    return ok;
  }

  @override
  Future<void> startSession(
    void Function(String partial) onPartial, {
    void Function(double level)? onLevel,
    PcmDiagnosticsCallback? onPcmDiagnostics,
  }) async {
    final ok = await _ws.beginUtterance(
      onPartial,
      onLevel: onLevel,
      onPcmDiagnostics: onPcmDiagnostics,
    );
    if (!ok) {
      _lastFailure = _ws.isReady
          ? HomeSpeechPrepareFailure.engineError
          : HomeSpeechPrepareFailure.voiceWsDisconnected;
    }
  }

  @override
  Future<String> endSession() => _ws.endUtterance();

  @override
  Future<void> cancelSession() => _ws.cancelUtterance();

  @override
  void dispose() {}
}
