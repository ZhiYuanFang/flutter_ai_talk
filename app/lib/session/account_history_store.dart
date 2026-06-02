import 'credential_history_store.dart';

/// 兼容旧调用：仅返回账号顺序（不含密码）。
Future<List<String>> loadRecentAccounts({int limit = kCredentialHistoryLimit}) async {
  final entries = await loadCredentialEntries();
  return entries.map((e) => e.account).take(limit).toList();
}

Future<List<String>> pushRecentAccount(String account, {int limit = kCredentialHistoryLimit}) async {
  final entries = await bumpAccountOrder(account);
  return entries.map((e) => e.account).take(limit).toList();
}
