import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pangbao_app/session/credential_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FlutterSecureStorage secureStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStorage = const FlutterSecureStorage();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('成功登录凭据保留最近5个且去重', () async {
    await rememberSuccessfulLogin('user_a', 'pass_a', secureStorage: secureStorage);
    await rememberSuccessfulLogin('user_b', 'pass_b', secureStorage: secureStorage);
    await rememberSuccessfulLogin('user_a', 'pass_a2', secureStorage: secureStorage);
    await rememberSuccessfulLogin('user_c', 'pass_c', secureStorage: secureStorage);
    await rememberSuccessfulLogin('user_d', 'pass_d', secureStorage: secureStorage);
    await rememberSuccessfulLogin('user_e', 'pass_e', secureStorage: secureStorage);
    await rememberSuccessfulLogin('user_f', 'pass_f', secureStorage: secureStorage);

    final entries = await loadCredentialEntries(secureStorage: secureStorage);
    expect(entries.map((e) => e.account), ['user_f', 'user_e', 'user_d', 'user_c', 'user_a']);
    expect(entries.first.password, 'pass_f');
    expect(
      await secureStorage.read(key: 'pangbao_cred_pw_v1_user_b'),
      isNull,
    );
    expect(
      await secureStorage.read(key: 'pangbao_cred_pw_v1_user_a'),
      'pass_a2',
    );
  });

  test('removePassword 仅清除密码保留顺序', () async {
    await rememberSuccessfulLogin('user_a', 'pass_a', secureStorage: secureStorage);
    await removePassword('user_a', secureStorage: secureStorage);

    final entries = await loadCredentialEntries(secureStorage: secureStorage);
    expect(entries.length, 1);
    expect(entries.first.account, 'user_a');
    expect(entries.first.password, isNull);
  });

  test('removeAccount 清除顺序与密码', () async {
    await rememberSuccessfulLogin('user_a', 'pass_a', secureStorage: secureStorage);
    await rememberSuccessfulLogin('user_b', 'pass_b', secureStorage: secureStorage);
    await removeAccount('user_a', secureStorage: secureStorage);

    final entries = await loadCredentialEntries(secureStorage: secureStorage);
    expect(entries.map((e) => e.account), ['user_b']);
    expect(
      await secureStorage.read(key: 'pangbao_cred_pw_v1_user_a'),
      isNull,
    );
  });

  test('rememberSuccessfulLogin 在安全存储失败时仍保留账号顺序', () async {
    await rememberSuccessfulLogin('user_a', 'pass_a');
    final entries = await loadCredentialEntries();
    expect(entries.map((e) => e.account), ['user_a']);
  });
}
