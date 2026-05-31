import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
