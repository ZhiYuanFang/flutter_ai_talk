import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../config/env.dart';
import '../providers/device_no_notifier.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../providers/toast_bus.dart';
import '../theme/app_theme_scope.dart';
import '../theme/theme_bootstrap_cache.dart';
import '../wechat/wechat_web_redirect.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final RegExp _accountPattern = RegExp(r'^[a-z0-9_]{4,32}$');

  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  var _loading = false;
  var _resumedPendingWebLogin = false;
  var _obscurePassword = true;
  String? _accountError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resumePendingWebWeChatLogin();
    });
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _normalizeAccount(String raw) => raw.trim().toLowerCase();

  bool _validateCredentialInputs() {
    final account = _normalizeAccount(_accountCtrl.text);
    final password = _passwordCtrl.text;
    String? accountError;
    String? passwordError;
    if (!_accountPattern.hasMatch(account)) {
      accountError = '账号需 4-32 位，仅支持 a-z、0-9、_';
    }
    if (password.length < 6 || password.length > 64) {
      passwordError = '密码长度需为 6-64 位';
    }
    setState(() {
      _accountError = accountError;
      _passwordError = passwordError;
    });
    return accountError == null && passwordError == null;
  }

  Future<void> _onUsernameLogin() async {
    if (_loading) return;
    if (!_validateCredentialInputs()) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.signInWithUsernamePassword(
        _normalizeAccount(_accountCtrl.text),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      await _afterLoginSuccess();
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRegisterUsername() async {
    if (_loading) return;
    if (!_validateCredentialInputs()) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.registerUsername(
        _normalizeAccount(_accountCtrl.text),
        _passwordCtrl.text,
      );
      ref.showApiToastError('注册成功，请使用账号密码登录');
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _afterLoginSuccess() async {
    await ref.read(deviceNoNotifierProvider.notifier).refresh();
    ref.invalidate(settingsBabyProvider);
    final baby = await ref.read(settingsRepositoryProvider).loadBaby();
    ref.read(babySexProvider.notifier).state = baby.sex;
    await persistCachedBabySex(baby.sex);
    if (mounted) context.go('/home');
  }

  bool get _canRedirectWebWeChatAuthorize {
    return kIsWeb && AppEnv.wechatOAuthRedirectUri.isNotEmpty && AppEnv.wechatWebAppIdEffective.isNotEmpty;
  }

  Future<void> _resumePendingWebWeChatLogin() async {
    if (!kIsWeb || _resumedPendingWebLogin || !hasPendingWeChatWebCode()) return;
    _resumedPendingWebLogin = true;
    await _onWeChatLogin();
  }

  Future<void> _onWeChatLogin() async {
    if (_loading) return;
    if (_canRedirectWebWeChatAuthorize && !hasPendingWeChatWebCode()) {
      try {
        redirectToWeChatWebAuthorize();
      } on StateError catch (e) {
        ref.showApiToastError(e.message);
      } catch (e) {
        ref.showApiToastError('无法发起微信授权：$e');
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.signInWithWeChat();
      if (!mounted) return;
      await _afterLoginSuccess();
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
    final hintColor = const Color(0xFF8C7E74);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFBF8F3), // 浅米色/大理石底色
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1F9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              offset: const Offset(8, 8),
                              blurRadius: 16,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              offset: const Offset(-8, -8),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '胖宝',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A3428),
                              letterSpacing: 4,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '记录宝宝成长的每一步',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: hintColor),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _accountCtrl,
                        enabled: !_loading,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: '账号',
                          hintText: '4-32 位，仅 a-z0-9_',
                          errorText: _accountError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        enabled: !_loading,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _onUsernameLogin(),
                        decoration: InputDecoration(
                          labelText: '密码',
                          hintText: '6-64 位',
                          errorText: _passwordError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          suffixIcon: IconButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _onUsernameLogin,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('账号密码登录'),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _onRegisterUsername,
                          child: const Text('注册账号'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('或', style: Theme.of(context).textTheme.bodySmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _onWeChatLogin,
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('微信登录'),
                      ),
                      const SizedBox(height: 12),
                      _buildPrivacyAgreement(context),
                      const SizedBox(height: 12),
                      Text(
                        _footerHint(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB0A499),
                        ),
                      ),
                      const Spacer(),
                      if (AppEnv.wxLoginCode.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '开发模式已开启',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyAgreement(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push(
            Uri(path: '/policy', queryParameters: {'url': AppEnv.userAgreementUrl}).toString(),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
              children: [
                const TextSpan(text: '登录即代表您已阅读并同意 '),
                TextSpan(
                  text: '用户协议',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => context.push(
            Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
              children: [
                const TextSpan(text: '和 '),
                TextSpan(
                  text: '隐私政策',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _footerHint() {
    if (_loading && kIsWeb && hasPendingWeChatWebCode()) {
      return '正在继续微信授权登录，请稍候。';
    }
    if (_canRedirectWebWeChatAuthorize) {
      return '说明：支持账号密码与微信登录；网页端微信会跳转授权页面。';
    }
    if (AppEnv.wechatAppId.isNotEmpty) {
      return '说明：支持账号密码登录；也可在已安装微信的手机上授权登录。';
    }
    if (AppEnv.wxLoginCode.isNotEmpty) {
      return '说明：支持账号密码登录；检测到微信联调凭证，可验证微信链路。';
    }
    return '说明：支持账号密码登录；微信登录需先配置微信开放平台参数。';
  }
}
