import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter_service/vosk_flutter.dart';

import '../audio/pcm_level.dart';
import 'home_speech_recognizer.dart';
import 'vosk_text_parser.dart';

/// 内置 zip 模型路径（见 [assets/models/README.md]）。
const kVoskCnSmallModelAsset = 'assets/models/vosk-model-small-cn-0.22.zip';
const kVoskSampleRate = 16000;

final _recordConfig = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: kVoskSampleRate,
  numChannels: 1,
);

/// 使用 [record] 采集 PCM + Vosk [Recognizer]，避免插件内置 SpeechService
/// 在华为等机型上 AudioRecord 崩溃（error reading audio buffer）。
class VoskHomeSpeechRecognizer implements HomeSpeechRecognizer {
  final _vosk = VoskFlutterPlugin.instance();
  final _loader = ModelLoader();
  final _recorder = AudioRecorder();

  Model? _model;
  Recognizer? _recognizer;
  StreamSubscription<Uint8List>? _pcmSub;
  var _feedBusy = false;

  String _lastPartial = '';
  void Function(String partial)? _onPartial;
  void Function(double level)? _onLevel;
  HomeSpeechPrepareFailure? _lastFailure;

  @override
  HomeSpeechPrepareFailure? get lastPrepareFailure => _lastFailure;

  @override
  Future<bool> prepare() async {
    _lastFailure = null;
    try {
      if (_recognizer != null) return true;

      if (!await _recorder.hasPermission(request: true)) {
        _lastFailure = HomeSpeechPrepareFailure.permissionDenied;
        return false;
      }

      final modelPath = await _loader.loadFromAssets(kVoskCnSmallModelAsset);
      await _waitForModelFiles(modelPath);

      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: kVoskSampleRate,
      );
      return true;
    } on FlutterError catch (e) {
      debugPrint('Vosk prepare FlutterError: $e');
      final msg = e.toString();
      if (msg.contains('Unable to load asset')) {
        _lastFailure = HomeSpeechPrepareFailure.modelMissing;
      } else {
        _lastFailure = HomeSpeechPrepareFailure.engineError;
      }
      return false;
    } catch (e) {
      debugPrint('Vosk prepare failed: $e');
      final msg = e.toString();
      if (msg.contains('Unable to load asset') || msg.contains('Asset not found')) {
        _lastFailure = HomeSpeechPrepareFailure.modelMissing;
      } else if (msg.contains('permission') || msg.contains('Permission')) {
        _lastFailure = HomeSpeechPrepareFailure.permissionDenied;
      } else if (msg.contains('does not contain model files') || msg.contains('model files missing')) {
        _lastFailure = HomeSpeechPrepareFailure.modelMissing;
      } else {
        _lastFailure = HomeSpeechPrepareFailure.engineError;
      }
      return false;
    }
  }

  Future<void> _waitForModelFiles(String modelPath) async {
    final marker = File('$modelPath/graph/Gr.fst');
    for (var i = 0; i < 60; i++) {
      if (await marker.exists()) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('model files missing at $modelPath');
  }

  @override
  Future<void> startSession(
    void Function(String partial) onPartial, {
    void Function(double level)? onLevel,
    PcmDiagnosticsCallback? onPcmDiagnostics,
  }) async {
    final recognizer = _recognizer;
    if (recognizer == null) return;

    await _stopCapture();
    _onPartial = onPartial;
    _onLevel = onLevel;
    _lastPartial = '';
    await recognizer.reset();

    if (!await _recorder.hasPermission(request: true)) {
      _lastFailure = HomeSpeechPrepareFailure.permissionDenied;
      return;
    }

    final stream = await _recorder.startStream(_recordConfig);
    _pcmSub = stream.listen((bytes) {
      unawaited(_feedPcm(bytes));
    });
  }

  Future<void> _feedPcm(Uint8List bytes) async {
    if (_feedBusy || _recognizer == null || bytes.isEmpty) return;
    _feedBusy = true;
    try {
      _onLevel?.call(pcm16PeakRmsNormalized(bytes));
      await _recognizer!.acceptWaveformBytes(bytes);
      final raw = await _recognizer!.getPartialResult();
      final partial = parseVoskTranscript(raw, partial: true);
      if (partial.isNotEmpty) {
        _lastPartial = partial;
        _onPartial?.call(partial);
      }
    } catch (e) {
      debugPrint('Vosk feed pcm: $e');
    } finally {
      _feedBusy = false;
    }
  }

  @override
  Future<String> endSession() async {
    await _stopCapture();
    final recognizer = _recognizer;
    if (recognizer == null) return '';

    try {
      final raw = await recognizer.getFinalResult();
      final text = parseVoskTranscript(raw).trim();
      if (text.isNotEmpty) return text;
    } catch (e) {
      debugPrint('Vosk final result: $e');
    }
    return _lastPartial.trim();
  }

  @override
  Future<void> cancelSession() async {
    await _stopCapture();
    _lastPartial = '';
    await _recognizer?.reset();
  }

  Future<void> _stopCapture() async {
    _onLevel = null;
    await _pcmSub?.cancel();
    _pcmSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  void dispose() {
    unawaited(_stopCapture().then((_) => _recorder.dispose()));
    _recognizer = null;
    _model = null;
  }
}
