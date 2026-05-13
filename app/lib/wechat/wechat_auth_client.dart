/// 从微信开放平台流程取得临时 `code`（作为网关登录请求体 `jsCode` 提交）。
abstract class WeChatAuthClient {
  /// 成功返回微信临时 `code`（网关字段 `jsCode`）；用户取消抛出 [WeChatAuthCanceledException]；其它失败抛出 [WeChatAuthException]。
  Future<String> obtainWxCode();
}
