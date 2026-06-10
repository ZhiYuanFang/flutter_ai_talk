/// 与 device-service / ucg-service / voice-service 约定的 AI 业务错误码。
const int kAiCodeNotLoggedIn = 40301;

/// 当月 AI 额度已用尽。
const int kAiCodeQuotaExhausted = 40302;

/// 是否为 AI 额度/登录类业务码（优先按 code 分支，避免匹配英文 message）。
bool isAiQuotaBusinessCode(int code) =>
    code == kAiCodeNotLoggedIn || code == kAiCodeQuotaExhausted;

/// 从 WebSocket error 帧解析业务码；无 code 或 type 非 error 时返回 null。
int? parseWsErrorBusinessCode(Map<String, dynamic> frame) {
  final type = frame['type'];
  if (type is! String || type != 'error') return null;
  final codeVal = frame['code'];
  if (codeVal is int) return codeVal;
  if (codeVal is num) return codeVal.toInt();
  return null;
}
