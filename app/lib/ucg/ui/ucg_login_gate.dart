import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/session_provider.dart';
import 'widgets/ucg_visual_widgets.dart';

/// UCG 需登录操作的统一门控。
Future<bool> requireUcgLogin(BuildContext context, WidgetRef ref) async {
  if (ref.read(sessionProvider).isLoggedIn) return true;
  if (!context.mounted) return false;
  await context.push('/login');
  return ref.read(sessionProvider).isLoggedIn;
}

/// 未登录占位。
class UcgLoginPrompt extends StatelessWidget {
  const UcgLoginPrompt({super.key, this.message = '登录后即可使用此功能'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return UcgEmptyState(
      icon: Icons.lock_outline_rounded,
      title: message,
      subtitle: '登录后可关注、发帖与聊天',
      action: FilledButton(
        onPressed: () => context.push('/login'),
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        ),
        child: const Text('去登录'),
      ),
    );
  }
}

/// 宝藏占位页。
class UcgTreasurePlaceholder extends StatelessWidget {
  const UcgTreasurePlaceholder({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  Widget build(BuildContext context) {
    return UcgTabPage(
      title: '宝藏',
      subtitle: '精选育儿好物，即将上线',
      leading: ucgBackLeading(context, onBackToFeeding),
      body: const UcgEmptyState(
        icon: Icons.diamond_outlined,
        title: '尚未开通',
        subtitle: '我们正在筹备宝藏内容\n敬请期待',
      ),
    );
  }
}
