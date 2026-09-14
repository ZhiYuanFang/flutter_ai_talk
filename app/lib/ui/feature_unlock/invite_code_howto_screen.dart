import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/client_usage_events.dart';
import '../../providers/authorized_api_client_provider.dart';
import '../../providers/client_usage_provider.dart';
import '../../providers/feature_unlock_provider.dart';
import '../../providers/home_pager.dart';
import '../../theme/app_visual_tokens.dart';
import '../../ucg/ui/widgets/ucg_media_viewer.dart';
import '../widgets/settings_glass_panel.dart';

/// 将 catalog 相对/绝对 `inviteGroupQrUrl` 解析为可加载地址。
String resolveInviteGroupQrUrl(String raw, String apiBaseUrl) {
  final u = raw.trim();
  if (u.isEmpty) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final base = Uri.tryParse(apiBaseUrl.trim());
  if (base == null || !base.hasScheme) return u;
  return base.resolve(u.startsWith('/') ? u : '/$u').toString();
}

/// 「如何获取邀请码」：来源说明 + 进广场 + 条件微信群二维码。
class InviteCodeHowtoScreen extends ConsumerStatefulWidget {
  const InviteCodeHowtoScreen({super.key});

  @override
  ConsumerState<InviteCodeHowtoScreen> createState() =>
      _InviteCodeHowtoScreenState();
}

class _InviteCodeHowtoScreenState extends ConsumerState<InviteCodeHowtoScreen> {
  @override
  void initState() {
    super.initState();
    // 确保 catalog（含群二维码 URL）已加载。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
    });
  }

  void _enterSquare() {
    // 清掉 howto / 开通中心栈，落到主壳 UCG 页（未合格由资格壳拦住）。
    ref.read(homePagerRequestProvider.notifier).requestPage(HomePagerPage.ucg);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final onShell = tokens?.onShell ?? scheme.onSurface;
    final shell = tokens?.shellColor ?? scheme.surface;
    final catalog = ref.watch(featureCatalogStateProvider);
    final apiBase = ref.watch(authorizedApiClientProvider).baseUrl;
    final qrUrl =
        resolveInviteGroupQrUrl(catalog.inviteGroupQrUrl, apiBase);

    return ClientUsageShowOnce(
      event: ClientUsageEvents.inviteHowtoShow,
      child: Scaffold(
      backgroundColor: shell,
      appBar: AppBar(
        backgroundColor: shell,
        foregroundColor: onShell,
        title: const Text('如何获取邀请码'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SettingsGlassPanel(
            child: Text(
              '每个激活广场的用户都可以在「广场 → 我的」中查看自己的邀请码，供他人激活使用。',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: onShell.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingsGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '1. 进入广场向其它用户获取邀请码',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: onShell.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '在广场与其它用户交流，向对方索取邀请码。',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: onShell.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _enterSquare,
                  child: const Text('进入广场'),
                ),
              ],
            ),
          ),
          if (qrUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InviteGroupQrBlock(qrUrl: qrUrl, onShell: onShell),
          ],
        ],
      ),
    ),
    );
  }
}

/// 微信群二维码：文案在图正上方；加载失败则整块不渲染。
class _InviteGroupQrBlock extends StatefulWidget {
  const _InviteGroupQrBlock({
    required this.qrUrl,
    required this.onShell,
  });

  final String qrUrl;
  final Color onShell;

  @override
  State<_InviteGroupQrBlock> createState() => _InviteGroupQrBlockState();
}

class _InviteGroupQrBlockState extends State<_InviteGroupQrBlock> {
  /// 图片加载失败后隐藏整块（含文案），避免「有标题无图」。
  var _loadFailed = false;

  @override
  void didUpdateWidget(covariant _InviteGroupQrBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrUrl != widget.qrUrl) {
      _loadFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) return const SizedBox.shrink();
    return SettingsGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '2. 加入官方微信群，向其它用户获取邀请码',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.onShell.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          // 仅图可点：打开全屏可缩放预览，便于微信扫码。
          Center(
            child: GestureDetector(
              onTap: () => unawaited(
                showUcgPhotoLightbox(context, urls: [widget.qrUrl]),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.qrUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    // 首帧 errorBuilder 在 build 内，延后 setState 避免同步重建冲突。
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_loadFailed) {
                        setState(() => _loadFailed = true);
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
