// UCG 媒体 CDN 拼装（客户端只存/传 objectKey；展示优先 API `cdnUrl`）。
abstract final class UcgMediaUrl {
  static const cdnBase = 'https://resorce.cuplay.top';

  static String objectKeyToCdn(String key) {
    if (key.isEmpty) return '';
    if (key.startsWith('http://') || key.startsWith('https://')) return key;
    final normalized = key.startsWith('/') ? key.substring(1) : key;
    return '$cdnBase/$normalized';
  }

  /// 展示 URL：API [cdnUrl] 与 [objectKey] 路径一致时采用；否则按 objectKey 拼装。
  static String resolveUrl({required String objectKey, String? cdnUrl}) {
    if (objectKey.startsWith('http://') || objectKey.startsWith('https://')) {
      return objectKey;
    }
    final canonical = objectKeyToCdn(objectKey);
    final fromApi = cdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty && _cdnUrlPathMatchesObjectKey(fromApi, objectKey)) {
      return fromApi;
    }
    return canonical;
  }

  static bool _cdnUrlPathMatchesObjectKey(String cdnUrl, String objectKey) {
    if (objectKey.isEmpty) return true;
    final uri = Uri.tryParse(cdnUrl);
    if (uri == null) return false;
    if (uri.query.isNotEmpty) return false;
    final key = objectKey.startsWith('/') ? objectKey.substring(1) : objectKey;
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return path == key;
  }

  /// 视频内联/全屏播放 URL：始终取原始 MP4 object，忽略 API `cdnUrl` 上的 `x-oss-process` 快照参数。
  static String videoPlayUrl({required String objectKey, String? cdnUrl}) {
    if (objectKey.startsWith('http://') || objectKey.startsWith('https://')) {
      return normalizeVideoPlayUrl(objectKey);
    }
    return objectKeyToCdn(objectKey);
  }

  /// 去掉 `.mp4` URL 上的 OSS 处理 query（避免请求到 JPEG 快照）。
  static String normalizeVideoPlayUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.query.isEmpty) return url.trim();
    if (!uri.path.toLowerCase().endsWith('.mp4')) return url.trim();
    return uri.replace(queryParameters: {}, fragment: '').toString();
  }

  /// 全分辨率原图/原视频 URL（lightbox、内联播放等交互场景）。
  static String fullUrl({required String objectKey, String? cdnUrl}) =>
      resolveUrl(objectKey: objectKey, cdnUrl: cdnUrl);

  /// 列表缩略图 URL：仅用 API 字段；缺失时回退 [fullUrl]。
  static String thumbnailUrl({
    required String objectKey,
    String? cdnUrl,
    String? apiThumbnailUrl,
    String? apiThumbKey,
  }) {
    final fromApi = apiThumbnailUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;

    final thumbKey = apiThumbKey?.trim();
    if (thumbKey != null && thumbKey.isNotEmpty) {
      return objectKeyToCdn(thumbKey);
    }

    return fullUrl(objectKey: objectKey, cdnUrl: cdnUrl);
  }
}
