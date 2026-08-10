import 'package:flutter/material.dart';

import '../../../theme/app_color.dart';
import 'ucg_feed_fake_glass_panel.dart';

/// 辩论 VS 条：软糖马卡龙假玻璃、emoji 中心、仅展示百分比；0 票对称条且不显示数字。
class UcgDebateVsBar extends StatelessWidget {
  const UcgDebateVsBar({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftRatio,
    required this.rightRatio,
    this.totalVotes = 0,
    this.myVoteSide,
    this.interactive = false,
    this.minDisplayRatio = 0.12,
    this.onVote,
  });

  final String leftLabel;
  final String rightLabel;
  final double leftRatio;
  final double rightRatio;
  final int totalVotes;
  final String? myVoteSide;
  final bool interactive;
  final double minDisplayRatio;
  final ValueChanged<String>? onVote;

  static const _barHeight = UcgDebateVisualTokens.vsBarHeight;
  static const _radius = UcgDebateVisualTokens.vsBarRadius;
  static const _sideHorizontalPadding = 16.0;
  static const _badgeSize = 36.0;
  static const _badgeHalf = _badgeSize / 2;
  /// 单侧文案区：左右 padding + 中心徽章半宽预留。
  static const _sideLayoutReserve = _sideHorizontalPadding + _badgeHalf;

  /// 测宽用（字色由 AppColor.debate*Label 提供）。
  static const _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  static const _percentTextStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    final hasVotes = totalVotes > 0;
    final displayLeft = hasVotes ? _clampVisual(leftRatio) : 0.5;
    final leftPct = hasVotes ? (leftRatio * 100).round() : null;
    final rightPct = hasVotes ? (rightRatio * 100).round() : null;
    final primary = AppColor.primary(context);

    Widget bar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColor.debateVsBarBorder(context)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.debateVsBarGlassTop(context),
            primary.withValues(alpha: 0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final (leftW, rightW) = _resolveSideWidths(
              totalWidth: w,
              leftRatioVisual: displayLeft,
              leftLabel: leftLabel,
              rightLabel: rightLabel,
              leftPercent: leftPct,
              rightPercent: rightPct,
            );
            final canVote = interactive && onVote != null;
            return SizedBox(
              height: _barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      _MacaronSide(
                        width: leftW,
                        gradientStart: AppColor.debateLeftStart(context),
                        gradientEnd: AppColor.debateLeftEnd(context),
                        label: leftLabel,
                        labelColor: AppColor.debateLeftLabel(context),
                        percent: leftPct,
                        percentColor: AppColor.debateLeftPercent(context),
                        selected: myVoteSide == 'left',
                        alignStart: true,
                        onTap: canVote ? () => onVote!('left') : null,
                      ),
                      _MacaronSide(
                        width: rightW,
                        gradientStart: AppColor.debateRightStart(context),
                        gradientEnd: AppColor.debateRightEnd(context),
                        label: rightLabel,
                        labelColor: AppColor.debateRightLabel(context),
                        percent: rightPct,
                        percentColor: AppColor.debateRightPercent(context),
                        selected: myVoteSide == 'right',
                        alignStart: false,
                        onTap: canVote ? () => onVote!('right') : null,
                      ),
                    ],
                  ),
                  Positioned(
                    left: (leftW - _badgeHalf).clamp(0.0, w - _badgeSize),
                    top: (_barHeight - _badgeSize) / 2,
                    child: IgnorePointer(
                      child: _EmojiBadge(
                        emoji: UcgDebateVisualTokens.vsCenterEmoji,
                        size: UcgDebateVsBar._badgeSize,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (!interactive || onVote == null) {
      return IgnorePointer(child: bar);
    }

    return bar;
  }

  double _clampVisual(double ratio) {
    if (ratio <= 0) return minDisplayRatio;
    if (ratio >= 1) return 1 - minDisplayRatio;
    return ratio.clamp(minDisplayRatio, 1 - minDisplayRatio);
  }

  /// 方案 A：色带宽 = max(票比宽, minDisplayRatio, 文案完整展示所需宽)。
  (double left, double right) _resolveSideWidths({
    required double totalWidth,
    required double leftRatioVisual,
    required String leftLabel,
    required String rightLabel,
    required int? leftPercent,
    required int? rightPercent,
  }) {
    if (totalWidth <= 0) return (0, 0);

    final minRatioW = totalWidth * minDisplayRatio;
    final leftFloor = _max(minRatioW, _sideMinContentWidth(leftLabel, leftPercent) + _sideLayoutReserve);
    final rightFloor = _max(minRatioW, _sideMinContentWidth(rightLabel, rightPercent) + _sideLayoutReserve);

    var leftW = _max(totalWidth * leftRatioVisual, leftFloor);
    var rightW = _max(totalWidth * (1 - leftRatioVisual), rightFloor);

    if (leftW + rightW <= totalWidth) {
      final sum = leftW + rightW;
      if (sum > 0 && sum < totalWidth) {
        leftW = totalWidth * leftW / sum;
        rightW = totalWidth - leftW;
      }
      return (leftW, rightW);
    }

    final overflow = leftW + rightW - totalWidth;
    final leftSlack = leftW - leftFloor;
    final rightSlack = rightW - rightFloor;
    final totalSlack = leftSlack + rightSlack;

    if (totalSlack <= 0) {
      leftW = totalWidth * leftFloor / (leftFloor + rightFloor);
      rightW = totalWidth - leftW;
      return (leftW, rightW);
    }

    leftW -= overflow * (leftSlack / totalSlack);
    rightW -= overflow * (rightSlack / totalSlack);
    leftW = _max(leftW, leftFloor);
    rightW = _max(rightW, rightFloor);

    if (leftW + rightW > totalWidth) {
      leftW = totalWidth * leftFloor / (leftFloor + rightFloor);
      rightW = totalWidth - leftW;
    }

    return (leftW, rightW);
  }

  static double _sideMinContentWidth(String label, int? percent) {
    final displayLabel = label.trim().isEmpty ? '—' : label.trim();
    final labelW = _measureText(displayLabel, _labelStyle);
    if (percent == null) return labelW;
    final pctW = _measureText('$percent%', _percentTextStyle) + 10;
    return _max(labelW, pctW);
  }

  static double _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  static double _max(double a, double b) => a > b ? a : b;
}

class _EmojiBadge extends StatelessWidget {
  const _EmojiBadge({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColor.debateVsChipFill(context),
        border: Border.all(color: AppColor.debateVsChipBorder(context), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColor.pageBg(context).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: 16,
          height: 1,
          color: AppColor.debateVsOnChip(context),
        ),
      ),
    );
  }
}

class _MacaronSide extends StatelessWidget {
  const _MacaronSide({
    required this.width,
    required this.gradientStart,
    required this.gradientEnd,
    required this.label,
    required this.labelColor,
    required this.percent,
    required this.percentColor,
    required this.selected,
    required this.alignStart,
    this.onTap,
  });

