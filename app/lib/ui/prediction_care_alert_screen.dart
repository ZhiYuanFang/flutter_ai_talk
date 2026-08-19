import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/prediction_care_alert.dart';
import '../home_widget/home_widget_sync.dart';
import '../providers/care_alert_follow_up_provider.dart';
import '../providers/clinic_ws_provider.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../theme/app_visual_tokens.dart';
import '../ucg/data/ucg_feature_flags.dart';
import 'widgets/app_toast.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// 护理留意详情：展示该事件全部原因 + 忽略 / 追问（非医疗诊断）。
class PredictionCareAlertScreen extends ConsumerWidget {
  const PredictionCareAlertScreen({super.key, required this.item});

  final CareAlertEventItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final shell = tokens?.shellColor ?? scheme.surface;
    final onShell = tokens?.onShell ?? scheme.onSurface;
    // VIP 购买暂停（kVipPurchaseEnabled=false）：不开通 CTA
    final showVipCta = kVipPurchaseEnabled;

    Future<void> onIgnore() async {
      // 乐观移除 + pop；同步刷新桌面 tip（忽略后列表可能变空）
      final notifier = ref.read(predictionCareAlertStateProvider.notifier);
      notifier.removeLocally(item.suggestionId);
      unawaited(notifier.ignoreSuggestion(item));
      unawaited(scheduleHomeWidgetSync(ref));
      if (context.mounted) context.pop();
    }

    Future<void> onFollowUp() async {
      final prompt = item.followUpPrompt.trim();
      // 固定意图飞轮（不阻塞进树洞）
      unawaited(
        ref
            .read(predictionCareAlertStateProvider.notifier)
            .reportFollowUp(item),
      );
      if (prompt.isNotEmpty) {
        ref.read(careAlertFollowUpPromptProvider.notifier).state = prompt;
      }
      await activateCompanionClinicWs(ref);
      if (!context.mounted) return;
      // 先离开详情再进树洞
      context.pop();
      await context.push('/companion');
    }

    return Scaffold(
      backgroundColor: shell,
      appBar: AppBar(
        backgroundColor: shell,
        foregroundColor: onShell,
        title: const Text('值得留意'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      // 暂停期 showVipCta 恒 false；翻回 kVipPurchaseEnabled 后需再接 VIP 状态分流
      bottomNavigationBar: showVipCta
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (kIsWeb) {
                      showAppToast('请使用手机 App 开通 VIP');
                      return;
                    }
                    unawaited(context.push<bool>('/vip/purchase'));
                  },
                  child: const Text('开通 VIP'),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.eventName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onShell,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.summaryLine,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '这是相对你宝宝近期记录与月龄期望的对照提示，不是医疗诊断。',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: onShell.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          for (final reason in item.reasons) ...[
            const SizedBox(height: 14),
            _GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.typeLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onShell,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _kv(onShell, '类型', reason.typeLabel),
                  if (reason.ageMonths != null)
                    _kv(onShell, '月龄', '${reason.ageMonths} 个月')
                  else
                    _kv(onShell, '月龄', '未使用（生日不可用）'),
                  for (final line in reason.detailLines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      // 渲染 markdown
                      child:MarkdownWidget(data: line, shrinkWrap: true,),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => unawaited(onIgnore()),
                  child: const Text('忽略'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => unawaited(onFollowUp()),
                  child: const Text('追问'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(Color onShell, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 13,
                color: onShell.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: onShell.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.12),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
