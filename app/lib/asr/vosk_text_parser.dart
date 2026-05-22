import 'dart:convert';

/// 从 Vosk JSON 结果中提取文本（final 或 partial）。
String parseVoskTranscript(String raw, {bool partial = false}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  try {
    final map = jsonDecode(trimmed) as Map<String, dynamic>;
    if (partial) {
      return (map['partial'] as String? ?? '').trim();
    }
    return (map['text'] as String? ?? '').trim();
  } catch (_) {
    return trimmed;
  }
}
