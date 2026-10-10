import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/authorized_api_client_provider.dart';
import '../providers/feature_unlock_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/ui/widgets/ucg_media_viewer.dart';
import 'feature_unlock/invite_code_howto_screen.dart';
import 'widgets/settings_glass_panel.dart';

/// 「如何购买小智音箱」：自购说明 + 复用 catalog 群二维码进群咨询。
class XiaozhiSpeakerBuyHowtoScreen extends ConsumerStatefulWidget {
  const XiaozhiSpeakerBuyHowtoScreen({super.key});

  @override
  ConsumerState<XiaozhiSpeakerBuyHowtoScreen> createState() =>
      _XiaozhiSpeakerBuyHowtoScreenState();
}

class _XiaozhiSpeakerBuyHowtoScreenState
    extends ConsumerState<XiaozhiSpeakerBuyHowtoScreen> {
  @override
  void initState() {
    super.initState();
    // 拉取 catalog 以取得 inviteGroupQrUrl（与邀请码 howto 同源）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(featureCatalogStateProvider.notifier).ensureLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = visualTokensOf(context);
    final scheme = Theme.of(context).colorScheme;
    final onShell = tokens?.onShell ?? AppColor.textPrimary(context);
    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd =
        Color.lerp(bgStart, scheme.primaryContainer, 0.35) ?? scheme.surface;
    final catalog = ref.watch(featureCatalogStateProvider);
    final apiBase = ref.watch(authorizedApiClientProvider).baseUrl;
    final qrUrl = resolveInviteGroupQrUrl(catalog.inviteGroupQrUrl, apiBase);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('如何购买小智音箱'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SettingsGlassPanel(
                child: Text(
                  '使用「小智音箱」绑定前，请自行采购兼容的小智硬件。App 仅提供开通与绑定，不包含音箱销售。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: onShell.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SettingsGlassPanel(
                child: Text(
                  '不确定型号或购买渠道时，可扫码加入官方微信群咨询。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: onShell.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (qrUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BuyGroupQrBlock(qrUrl: qrUrl, onShell: onShell),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 进群咨询购买：文案在图上方；加载失败隐藏整块。
class _BuyGroupQrBlock extends StatefulWidget {
  const _BuyGroupQrBlock({
    required this.qrUrl,
    required this.onShell,
  });

  final String qrUrl;
  final Color onShell;

  @override
  State<_BuyGroupQrBlock> createState() => _BuyGroupQrBlockState();
}

class _BuyGroupQrBlockState extends State<_BuyGroupQrBlock> {
  var _loadFailed = false;

  @override
  void didUpdateWidget(covariant _BuyGroupQrBlock oldWidget) {
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
            '扫码加入官方微信群，咨询购买',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.onShell.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
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
