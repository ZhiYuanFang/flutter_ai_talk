import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/predict_pro_idea_models.dart';
import '../../providers/predict_pro_idea_provider.dart';
import '../../theme/app_color.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: () => _openCompose(context),
            style: OutlinedButton.styleFrom(
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
                color: widget.accent.withValues(alpha: 0.22),
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

/// 紧凑列表行：• 正文 | 火赞；本人整行 accent。
class _IdeaCard extends StatelessWidget {
  const _IdeaCard({
    required this.item,
    required this.accent,
    required this.onToggleLike,
  });

  final PredictProIdeaItem item;
  final Color accent;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    final muted = AppColor.textOnPanelGlassMuted(context);
    final mine = item.isMine;
    // 本人整行 accent；他人默认玻璃字色
    final rowColor = mine ? accent : onGlass;
    final heatColor = mine || item.likedByMe
        ? accent
        : muted.withValues(alpha: 0.9);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 列表 bullet（非 ASCII -）
        Text(
          '•',
          style: TextStyle(
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: rowColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
              color: rowColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 火标热度：与正文块纵向居中
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
  }
}
