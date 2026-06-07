// UCG 媒体 CDN 拼装（客户端只存/传 objectKey；展示优先 API `cdnUrl`）。
abstract final class UcgMediaUrl {
  static const cdnBase = 'https://resorce.cuplay.top';

  static String objectKeyToCdn(String key) {
    if (key.isEmpty) return '';
    if (key.startsWith('http://') || key.startsWith('https://')) return key;
    final normalized = key.startsWith('/') ? key.substring(1) : key;
    return '$cdnBase/$normalized';
  }

  /// 优先 API 返回的 [cdnUrl]，缺失时由 [objectKey] 拼装 CDN 地址。
  static String resolveUrl({required String objectKey, String? cdnUrl}) {
    final fromApi = cdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return objectKeyToCdn(objectKey);
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
