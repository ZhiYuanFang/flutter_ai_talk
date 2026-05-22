import 'package:flutter/foundation.dart' show kIsWeb;

import '../api/gateway_absolute_url.dart';

/// 将接口 `logo` 转为可请求的绝对 URL。
String? resolveEventLogoUrl(String? logo) => resolveGatewayAbsoluteUrl(logo);

String safeEventLogoFileStem(String eventId) {
  final stem = eventId.replaceAll(RegExp(r'[^\w.-]'), '_');
  return stem.isEmpty ? 'event' : stem;
}

String logoFileExtensionFromUrl(String url) {
  final path = Uri.tryParse(url)?.path ?? '';
  if (!path.contains('.')) return 'png';
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' || 'png' || 'webp' || 'gif' => ext,
    _ => 'png',
  };
}

bool get eventCatalogSupportsLocalFiles => !kIsWeb;
