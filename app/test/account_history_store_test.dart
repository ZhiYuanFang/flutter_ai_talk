import 'package:flutter_test/flutter_test.dart';
import 'package:pangbao_app/session/account_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('记忆账号仅保留最近3个且去重', () async {
    await pushRecentAccount('user_a');
    await pushRecentAccount('user_b');
    await pushRecentAccount('user_a');
    await pushRecentAccount('user_c');
    await pushRecentAccount('user_d');

    final recent = await loadRecentAccounts();
    expect(recent, ['user_d', 'user_c', 'user_a']);
  });
}
