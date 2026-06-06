/// UCG 媒体 CDN 拼装（客户端只存/传 objectKey；展示优先 API `cdnUrl`）。
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
}
