import 'package:record/record.dart';

/// App 内 PCM 语音采集唯一配置（远场导向；chat / ASR / KWS 共用）。
abstract final class AppVoiceRecordConfig {
  static const sampleRate = 16000;

  /// 横屏 chat 有效音块级 avgAbs 门槛（平放屏朝上 2m 小声真机标定初值）。
  static const effectiveChunkAvgAbs = 130;

  /// 与服务端 Go `pcmEffectiveAvgAbsThreshold` 对齐参考（±20 标定）。
  static const serverEffectiveAvgAbsHint = 150;

  /// 16 kHz / mono / PCM16；AGC 开；NS/AEC 关；Android 识别音源。
  static const pcm16kMono = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: sampleRate,
    numChannels: 1,
    autoGain: true,
    echoCancel: false,
    noiseSuppress: false,
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.voiceRecognition,
    ),
  );
}
