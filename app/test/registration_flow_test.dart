import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pangbao_app/data/repositories.dart';
import 'package:pangbao_app/data/user_account_profile.dart';
import 'package:pangbao_app/providers/repositories.dart';
import 'package:pangbao_app/ui/login_screen.dart';
import 'package:pangbao_app/ui/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  final List<(String, String)> registerCalls = [];

  @override
  Future<void> registerUsername(String account, String password) async {
    registerCalls.add((account, password));
  }

  @override
  Future<void> bindUsernameDevice(String deviceNo) async => throw UnimplementedError();

  @override
  Future<void> bindUsernameWx({required String jsCode, String? platform}) async =>
      throw UnimplementedError();

  @override
  Future<void> changeUsernamePassword({required String oldPassword, required String newPassword}) async =>
      throw UnimplementedError();

  @override
  Future<void> createUsernameForWx(String account, String password) async => throw UnimplementedError();

  @override
  Future<void> deactivateAccount() async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> loginUsernameBusiness(String account, String password) async =>
      throw UnimplementedError();

  @override
  Future<void> signInWithUsernamePassword(String account, String password) async =>
      throw UnimplementedError();

  @override
  Future<void> signInWithWeChat() async => throw UnimplementedError();

  @override
  Future<UserAccountProfile> fetchUserProfile() async =>
      const UserAccountProfile(account: '', isWxBound: false, isAppleBound: false, authProviders: []);

  @override
  Future<void> signOut() async => throw UnimplementedError();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('点击登录页注册账号会进入独立注册页', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/policy', builder: (_, __) => const SizedBox.shrink()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('注册账号'));
    await tester.pumpAndSettle();

    expect(find.text('确认密码'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('注册页确认密码不一致时阻止提交并显示错误', (tester) async {
    final fakeAuth = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '账号'), 'hello_user');
    await tester.enterText(find.widgetWithText(TextField, '密码'), 'abc12345');
    await tester.enterText(find.widgetWithText(TextField, '确认密码'), 'abc12346');
    await tester.tap(find.text('注册账号'));
    await tester.pumpAndSettle();

    expect(find.text('确认密码与密码不一致'), findsOneWidget);
    expect(fakeAuth.registerCalls, isEmpty);
  });

  testWidgets('注册页确认密码一致时允许提交', (tester) async {
    final fakeAuth = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '账号'), 'hello_user');
    await tester.enterText(find.widgetWithText(TextField, '密码'), 'abc12345');
    await tester.enterText(find.widgetWithText(TextField, '确认密码'), 'abc12345');
    await tester.tap(find.text('注册账号'));
    await tester.pumpAndSettle();

    expect(fakeAuth.registerCalls.length, 1);
    expect(fakeAuth.registerCalls.first.$1, 'hello_user');
    expect(fakeAuth.registerCalls.first.$2, 'abc12345');
  });

  testWidgets('注册成功返回登录页后自动回填账号和密码', (tester) async {
    final fakeAuth = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/policy', builder: (_, __) => const SizedBox.shrink()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('注册账号').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '账号'), 'hello_user');
    await tester.enterText(find.widgetWithText(TextField, '密码'), 'abc12345');
    await tester.enterText(find.widgetWithText(TextField, '确认密码'), 'abc12345');
    await tester.tap(find.text('注册账号').first);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final accountField = tester.widget<TextField>(find.widgetWithText(TextField, '账号'));
    final passwordField = tester.widget<TextField>(find.widgetWithText(TextField, '密码'));

    expect(accountField.controller?.text, 'hello_user');
    expect(passwordField.controller?.text, 'abc12345');
    expect(find.text('hello_user'), findsWidgets);
  });
}
