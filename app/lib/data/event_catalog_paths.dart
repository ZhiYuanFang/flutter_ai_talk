import '../api/gateway_absolute_url.dart';

/// 将接口 `logo` 转为可请求的绝对 URL（服务端返回 CDN https 时原样使用）。
String? resolveEventLogoUrl(String? logo) {
  if (logo == null) return null;
  final t = logo.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return t;
  }
  // 迁移完成后 API 不应再返回 path-only；保留网关拼接仅便于本地联调旧数据。
  return resolveGatewayAbsoluteUrl(t);
}
