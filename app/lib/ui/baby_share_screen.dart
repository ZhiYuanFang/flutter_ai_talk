import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/baby_age.dart';
import '../data/baby_share_qr_payload.dart';
import '../providers/device_no_notifier.dart';
import '../providers/settings_baby.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'widgets/settings_glass_panel.dart';

/// 出示宝宝共享二维码：家人扫码/相册识码后可绑定同一宝宝。
/// 不展示 ID；不提供保存/分享图片。
class BabyShareScreen extends ConsumerWidget {
  const BabyShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = visualTokensOf(context);
    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd =
        Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;
    final onShell = AppColor.textPrimary(context);

    final deviceNo =
        ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
    final baby = ref.watch(settingsBabyProvider).asData?.value;
    final nickname = displayBabyNickname(baby);
    final payload =
        deviceNo.isEmpty ? '' : BabyShareQrPayload.encode(deviceNo);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('邀请家人'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: deviceNo.isEmpty || payload.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '请先绑定宝宝后再出示共享码',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onShell.withValues(alpha: 0.8)),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Text(
                      '邀请家人看护「$nickname」',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: onShell,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '家人打开胖宝 → 绑定宝宝 → 扫一扫或从相册选码',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: onShell.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SettingsGlassPanel(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          children: [
                            // 白底保证扫码对比度，与壳主题无关
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: payload,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '请只出示给信任的家人',
                              style: TextStyle(
                                fontSize: 12,
                                color: onShell.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '对方新注册账号后，在「绑定宝宝」里用相机扫此码，或选择相册里的截图即可同步喂养与预测。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: onShell.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
