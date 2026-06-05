import 'dart:convert';

Map<String, dynamic>? readJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    var payload = parts[1];
    final mod = payload.length % 4;
    if (mod > 0) {
      payload += '=' * (4 - mod);
    }
    final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    final decoded = utf8.decode(base64.decode(normalized));
    final map = jsonDecode(decoded);
    if (map is! Map<String, dynamic>) return null;
    return map;
  } catch (_) {
    return null;
  }
}

/// 从 JWT access token 解析 `device_no` / `deviceNo`；缺失或解析失败返回 null。
String? readJwtDeviceNo(String? token) {
  if (token == null || token.isEmpty) return null;
  final map = readJwtPayload(token);
  if (map == null) return null;
  final raw = map['device_no'] ?? map['deviceNo'];
  if (raw == null) return null;
  final normalized = raw.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

/// 从 JWT access token 解析过期时间；非 JWT 或解析失败返回 null。
DateTime? readJwtExpiry(String token) {
  final map = readJwtPayload(token);
  if (map == null) return null;
  try {
    final exp = map['exp'];
    final expSec = exp is int ? exp : (exp is num ? exp.toInt() : null);
    if (expSec == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expSec * 1000, isUtc: true).toLocal();
  } catch (_) {
    return null;
  }
}

/// access 已过期或距过期不足 [buffer] 时应尝试 refresh。
bool accessTokenShouldRefresh(
  String? accessToken, {
  Duration buffer = const Duration(minutes: 5),
}) {
  if (accessToken == null || accessToken.isEmpty) return true;
  final exp = readJwtExpiry(accessToken);
  if (exp == null) return true;
  return DateTime.now().add(buffer).isAfter(exp);
}