  final double width;
  final Color gradientStart;
  final Color gradientEnd;
  final String label;
  final Color labelColor;
  final int? percent;
  final Color percentColor;
  final bool selected;
  final bool alignStart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (width < 4) return SizedBox(width: width);

    final borderRadius = alignStart
        ? const BorderRadius.horizontal(left: Radius.circular(18))
        : const BorderRadius.horizontal(right: Radius.circular(18));
    final sideBorder = selected
        ? AppColor.debateVsSideBorderSelected(context)
        : AppColor.debateVsSideBorder(context);

    Widget side = SizedBox(
      width: width,
      height: UcgDebateVsBar._barHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: alignStart ? Alignment.centerLeft : Alignment.centerRight,
            end: alignStart ? Alignment.centerRight : Alignment.centerLeft,
            colors: [gradientStart, gradientEnd],
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: sideBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: gradientEnd.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRect(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              alignStart ? 10 : 6 + UcgDebateVsBar._badgeHalf,
              4,
              alignStart ? 6 + UcgDebateVsBar._badgeHalf : 10,
              4,
            ),
            child: _SideLabel(
              maxWidth: width - UcgDebateVsBar._sideLayoutReserve,
              maxHeight: UcgDebateVsBar._barHeight - 8,
              label: label,
              labelColor: labelColor,
              percent: percent,
              percentColor: percentColor,
              alignStart: alignStart,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return side;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: side,
    );
  }
}

class _SideLabel extends StatelessWidget {
  const _SideLabel({
    required this.maxWidth,
    required this.maxHeight,
    required this.label,
    required this.labelColor,
    required this.percent,
    required this.percentColor,
    required this.alignStart,
  });

  final double maxWidth;
  final double maxHeight;
  final String label;
  final Color labelColor;
  final int? percent;
  final Color percentColor;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final align = alignStart ? Alignment.centerLeft : Alignment.centerRight;
    final displayLabel = label.trim().isEmpty ? '—' : label.trim();

    Widget content = Text(
      displayLabel,
      maxLines: 1,
      softWrap: false,
      style: UcgDebateVsBar._labelStyle.copyWith(color: labelColor),
    );

    if (percent != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          content,
          const SizedBox(height: 2),
          _PercentSticker(percent: percent!, color: percentColor),
        ],
      );
    }

    return Align(
      alignment: align,
      child: SizedBox(
        width: maxWidth.clamp(0, double.infinity),
        height: maxHeight.clamp(0, double.infinity),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align,
          child: content,
        ),
      ),
    );
  }
}

class _PercentSticker extends StatelessWidget {
  const _PercentSticker({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColor.debateVsStickerFill(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.debateVsStickerBorder(context)),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: color,
          fontSize: UcgDebateVsBar._percentTextStyle.fontSize,
          fontWeight: UcgDebateVsBar._percentTextStyle.fontWeight,
          height: UcgDebateVsBar._percentTextStyle.height,
        ),
      ),
    );
  }
}
