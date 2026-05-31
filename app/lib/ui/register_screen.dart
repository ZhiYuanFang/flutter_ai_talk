import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../config/env.dart';
import '../providers/repositories.dart';
import '../providers/toast_bus.dart';
import 'auth/auth_ui.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static final RegExp _accountPattern = RegExp(r'^[a-z0-9_]{4,32}$');

  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  var _loading = false;
  var _obscurePassword = true;
  var _obscureConfirmPassword = true;
  String? _accountError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String _normalizeAccount(String raw) => raw.trim().toLowerCase();

  bool _validateRegisterInputs() {
    final account = _normalizeAccount(_accountCtrl.text);
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    String? accountError;
    String? passwordError;
    String? confirmPasswordError;

    if (!_accountPattern.hasMatch(account)) {
      accountError = '账号需 4-32 位，仅支持 a-z、0-9、_';
    }
    if (password.length < 6 || password.length > 64) {
      passwordError = '密码长度需为 6-64 位';
    }
    if (confirmPassword != password) {
      confirmPasswordError = '确认密码与密码不一致';
    }

    setState(() {
      _accountError = accountError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });
    return accountError == null && passwordError == null && confirmPasswordError == null;
  }

  Future<void> _onRegisterUsername() async {
    if (_loading) return;
    if (!_validateRegisterInputs()) return;

    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.registerUsername(
        _normalizeAccount(_accountCtrl.text),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      ref.showApiToastError('注册成功，请使用账号密码登录');
      final result = <String, String>{
        'account': _normalizeAccount(_accountCtrl.text),
        'password': _passwordCtrl.text,
      };
      if (Navigator.of(context).canPop()) {
        context.pop(result);
      }
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFBF8F3),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _loading ? null : () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new),
                        tooltip: '返回登录',
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            buildAuthBrandHeader(context),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _accountCtrl,
                              enabled: !_loading,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: buildAuthInputDecoration(
                                labelText: '账号',
                                hintText: '4-32 位，仅 a-z0-9_',
                                errorText: _accountError,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordCtrl,
                              enabled: !_loading,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: buildAuthInputDecoration(
                                labelText: '密码',
                                hintText: '6-64 位',
                                errorText: _passwordError,
                                suffixIcon: IconButton(
                                  onPressed:
                                      _loading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordCtrl,
                              enabled: !_loading,
                              obscureText: _obscureConfirmPassword,
                              onSubmitted: (_) => _onRegisterUsername(),
                              decoration: buildAuthInputDecoration(
                                labelText: '确认密码',
                                hintText: '请再次输入密码',
                                errorText: _confirmPasswordError,
                                suffixIcon: IconButton(
                                  onPressed: _loading
                                      ? null
                                      : () => setState(
                                            () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                          ),
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _loading ? null : _onRegisterUsername,
                                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                                child: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('注册账号'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : () => context.pop(),
                                child: const Text('返回登录'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            buildAuthPrivacyAgreement(
                              context,
                              leadText: '注册即代表您已阅读并同意',
                              onTapUserAgreement: () => context.push(
                                Uri(path: '/policy', queryParameters: {'url': AppEnv.userAgreementUrl}).toString(),
                              ),
                              onTapPrivacyPolicy: () => context.push(
                                Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
