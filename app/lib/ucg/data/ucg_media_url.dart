/// UCG 媒体 CDN 拼装（客户端只存/传 objectKey）。
abstract final class UcgMediaUrl {
  static const cdnBase = 'https://resorce.cuplay.top';

  static String objectKeyToCdn(String key) {
    if (key.isEmpty) return '';
    if (key.startsWith('http://') || key.startsWith('https://')) return key;
    final normalized = key.startsWith('/') ? key.substring(1) : key;
    return '$cdnBase/$normalized';
  }
}
