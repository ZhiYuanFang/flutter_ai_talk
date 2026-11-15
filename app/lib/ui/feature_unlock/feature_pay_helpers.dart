import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/feature_unlock_models.dart';
import '../../theme/app_color.dart';
import '../home_history_edit_glass_panel.dart';
import '../widgets/app_glass_overlay.dart';
import '../widgets/feature_logo.dart';

/// 分 → 展示用元字符串（两位小数）。
String formatVipFenYuan(int fen) {
  final yuan = fen / 100.0;
  return yuan.toStringAsFixed(2);
}

/// 免费体验确认：每位用户仅一次；确认后由调用方发起 trial。
Future<bool> confirmFreeTrialDialog({
  required BuildContext context,
  required FeatureCatalogItem? feature,
  String title = '免费体验',
}) async {
  final ok = await showGlassConfirmDialog(
    context,
    title: title,
    message: '每位用户仅有一次免费体验机会，成功体验后可享 24 小时使用权。确认开始体验？',
    cancelLabel: '取消',
    confirmLabel: '体验',
    eventAccent:
        context.mounted ? resolveFeatureColor(context, feature) : null,
  );
  return ok == true;
}

/// 支付确认：glass 弹窗；确认键「去支付」+ 右侧小字括号价；Web 文案为「仅 App 可支付」。
Future<bool?> showFeaturePayConfirmDialog(
  BuildContext context, {
  required String message,
  required String priceLine,
  Color? eventAccent,
  String logoUrl = '',
}) {
  final actionLabel = kIsWeb ? '仅 App 可支付' : '去支付';
  return showGlassDialog<bool>(
    context: context,
    eventAccent: eventAccent,
    contentBuilder: (ctx) {
      final glassText = historyEditGlassTextColor(ctx);
      final glassLabel = historyEditGlassLabelColor(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      final accent = eventAccent ?? scheme.primary;
      // accent 底：相对 accent 成对，勿用主题 onPrimary
      final onAccent = AppColor.onFill(ctx, accent);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FeatureLogo(logoUrl: logoUrl, size: 28, accent: accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '支付开通',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: glassText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: glassLabel,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('取消'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel),
                    Text(
                      ' ($priceLine)',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: onAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
