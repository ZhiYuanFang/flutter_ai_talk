import 'package:shared_preferences/shared_preferences.dart';

const _kRecentAccountsKey = 'pangbao_recent_accounts_v1';

Future<List<String>> loadRecentAccounts({int limit = 3}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_kRecentAccountsKey) ?? const <String>[];
  return _sanitizeAccounts(raw, limit: limit);
}

Future<List<String>> pushRecentAccount(String account, {int limit = 3}) async {
  final normalized = account.trim().toLowerCase();
  if (normalized.isEmpty) return loadRecentAccounts(limit: limit);

  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_kRecentAccountsKey) ?? const <String>[];
  final merged = [normalized, ...raw];
  final sanitized = _sanitizeAccounts(merged, limit: limit);
  await prefs.setStringList(_kRecentAccountsKey, sanitized);
  return sanitized;
}

List<String> _sanitizeAccounts(List<String> raw, {required int limit}) {
  final seen = <String>{};
  final out = <String>[];

  for (final e in raw) {
    final v = e.trim().toLowerCase();
    if (v.isEmpty || seen.contains(v)) continue;
    seen.add(v);
    out.add(v);
    if (out.length >= limit) break;
  }
  return out;
}
