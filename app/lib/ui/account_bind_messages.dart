import '../api/api_exceptions.dart';

/// 将账号绑定冲突的后端文案映射为用户可理解的提示。
String bindConflictMessage(Object error) {
  if (error is ApiBusinessException) {
    final msg = error.message;
    if (msg.contains('无法合并') ||
        msg.contains('已绑定其他') ||
        msg.contains('Apple 账号已绑定') ||
        msg.contains('微信已绑定其他')) {
      return '无法合并两个已独立创建的账号，请使用原登录方式进入对应账号';
    }
    return msg;
  }
  return error.toString();
}
