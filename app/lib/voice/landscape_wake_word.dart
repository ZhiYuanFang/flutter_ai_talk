import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../api/app_debug_log.dart';
import 'landscape_kws_models.dart';

/// 横屏前台唤醒词检测（「你好，胖宝」）。
abstract class LandscapeWakeWord {
  /// 每次命中唤醒词发一次事件。
  Stream<void> get detections;

  /// 无法启动时的用户可读原因。
  String? get unavailableReason;

  Future<bool> start({void Function(String status)? onStatus});
  Future<void> stop();
  Future<void> pause();

  /// 对话轮次结束后恢复 KWS 麦流；成功返回 true。
  Future<bool> resume();
}

/// 工厂：Android / iOS 共用 Sherpa KWS（仅前台横屏）。
LandscapeWakeWord createLandscapeWakeWord() {
  if (kIsWeb) return _NoopWakeWord('Web 不支持');
  if (Platform.isAndroid || Platform.isIOS) {
    return SherpaLandscapeWakeWord();
  }
  return _NoopWakeWord('当前平台不支持唤醒');
}

class _NoopWakeWord implements LandscapeWakeWord {
  _NoopWakeWord(this.unavailableReason);

  @override
  final String unavailableReason;
  final _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get detections => _controller.stream;

  @override
  Future<bool> start({void Function(String status)? onStatus}) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<bool> resume() async => false;
}

var _sherpaBindingsReady = false;

void _ensureSherpaBindings() {
  if (_sherpaBindingsReady) return;
  sherpa.initBindings();
  _sherpaBindingsReady = true;
}

/// Sherpa-ONNX 中文 KWS：「你好，胖宝」。
///
/// 模型首次从 GitHub Release 下载到应用支持目录；之后离线可用。
class SherpaLandscapeWakeWord implements LandscapeWakeWord {
  final _controller = StreamController<void>.broadcast();
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSub;

  sherpa.KeywordSpotter? _spotter;
  sherpa.OnlineStream? _stream;

  var _running = false;
  var _paused = false;
  var _emitCooldown = false;
  String? _reason;

  @override
  Stream<void> get detections => _controller.stream;

  @override
  String? get unavailableReason => _reason;

  @override
  Future<bool> start({void Function(String status)? onStatus}) async {
    await stop();
    _reason = '正在准备唤醒模型…';
    onStatus?.call(_reason!);
    try {
      _ensureSherpaBindings();
      final paths = await ensureLandscapeKwsModels(
        onStatus: (s) {
          _reason = s;
          onStatus?.call(s);
        },
      );
      if (paths == null) {
        // 保留 ensure 经 onStatus 写入的短因，避免盖成笼统文案。
        final detail = _reason;
        final keepDetail = detail != null &&
            detail.isNotEmpty &&
            !detail.startsWith('正在');
        _reason = keepDetail
            ? '$detail（点按可临时联调）'
            : '唤醒模型准备失败：点按左下角可临时联调对话';
        return false;
      }

      final transducer = sherpa.OnlineTransducerModelConfig(
        encoder: paths.encoder,
        decoder: paths.decoder,
        joiner: paths.joiner,
      );
      final modelConfig = sherpa.OnlineModelConfig(
        transducer: transducer,
        tokens: paths.tokens,
        numThreads: 2,
        provider: 'cpu',
        modelType: 'zipformer2',
        modelingUnit: 'ppinyin',
      );
      final config = sherpa.KeywordSpotterConfig(
        model: modelConfig,
        keywordsFile: paths.keywords,
        keywordsThreshold: 0.25,
        keywordsScore: 1.5,
      );
      _spotter = sherpa.KeywordSpotter(config);
      _stream = _spotter!.createStream();

      if (!await _recorder.hasPermission(request: false)) {
        _reason = '需要麦克风权限才能语音唤醒';
        await _disposeSpotter();
        return false;
      }

      const cfg = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );
      final pcm = await _recorder.startStream(cfg);
      _pcmSub = pcm.listen(_onPcm);
      _running = true;
      _paused = false;
      _reason = null;
      return true;
    } catch (e) {
      _reason = '唤醒引擎启动失败：点按左下角可临时联调';
      await _disposeSpotter();
      return false;
    }
  }

  void _onPcm(Uint8List bytes) {
    if (!_running || _paused || _spotter == null || _stream == null) return;
    if (bytes.length < 2) return;
    try {
      final samples = _pcm16ToFloat32(bytes);
      _stream!.acceptWaveform(samples: samples, sampleRate: 16000);
      while (_spotter!.isReady(_stream!)) {
        _spotter!.decode(_stream!);
        final kw = _spotter!.getResult(_stream!).keyword.trim();
        if (kw.isEmpty) continue;
        // 重置流避免连续误触发。
        _spotter!.reset(_stream!);
        if (_emitCooldown || _paused) return;
        _emitCooldown = true;
        if (!_controller.isClosed) _controller.add(null);
        // 短冷却，防止同一次发音重复触发。
        Future<void>.delayed(const Duration(milliseconds: 1200), () {
          _emitCooldown = false;
        });
        return;
      }
    } catch (_) {
      // 单块失败不拆整条监听。
    }
  }

  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    final count = bytes.length ~/ 2;
    final out = Float32List(count);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < count; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  Future<void> _disposeSpotter() async {
    try {
      _stream?.free();
    } catch (_) {}
    _stream = null;
    try {
      _spotter?.free();
    } catch (_) {}
    _spotter = null;
  }

  @override
  Future<void> stop() async {
    _running = false;
    _paused = false;
    await _pcmSub?.cancel();
    _pcmSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _disposeSpotter();
  }

  @override
  Future<void> pause() async {
    _paused = true;
    // 对话轮次占用麦克风：停录音但保留 spotter，resume 时重开流。
    await _pcmSub?.cancel();
    _pcmSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<bool> resume() async {
    // 引擎未就绪：无法恢复。
    if (!_running || _spotter == null) {
      _paused = false;
      AppDebugLog.landscapeKws('resume skip not_running');
      return false;
    }
    // 已在听：视为成功。
    if (_pcmSub != null) {
      _paused = false;
      return true;
    }
    try {
      // 释放旧 OnlineStream，避免泄漏与脏状态。
      try {
        _stream?.free();
      } catch (_) {}
      _stream = null;
      _paused = false;
      // 确保本端 recorder 已停，再与 chat 抢麦。
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _stream = _spotter!.createStream();
      const cfg = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );
      final pcm = await _recorder
          .startStream(cfg)
          .timeout(const Duration(seconds: 5));
      _pcmSub = pcm.listen(_onPcm);
      _reason = null;
      AppDebugLog.landscapeKws('resume ok');
      return true;
    } catch (e) {
      _reason = '恢复唤醒监听失败';
      AppDebugLog.landscapeKws('resume err=$e');
      return false;
    }
  }
}
