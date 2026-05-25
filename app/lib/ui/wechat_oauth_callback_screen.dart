import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/toast_bus.dart';
import '../wechat/wechat_web_redirect.dart';

/// Web 微信 OAuth 回调：解析 query，写入 sessionStorage 后进入登录页。
class WeChatOAuthCallbackScreen extends ConsumerStatefulWidget {
  const WeChatOAuthCallbackScreen({super.key});

  @override
  ConsumerState<WeChatOAuthCallbackScreen> createState() => _WeChatOAuthCallbackScreenState();
}

class _WeChatOAuthCallbackScreenState extends ConsumerState<WeChatOAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      handleWeChatOAuthCallbackQuery(uri);
      final err = consumeWeChatOAuthCallbackError();
      if (err != null && err.isNotEmpty) {
        ref.showApiToastError(_messageForOAuthError(err));
      }
      if (mounted) context.go('/login');
    });
  }

  String _messageForOAuthError(String err) {
    return switch (err) {
      'access_denied' => '已取消微信授权',
      'state_mismatch' => '授权状态校验失败，请重试',
      'missing_code' => '未收到微信授权码',
      _ => '微信授权失败：$err',
    };
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
