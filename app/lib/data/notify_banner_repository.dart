import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

/// 服务端维护/公告通知快照。
class NotifyBanner {
  const NotifyBanner({
    required this.active,
    required this.title,
    required this.message,
    required this.dismissible,
    required this.contentKey,
    this.expectedEndAt,
    this.updatedAt,
  });

  final bool active;
  final String title;
  final String message;
  final bool dismissible;
  final String contentKey;
  final int? expectedEndAt;
  final int? updatedAt;

  factory NotifyBanner.fromJson(Map<String, dynamic> data) {
    return NotifyBanner(
      active: data['active'] as bool? ?? false,
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      dismissible: data['dismissible'] as bool? ?? false,
      contentKey: (data['contentKey'] as String?) ?? '',
      expectedEndAt: data['expectedEndAt'] as int?,
      updatedAt: data['updatedAt'] as int?,
    );
  }
}

/// 从独立 notify 服务拉取 banner（无鉴权，不走 gateway-app）；HTTP 路径仍为 /app/api/status/banner。
class NotifyBannerRepository {
  const NotifyBannerRepository();

  Future<NotifyBanner?> fetchBanner() async {
    final base = AppEnv.notifyBaseUrl.trim();
    if (base.isEmpty) return null;
    final root = Uri.parse(base);
    var prefix = root.path;
    if (prefix.endsWith('/')) {
      prefix = prefix.substring(0, prefix.length - 1);
    }
    final rel = '${prefix.isEmpty ? '' : prefix}/app/api/status/banner';
    final uri = root.replace(path: rel.startsWith('/') ? rel : '/$rel');
    final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(
      const Duration(seconds: 8),
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    final code = body['code'] as int? ?? -1;
    if (code != 0) return null;
    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;
    final banner = NotifyBanner.fromJson(data);
    if (!banner.active) return null;
    return banner;
  }
}
