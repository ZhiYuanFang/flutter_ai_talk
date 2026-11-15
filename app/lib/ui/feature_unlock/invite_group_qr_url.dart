/// 将 catalog 相对/绝对 `inviteGroupQrUrl` 解析为可加载地址。
String resolveInviteGroupQrUrl(String raw, String apiBaseUrl) {
  final u = raw.trim();
  if (u.isEmpty) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final base = Uri.tryParse(apiBaseUrl.trim());
  if (base == null || !base.hasScheme) return u;
  return base.resolve(u.startsWith('/') ? u : '/$u').toString();
}
