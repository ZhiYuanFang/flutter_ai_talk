import 'dart:convert';

import 'ai_quota_codes.dart';

enum ClinicWsErrorKind { auth, quota, llm, generic }

const kClinicWsFallbackMessage = '服务暂时不可用，请稍后再试';

/// 胖宝诊疗 WS error 帧解析结果。
class ParsedClinicWsError {
  const ParsedClinicWsError({
    required this.kind,
    required this.userMessage,
    this.businessCode,
  });

  final ClinicWsErrorKind kind;
  final String userMessage;
  final int? businessCode;
}

/// 鉴权类 error（如 40301）应清除 WS auth 态。
bool isClinicWsAuthError(Map<String, dynamic> frame) {
  return parseWsErrorBusinessCode(frame) == kAiCodeNotLoggedIn;
}

ClinicWsErrorKind classifyClinicWsError(Map<String, dynamic> frame) {
  final code = parseWsErrorBusinessCode(frame);
  if (code == kAiCodeNotLoggedIn) return ClinicWsErrorKind.auth;
  if (code == kAiCodeQuotaExhausted) return ClinicWsErrorKind.quota;
  final msg = frame['message'] as String? ?? '';
  if (code == 500 && (msg.contains('429') || msg.contains('1305'))) {
    return ClinicWsErrorKind.llm;
  }
  return ClinicWsErrorKind.generic;
}

String? _extractNestedErrorMessage(String message) {
  final start = message.indexOf('{');
  if (start < 0) return null;
  try {
    final decoded = jsonDecode(message.substring(start));
    if (decoded is! Map<String, dynamic>) return null;
    final err = decoded['error'];
    if (err is Map<String, dynamic>) {
      final inner = err['message'] as String?;
      if (inner != null && inner.trim().isNotEmpty) return inner.trim();
    }
    final direct = decoded['message'] as String?;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
  } catch (_) {}
  return null;
}

String _cleanTopLevelMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return kClinicWsFallbackMessage;
  const prefix = 'LLM HTTP 429:';
  if (trimmed.startsWith(prefix)) {
    final nested = _extractNestedErrorMessage(trimmed);
    return nested ?? kClinicWsFallbackMessage;
  }
  if (trimmed.length > 120) return '${trimmed.substring(0, 117)}...';
  return trimmed;
}

ParsedClinicWsError parseClinicWsUserMessage(Map<String, dynamic> frame) {
  final kind = classifyClinicWsError(frame);
  final code = parseWsErrorBusinessCode(frame);
  final rawMsg = frame['message'] as String? ?? '';

  if (kind == ClinicWsErrorKind.auth) {
    return ParsedClinicWsError(
      kind: kind,
      userMessage: '请先登录账号',
      businessCode: code,
    );
  }
  if (kind == ClinicWsErrorKind.quota) {
    return ParsedClinicWsError(
      kind: kind,
      userMessage: '本月额度已用完',
      businessCode: code,
    );
  }

  final nested = _extractNestedErrorMessage(rawMsg);
  final userMessage = nested ?? (rawMsg.isNotEmpty ? _cleanTopLevelMessage(rawMsg) : kClinicWsFallbackMessage);
  return ParsedClinicWsError(
    kind: kind,
    userMessage: userMessage,
    businessCode: code,
  );
}
