import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/predict_pro_idea_models.dart';
import '../../providers/predict_pro_idea_provider.dart';
import '../../theme/app_color.dart';
import 'app_glass_overlay.dart';
import 'predict_pro_idea_compose_sheet.dart';

/// 付费意愿小字（空态圆钮 /「我有更多想法」下方共用）。
const kPredictProIdeaPayHint = '具备什么功能，你愿意付费开通';

/// Pro 卡内想法区：空态底对齐心跳圆钮，或列表（底栏 CTA 由外层钉底）。
class PredictProIdeaPanel extends ConsumerWidget {
  const PredictProIdeaPanel({
    super.key,
    required this.accent,
    /// 有数据时是否内嵌「我有更多想法」；钉底场景传 false。
    this.showBottomCta = true,
  });

  final Color accent;
  final bool showBottomCta;

  Future<void> _openCompose(BuildContext context) async {
    await showPredictProIdeaComposeSheet(context, accent: accent);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(predictProIdeaListProvider);
    final items = state.items;
    final onGlass = AppColor.textOnPanelGlass(context);
    final muted = AppColor.textOnPanelGlassMuted(context);

    if (!state.loaded && state.loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      // 空态：底对齐由外层 Column Expanded + 本面板贴底完成
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeartbeatIdeaCircle(
            accent: accent,
            onTap: () => _openCompose(context),
          ),
          const SizedBox(height: 10),
          Text(
            kPredictProIdeaPayHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: muted,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '可能还包含以下能力',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: onGlass,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '热度越高越可能被收纳进Pro功能中',
          style: TextStyle(fontSize: 12, height: 1.35, color: muted),
        ),
        // 已去掉「被采纳…资格」占位文案
        const SizedBox(height: 12),
        for (final item in items) ...[
          _IdeaCard(
            item: item,
            accent: accent,
            onToggleLike: () =>
                ref.read(predictProIdeaListProvider.notifier).toggleLike(item.id),
            // 仅本人：长按 → 删除 Sheet
            onAuthorLongPress: item.isMine
                ? () => unawaited(_confirmDeleteOwnIdea(context, ref, item))
                : null,
          ),
          const SizedBox(height: 8),
        ],
        if (showBottomCta) ...[
          const SizedBox(height: 4),
          PredictProIdeaMoreCta(accent: accent),
        ],
      ],
    );
  }
}

/// 「我有更多想法」+ 付费意愿小字（卡内钉底，不随列表滚）。
class PredictProIdeaMoreCta extends StatelessWidget {
  const PredictProIdeaMoreCta({
    super.key,
    required this.accent,
  });

  final Color accent;

  Future<void> _openCompose(BuildContext context) async {
    await showPredictProIdeaComposeSheet(context, accent: accent);
  }

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    final muted = AppColor.textOnPanelGlassMuted(context);
    // 浅透 accent 底 + 玻璃字，避免 Material 默认浅底在夜空糊字
    final ctaFill = accent.withValues(alpha: 0.22);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: () => _openCompose(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: ctaFill,
              foregroundColor: onGlass,
              side: BorderSide(color: accent.withValues(alpha: 0.55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text(
              '我有更多想法',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          kPredictProIdeaPayHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.35, color: muted),
        ),
      ],
    );
  }
}

/// 心跳圆形「我有想法」。
class _HeartbeatIdeaCircle extends StatefulWidget {
  const _HeartbeatIdeaCircle({
    required this.accent,
    required this.onTap,
  });

  final Color accent;
  final VoidCallback onTap;

  @override
  State<_HeartbeatIdeaCircle> createState() => _HeartbeatIdeaCircleState();
}

class _HeartbeatIdeaCircleState extends State<_HeartbeatIdeaCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // 与预测卡心跳节奏接近
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 浅透 accent 底仍压在 panelGlass 上 → 字用玻璃正文原子（非实心 onFill）
    final fill = widget.accent.withValues(alpha: 0.28);
    final onGlass = AppColor.textOnPanelGlass(context);
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: Ink(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '我有想法',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: onGlass,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 本人想法：动作 Sheet → 确认 → 删除。
Future<void> _confirmDeleteOwnIdea(
  BuildContext context,
  WidgetRef ref,
  PredictProIdeaItem item,
) async {
  final accent = Theme.of(context).colorScheme.primary;
  final pickDelete = await showGlassAdaptiveBottomSheet<bool>(
    context: context,
    eventAccent: accent,
    maxHeightFraction: 0.35,
    scrollable: false,
    bodyBuilder: (ctx) {
      final onGlass = AppColor.textOnPanelGlass(ctx);
      final muted = AppColor.textOnPanelGlassMuted(ctx);
      // 展示当前想法正文，避免多条本人想法时误删
      final ideaText = item.text.trim();
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '管理想法',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onGlass,
            ),
          ),
          if (ideaText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '· ',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                Expanded(
                  child: Text(
                    ideaText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
            title: Text(
              '删除',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(ctx).colorScheme.error,
              ),
            ),
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      );
    },
  );
  if (pickDelete != true || !context.mounted) return;
  final ok = await showGlassConfirmDialog(
        context,
        title: '删除想法',
        message: '删除后不可恢复，确定删除这条想法吗？',
        confirmLabel: '删除',
        eventAccent: accent,
      ) ??
      false;
  if (!ok || !context.mounted) return;
  await ref.read(predictProIdeaListProvider.notifier).deleteIdea(item.id);
}

/// 紧凑列表行：• 正文 | 火赞；本人整行 accent；本人可长按删除。
class _IdeaCard extends StatelessWidget {
  const _IdeaCard({
    required this.item,
    required this.accent,
    required this.onToggleLike,
    this.onAuthorLongPress,
  });

  final PredictProIdeaItem item;
  final Color accent;
  final VoidCallback onToggleLike;
  final VoidCallback? onAuthorLongPress;

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    final muted = AppColor.textOnPanelGlassMuted(context);
    final mine = item.isMine;
    // 深 accent 在暗玻璃上不可读时回退 onGlass，仍用字重区分本人
    final accentReadable = accent.computeLuminance() >= 0.35;
    final rowColor = !mine
        ? onGlass
        : (accentReadable ? accent : onGlass);
    final heatColor = mine || item.likedByMe
        ? (accentReadable ? accent : onGlass)
        : muted.withValues(alpha: 0.9);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 列表 bullet（非 ASCII -）；本人始终用 accent 点标便于扫视
        Text(
          '•',
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: mine ? accent : rowColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.text,
            style: TextStyle(
              // 与热度/小字齐平，列表更密
              fontSize: 12,
              height: 1.4,
              fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
              color: rowColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 火标热度：与正文块纵向居中（独立 InkWell，避免与长按抢手势）
        InkWell(
          onTap: onToggleLike,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.likedByMe
                      ? Icons.local_fire_department
                      : Icons.local_fire_department_outlined,
                  size: 18,
                  color: heatColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${item.likeCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: heatColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (onAuthorLongPress == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onAuthorLongPress,
      child: row,
    );
  }
}
