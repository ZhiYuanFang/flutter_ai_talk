import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/session_provider.dart';
import '../../session/token_expiry.dart';
import '../providers/ucg_providers.dart';
import 'widgets/ucg_visual_widgets.dart';

/// UCG 需登录操作的统一门控。
Future<bool> requireUcgLogin(BuildContext context, WidgetRef ref) async {
  if (ref.read(sessionProvider).isLoggedIn) return true;
  if (!context.mounted) return false;
  await context.push('/login');
  return ref.read(sessionProvider).isLoggedIn;
}

/// UCG 需已绑定微信账号（JWT `sub` 非零）；设备态已登录但 `sub=0` 时展示绑定提示。
Future<bool> requireUcgWxAccount(BuildContext context, WidgetRef ref) async {
  if (!ref.read(sessionProvider).isLoggedIn) {
    return requireUcgLogin(context, ref);
  }
  final wxId = ref.read(ucgCurrentUserIdProvider);
  if (isUcgWxAccountBound(wxId)) return true;
  if (!context.mounted) return false;
  await showAdaptiveDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('需要绑定微信'),
      content: const Text('请先绑定微信账号后再使用社区功能'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            ctx.push('/login');
          },
          child: const Text('去绑定'),
        ),
      ],
    ),
  );
  return isUcgWxAccountBound(ref.read(ucgCurrentUserIdProvider));
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

/// 设备态（`sub=0`）占位：已设备登录但未绑微信。
class UcgWxBindPrompt extends StatelessWidget {
  const UcgWxBindPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return UcgEmptyState(
      icon: Icons.wechat_outlined,
      title: '请先绑定微信账号后再使用社区功能',
      subtitle: '绑定后可发帖、互动与私信',
      action: FilledButton(
        onPressed: () => context.push('/login'),
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        ),
        child: const Text('去绑定'),
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
