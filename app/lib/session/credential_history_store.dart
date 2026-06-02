import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kCredentialHistoryLimit = 5;

const _kRecentAccountsKeyV2 = 'pangbao_recent_accounts_v2';
const _kRecentAccountsKeyV1 = 'pangbao_recent_accounts_v1';
const _kPasswordKeyPrefix = 'pangbao_cred_pw_v1_';

/// iOS Keychain + Android Keystore；写入/读取失败时降级为仅记账号，不阻断登录。
const _kSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    preferencesKeyPrefix: 'pangbao',
  ),
  iOptions: IOSOptions(),
);

@immutable
class CredentialEntry {
  const CredentialEntry({
    required this.account,
    this.password,
  });

  final String account;
  final String? password;

  bool get hasPassword => password != null && password!.isNotEmpty;
}

FlutterSecureStorage _storageFor({FlutterSecureStorage? override}) =>
    override ?? _kSecureStorage;

String _passwordKey(String account) => '$_kPasswordKeyPrefix$account';

String _normalizeAccount(String raw) => raw.trim().toLowerCase();

Future<void> _writePassword(
  FlutterSecureStorage secure,
  String account,
  String password,
) async {
  if (password.isEmpty) return;
  try {
    await secure.write(key: _passwordKey(account), value: password);
  } on MissingPluginException {
    // 原生插件未注册（常见于 hot reload）；账号顺序仍可用。
  } on PlatformException {
    // Android/iOS 安全存储暂不可用时忽略。
  }
}

Future<String?> _readPassword(
  FlutterSecureStorage secure,
  String account,
) async {
  try {
    final value = await secure.read(key: _passwordKey(account));
    if (value == null || value.isEmpty) return null;
    return value;
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

Future<void> _deletePassword(
  FlutterSecureStorage secure,
  String account,
) async {
  try {
    await secure.delete(key: _passwordKey(account));
  } on MissingPluginException {
    // no-op
  } on PlatformException {
    // no-op
  }
}

List<String> _sanitizeAccountOrder(List<String> raw, {required int limit}) {
  final seen = <String>{};
  final out = <String>[];

  for (final e in raw) {
    final v = _normalizeAccount(e);
    if (v.isEmpty || seen.contains(v)) continue;
    seen.add(v);
    out.add(v);
    if (out.length >= limit) break;
  }
  return out;
}

Future<void> _migrateV1AccountsIfNeeded(SharedPreferences prefs) async {
  final v2 = prefs.getStringList(_kRecentAccountsKeyV2);
  if (v2 != null && v2.isNotEmpty) return;

  final v1 = prefs.getStringList(_kRecentAccountsKeyV1);
  if (v1 == null || v1.isEmpty) return;

  final migrated = _sanitizeAccountOrder(v1, limit: kCredentialHistoryLimit);
  if (migrated.isEmpty) return;
  await prefs.setStringList(_kRecentAccountsKeyV2, migrated);
}

Future<List<String>> _loadAccountOrder() async {
  final prefs = await SharedPreferences.getInstance();
  await _migrateV1AccountsIfNeeded(prefs);
  final raw = prefs.getStringList(_kRecentAccountsKeyV2) ?? const <String>[];
  return _sanitizeAccountOrder(raw, limit: kCredentialHistoryLimit);
}

Future<void> _persistAccountOrder(List<String> order) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_kRecentAccountsKeyV2, order);
}

Future<String?> readPasswordForAccount(
  String account, {
  FlutterSecureStorage? secureStorage,
}) async {
  final normalized = _normalizeAccount(account);
  if (normalized.isEmpty) return null;
  return _readPassword(_storageFor(override: secureStorage), normalized);
}

Future<List<CredentialEntry>> loadCredentialEntries({
  FlutterSecureStorage? secureStorage,
}) async {
  final secure = _storageFor(override: secureStorage);
  final order = await _loadAccountOrder();
  final entries = <CredentialEntry>[];
  for (final account in order) {
    final password = await _readPassword(secure, account);
    entries.add(CredentialEntry(account: account, password: password));
  }
  return entries;
}

Future<List<CredentialEntry>> bumpAccountOrder(
  String account, {
  FlutterSecureStorage? secureStorage,
}) async {
  final normalized = _normalizeAccount(account);
  if (normalized.isEmpty) return loadCredentialEntries(secureStorage: secureStorage);

  final order = await _loadAccountOrder();
  final merged = [normalized, ...order.where((e) => e != normalized)];
  final nextOrder = _sanitizeAccountOrder(merged, limit: kCredentialHistoryLimit);
  await _persistAccountOrder(nextOrder);
  return loadCredentialEntries(secureStorage: secureStorage);
}

/// 成功登录后记住账号顺序；密码写入 Keychain/Keystore（失败时不抛错）。
Future<List<CredentialEntry>> rememberSuccessfulLogin(
  String account,
  String password, {
  FlutterSecureStorage? secureStorage,
}) async {
  final normalized = _normalizeAccount(account);
  if (normalized.isEmpty) return loadCredentialEntries(secureStorage: secureStorage);

  final secure = _storageFor(override: secureStorage);
  final order = await _loadAccountOrder();
  final merged = [normalized, ...order.where((e) => e != normalized)];
  final nextOrder = _sanitizeAccountOrder(merged, limit: kCredentialHistoryLimit);
  await _persistAccountOrder(nextOrder);
  await _writePassword(secure, normalized, password);

  final dropped = order.where((e) => !nextOrder.contains(e));
  for (final droppedAccount in dropped) {
    await _deletePassword(secure, droppedAccount);
  }

  return loadCredentialEntries(secureStorage: secureStorage);
}

Future<void> removePassword(
  String account, {
  FlutterSecureStorage? secureStorage,
}) async {
  final normalized = _normalizeAccount(account);
  if (normalized.isEmpty) return;
  await _deletePassword(_storageFor(override: secureStorage), normalized);
}

Future<void> removeAccount(
  String account, {
  FlutterSecureStorage? secureStorage,
}) async {
  final normalized = _normalizeAccount(account);
  if (normalized.isEmpty) return;

  final secure = _storageFor(override: secureStorage);
  final order = await _loadAccountOrder();
  if (!order.contains(normalized)) {
    await _deletePassword(secure, normalized);
    return;
  }
  final nextOrder = order.where((e) => e != normalized).toList();
  await _persistAccountOrder(nextOrder);
  await _deletePassword(secure, normalized);
}
