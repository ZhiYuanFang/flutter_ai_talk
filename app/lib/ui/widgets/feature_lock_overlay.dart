import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// 统一功能锁定浮层：真实内容之上高斯模糊 + 浅透罩 + 中心锁。
///
/// 罩色用 [AppColor.lockScrim]（低 α），勿用实心 [AppColor.panelGlassGradient]。
/// 卡片场景不得使用 [StackFit.expand]（ListView 纵向无界会炸 layout）。
/// 全屏场景外层包 [SizedBox.expand] 占满有界父级（如 PageView）。
/// 矮卡片用精简内容 / [FittedBox]，避免 Column overflow。
class FeatureLockOverlay extends StatelessWidget {
  const FeatureLockOverlay({
    super.key,
    required this.child,
    this.onTap,
    this.centerLabel = '点击开通',
    this.subtitle,
    this.footer,
    this.borderRadius = 16,
    this.fullScreen = false,
  });

  /// 被锁住的真实内容（仍渲染，供模糊采样）。
  final Widget child;

  /// 点击浮层（预测卡 → 开通中心）。
  final VoidCallback? onTap;

  /// 中心主文案（预测默认「点击开通」）。
  final String centerLabel;

  /// 次文案（UCG 天数进度等）。
  final String? subtitle;

  /// 底部槽位（如「返回预测页」按钮）。
  final Widget? footer;

  final double borderRadius;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final radius = fullScreen ? 0.0 : borderRadius;
    // 浅透罩上的文案用壳主色，比实心 panelGlass 上的 onPanelGlass 更稳
    final onScrim = AppColor.textPrimary(context);
    final blurSigma = fullScreen ? 16.0 : 12.0;

    // 非定位 child 决定高度；Positioned.fill 盖浮层（适配 ListView 无界约束）。
    final stack = Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.hardEdge,
      children: [
        ExcludeSemantics(excluding: true, child: child),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  // 浅透罩：勿用 panelGlassGradient（过实会盖死模糊底图）
                  color: AppColor.lockScrim(context),
                  border: fullScreen
                      ? null
                      : Border.all(
                          color: AppColor.divider(context).withValues(alpha: 0.5),
                        ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _LockOverlayBody(
                          constraints: constraints,
                          fullScreen: fullScreen,
                          onPanel: onScrim,
                          centerLabel: centerLabel,
                          subtitle: subtitle,
                          footer: footer,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (fullScreen) {
      return SizedBox.expand(child: stack);
    }
    return stack;
  }
}

class _LockOverlayBody extends StatelessWidget {
  const _LockOverlayBody({
    required this.constraints,
    required this.fullScreen,
    required this.onPanel,
    required this.centerLabel,
    this.subtitle,
    this.footer,
  });

  final BoxConstraints constraints;
  final bool fullScreen;
  final Color onPanel;
  final String centerLabel;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;
    // 瀑布流矮卡：只放锁标；中等高度：锁+短文案；全屏/高卡：完整 UI
    final tiny = !fullScreen && h < 56;
    final compact = !fullScreen && h < 120;

    if (tiny) {
      return Center(
        child: Icon(
          Icons.lock_rounded,
          size: (h * 0.55).clamp(14.0, 28.0),
          color: onPanel.withValues(alpha: 0.95),
        ),
      );
    }

    final padH = compact ? 8.0 : 20.0;
    final padV = compact ? 6.0 : (fullScreen ? 32.0 : 12.0);
    final iconSize = compact ? 22.0 : (fullScreen ? 36.0 : 28.0);

    final column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_rounded,
          size: iconSize,
          color: onPanel.withValues(alpha: 0.95),
        ),
        SizedBox(height: compact ? 6 : 12),
        Text(
          centerLabel,
          textAlign: TextAlign.center,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: (compact
                  ? Theme.of(context).textTheme.bodyMedium
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.w700,
            color: onPanel,
            fontSize: compact ? 12 : null,
          ),
        ),
        if (!compact &&
            subtitle != null &&
            subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onPanel.withValues(alpha: 0.78),
                  height: 1.35,
                ),
          ),
        ],
        if (!compact && footer != null) ...[
          const SizedBox(height: 20),
          footer!,
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (w - padH * 2).clamp(40.0, double.infinity),
            // 给 FittedBox 一个内容自然高度上限，避免反向撑破
            maxHeight: (h - padV * 2).clamp(24.0, double.infinity),
          ),
          child: column,
        ),
      ),
    );
  }
}
