import 'dart:math';
import 'dart:typed_data';

/// 云端 PCM 诊断：块级与会话 avgAbs 累计。
class PcmAbsSessionAccumulator {
  var sumAbs = 0.0;
  var sampleCount = 0;

  void reset() {
    sumAbs = 0;
    sampleCount = 0;
  }

  int get sessionAvgAbs =>
      sampleCount == 0 ? 0 : (sumAbs / sampleCount).round();
}

/// 单次 PCM 块解析结果（响度 + avgAbs）。
class Pcm16ChunkMetrics {
  const Pcm16ChunkMetrics({
    required this.level,
    required this.chunkAvgAbs,
    required this.sessionAvgAbs,
  });

  final double level;
  final int chunkAvgAbs;
  final int sessionAvgAbs;
}

/// PCM16 LE 单声道块：响度 [0,1] + 块/会话 avgAbs（单次遍历）。
Pcm16ChunkMetrics pcm16ProcessChunk(
  Uint8List bytes,
  PcmAbsSessionAccumulator session,
) {
  if (bytes.length < 2) {
    return Pcm16ChunkMetrics(
      level: 0,
      chunkAvgAbs: 0,
      sessionAvgAbs: session.sessionAvgAbs,
    );
  }

  final bd = ByteData.sublistView(bytes);
  final count = bytes.length ~/ 2;
  var sumSquares = 0.0;
  var peak = 0.0;
  var chunkSumAbs = 0.0;

  for (var i = 0; i < count; i++) {
    final sample = bd.getInt16(i * 2, Endian.little).toDouble();
    final abs = sample.abs();
    if (abs > peak) peak = abs;
    sumSquares += sample * sample;
    chunkSumAbs += abs;
    session.sumAbs += abs;
    session.sampleCount++;
  }

  final rms = sqrt(sumSquares / count);
  const fullScale = 12000.0;
  final rmsNorm = (rms / fullScale).clamp(0.0, 1.0);
  final peakNorm = (peak / 32768.0).clamp(0.0, 1.0);
  final level = ((rmsNorm * 0.65 + peakNorm * 0.35) * 1.2).clamp(0.0, 1.0);
  final chunkAvgAbs = (chunkSumAbs / count).round();

  return Pcm16ChunkMetrics(
    level: level,
    chunkAvgAbs: chunkAvgAbs,
    sessionAvgAbs: session.sessionAvgAbs,
  );
}

/// PCM16 LE 单声道块 → 归一化响度 [0, 1]（RMS + 峰值混合）。
double pcm16PeakRmsNormalized(Uint8List bytes) {
  final session = PcmAbsSessionAccumulator();
  return pcm16ProcessChunk(bytes, session).level;
}

/// `speech_to_text` [onSoundLevelChange] 分贝值 → [0, 1]。
double sttSoundLevelNormalized(double db) {
  const minDb = -2.0;
  const maxDb = 10.0;
  return ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
}
