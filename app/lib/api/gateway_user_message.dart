/// 将网关/WS 后端原文映射为用户可见的宝宝语义文案。
String normalizeUserFacingApiMessage(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  if (t.contains('设备未注册') || t.contains('请先注册设备号')) {
    return '宝宝ID未绑定';
  }
  if (t.contains('未绑定设备') && t.contains('历史推送')) {
    return '请先绑定宝宝信息后重试';
  }
  return raw;
}
