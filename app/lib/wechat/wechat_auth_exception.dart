/// 微信取码失败（非用户取消）。
class WeChatAuthException implements Exception {
  WeChatAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 用户在微信内取消授权。
class WeChatAuthCanceledException implements Exception {
  WeChatAuthCanceledException([this.message = '用户已取消']);

  final String message;
}
