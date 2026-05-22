import '../config/env.dart';

/// 将网关返回的相对资源路径拼为绝对 URL（与 [AppEnv.apiBaseUrl] 一致）。
String? resolveGatewayAbsoluteUrl(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final path = t.replaceFirst(RegExp(r'^/+'), '');
  return '$base/$path';
}
