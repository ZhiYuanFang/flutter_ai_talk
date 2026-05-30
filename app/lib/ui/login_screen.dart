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
  var _loading = false;
  var _resumedPendingWebLogin = false;

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
    super.dispose();
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo section
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/splash_logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '胖宝',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '记录宝宝成长的每一步',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const Spacer(flex: 3),
                // Login Button
                FilledButton.icon(
                  onPressed: _loading ? null : _onWeChatLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF07C160), // WeChat Green
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: _loading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.chat_bubble, size: 24),
                  label: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '微信安全登录',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 20),
                // Privacy info
                _buildPrivacyAgreement(context),
                const SizedBox(height: 16),
                Text(
                  _footerHint(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black38),
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
      ),
    );
  }

  Widget _buildPrivacyAgreement(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
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
            const TextSpan(text: ' 和 '),
            TextSpan(
              text: '隐私政策',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _footerHint() {
    if (_loading && kIsWeb && hasPendingWeChatWebCode()) {
      return '正在继续微信授权登录，请稍候。';
    }
    if (_canRedirectWebWeChatAuthorize) {
      return '说明：当前仅支持微信登录；网页端将跳转到微信授权页面。';
    }
    if (AppEnv.wechatAppId.isNotEmpty) {
      return '说明：当前仅支持微信登录；请在已安装微信的设备上完成授权。';
    }
    if (AppEnv.wxLoginCode.isNotEmpty) {
      return '说明：当前仅支持微信登录；检测到联调凭证，可继续验证登录链路。';
    }
    return '说明：当前仅支持微信登录；请先配置微信开放平台参数。';
  }
}
