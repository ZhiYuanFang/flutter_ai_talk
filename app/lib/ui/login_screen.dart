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
  final _deviceNoCtrl = TextEditingController();
  var _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearWebWeChatResidual();
    });
  }

  @override
  void dispose() {
    _deviceNoCtrl.dispose();
    super.dispose();
  }

  /// Web：不再自动走微信登录；若存在残留 OAuth code，清除并提示使用胖宝号。
  void _clearWebWeChatResidual() {
    if (!kIsWeb) return;
    final had = hasPendingWeChatWebCode();
    clearPendingWeChatWebOAuthStorage();
    if (had) {
      ref.showApiToast('请使用胖宝号登录');
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

  Future<void> _onDeviceLogin() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.signInWithDeviceNo(_deviceNoCtrl.text);
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

  void _onWeChatLoginStub() {
    ref.showApiToast('当前功能未开放');
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
              '胖宝号登录',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deviceNoCtrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onDeviceLogin(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '胖宝号（deviceNo）',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _onDeviceLogin,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('登录'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loading ? null : _onWeChatLoginStub,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('微信登录'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push(
                Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
              ),
              child: const Text('请阅读并同意隐私政策'),
            ),
            const Spacer(),
            Text(
              _footerHint(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _footerHint() {
    if (kIsWeb && AppEnv.wechatOAuthRedirectUri.isNotEmpty && AppEnv.wechatWebAppIdEffective.isNotEmpty) {
      return '说明：默认使用胖宝号登录；微信登录暂未开放。';
    }
    if (AppEnv.wechatAppId.isNotEmpty) {
      return '说明：默认使用胖宝号登录；微信登录暂未开放。';
    }
    if (AppEnv.wxLoginCode.isNotEmpty) {
      return '说明：默认使用胖宝号登录；微信联调入口已关闭。';
    }
    return '说明：请输入网关下发的胖宝号（deviceNo）完成登录。';
  }
}
