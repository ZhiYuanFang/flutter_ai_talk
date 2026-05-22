import 'package:flutter/material.dart';

/// 云端聆听时的录音诊断读数。
class RecordingDiagnosticsSnapshot {
  const RecordingDiagnosticsSnapshot({
    this.chunkAvgAbs = 0,
    this.sessionAvgAbs = 0,
    this.elapsedSeconds = 0,
  });

  final int chunkAvgAbs;
  final int sessionAvgAbs;
  final double elapsedSeconds;
}

/// 语音圆左侧：PCM 格式 / 采样率 / 双 avgAbs / 时长。
class HomeVoiceRecordingStats extends StatelessWidget {
  const HomeVoiceRecordingStats({
    super.key,
    required this.stats,
  });

  final RecordingDiagnosticsSnapshot stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          fontSize: 10,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface.withValues(alpha: 0.85),
        );

    String line(String label, String value) => '$label $value';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line('格式', 'PCM16'), style: style),
        Text(line('采样', '16 kHz'), style: style),
        Text(line('块', 'avg ${stats.chunkAvgAbs}'), style: style),
        Text(line('场', 'avg ${stats.sessionAvgAbs}'), style: style),
        Text(
          line('时长', '${stats.elapsedSeconds.toStringAsFixed(1)} s'),
          style: style,
        ),
      ],
    );
  }
}
