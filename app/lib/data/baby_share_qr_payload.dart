/// 宝宝全家共享二维码载荷：`pangbao:baby:<deviceNo>`。
/// 对用户隐藏 ID 概念；协议层仍用 deviceNo。
abstract final class BabyShareQrPayload {
  static const prefix = 'pangbao:baby:';

  /// 非法 / 非本产品码时的统一用户文案。
  static const invalidMessage = '不是有效的宝宝共享码';

  /// 编码：写入二维码的字符串。
  static String encode(String deviceNo) {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return '';
    return '$prefix$dn';
  }

  /// 解码：成功返回 trim 后的 deviceNo；失败返回 null。
  static String? tryDecode(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return null;
    if (!t.startsWith(prefix)) return null;
    final dn = t.substring(prefix.length).trim();
    if (dn.isEmpty) return null;
    return dn;
  }
}
