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
      appBar: AppBar(title: const Text('胖宝')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Text(
              '微信登录',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _footerHint(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _onWeChatLogin,
              icon: const Icon(Icons.chat_outlined),
              label: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('使用微信登录'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push(
                Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
              ),
              child: const Text('请阅读并同意隐私政策'),
            ),
            const Spacer(),
            if (AppEnv.wxLoginCode.isNotEmpty)
              Text(
                '开发提示：已检测到 WX_LOGIN_CODE，可用于微信登录联调。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
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
