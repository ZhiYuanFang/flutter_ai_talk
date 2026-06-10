import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../theme/app_visual_tokens.dart';
import 'event_logo.dart';

/// 主页历史列表：紧凑时间轴行（左时间、中事件、右尾注）。
class HomeHistoryTimelineTile extends StatelessWidget {
  const HomeHistoryTimelineTile({
    super.key,
    required this.display,
    required this.fromBottom,
    required this.onTap,
    this.event,
    this.activeElapsedLabel,
    this.onStop,
    this.stopInProgress = false,
    this.logoAnchorKey,
    this.hideLogoDuringFly = false,
    this.showRelativeAgo = false,
    this.relativeAgoLabel,
  });

  final HistoryHomeRowDisplay display;
  /// 0 = 视觉上最靠近底部（最新一条）。
  final int fromBottom;
  final VoidCallback onTap;
  final EventDefinition? event;
  final String? activeElapsedLabel;
  final VoidCallback? onStop;
  final bool stopInProgress;
  final Key? logoAnchorKey;
  final bool hideLogoDuringFly;
  final bool showRelativeAgo;
  final String? relativeAgoLabel;

  static const double rowHeight = 40;
  static const double timelineTimeColumnWidth = 44;
  static const double timelineTimeToDotGap = 2;
  static const double timelineDotColumnWidth = 14;
  static const double timelineRowHorizontalPadding = 2;
  static const double timelineDotCenterX = timelineRowHorizontalPadding +
      timelineTimeColumnWidth +
      timelineTimeToDotGap +
      timelineDotColumnWidth / 2;
  static const double logoSize = 16;

  static double get timelineBadgeLeftInset =>
      timelineRowHorizontalPadding +
      timelineTimeColumnWidth +
      timelineTimeToDotGap +
      timelineDotColumnWidth +
      2 +
      logoSize +
      4;

  /// Badge 区域占用高度（行下方，不含 [rowHeight]）。
  static const double timelineBadgeBottomPadding = 4;
  static const double timelineBadgeSlotHeight = 28;

  /// 列表中该 tile 占用的竖向槽位（含 badge 时不与下一行重叠）。
  static double slotHeightFor({required bool showRelativeAgo}) =>
      showRelativeAgo ? rowHeight + timelineBadgeSlotHeight : rowHeight;

  static const Color _relativeAgoBadgeTextRedTarget = Color(0xFFE53935);
  static const double _relativeAgoBadgeTextRedLerp = 0.15;

  static Color _relativeAgoBadgeTextColor(Color accent) =>
      Color.lerp(accent, _relativeAgoBadgeTextRedTarget, _relativeAgoBadgeTextRedLerp)!;

  static double dotRadiusForFromBottom(int fromBottom) =>
      fromBottom == 0 ? 3.5 : 2.5;

  /// 历史行正文色：随主题 shell 前景（onShell），非事件色、非 primary 染色。
  static Color _historyTextColor(
    BuildContext context, {
    required double emphasis,
    bool muted = false,
  }) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final base = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final alpha = muted
        ? (0.62 * emphasis).clamp(0.0, 1.0)
        : emphasis.clamp(0.0, 1.0);
    return base.withValues(alpha: alpha);
  }

  @override
  Widget build(BuildContext context) {
    final accent = resolveEventColor(context, event);
    final fontSize = (13 - fromBottom * 0.35).clamp(9.0, 13.0);
    final emphasis = (1.0 - fromBottom * 0.10).clamp(0.45, 1.0);
    final isNewest = fromBottom == 0;

    final timeStyle = TextStyle(
      fontSize: fontSize - 1,
      height: 1.15,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: _historyTextColor(context, emphasis: emphasis, muted: true),
    );
    final eventStyle = historyTimelineEventNameStyle(TextStyle(
      fontSize: fontSize,
      height: 1.15,
      color: _historyTextColor(context, emphasis: emphasis),
    ));
    final remarkStyle = historyTimelineRemarkStyle(TextStyle(
      fontSize: fontSize,
      height: 1.15,
      color: _historyTextColor(context, emphasis: emphasis),
    ));
    final trailingStyle = TextStyle(
      fontSize: fontSize - 1,
      height: 1.15,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: _historyTextColor(context, emphasis: emphasis),
    );
    final trailingDigitStyle = historyTimelineDigitAccentStyle(trailingStyle, accent);

    final centerSpans = <InlineSpan>[
      TextSpan(text: display.eventName, style: eventStyle),
    ];
    if (display.remark != null && display.remark!.isNotEmpty) {
      centerSpans.addAll([
        TextSpan(text: '(', style: remarkStyle),
        TextSpan(text: display.remark, style: remarkStyle),
        TextSpan(text: ')', style: remarkStyle),
      ]);
    }

    InlineSpan? trailingSpan;
    if (display.hasStructuredTrailing) {
      if (display.trailingCount != null) {
        trailingSpan = TextSpan(
          children: historyCountTrailingSpans(
            display.trailingCount!,
            display.trailingUnit ?? '',
            trailingStyle,
            trailingDigitStyle,
          ),
        );
      } else if (display.trailingPrefix != null && display.trailingDuration != null) {
        trailingSpan = TextSpan(
          children: historyDurationTrailingSpans(
            display.trailingPrefix!,
            display.trailingDuration!,
            trailingStyle,
            trailingDigitStyle,
          ),
        );
      }
    } else if (display.trailing.isNotEmpty) {
      trailingSpan = TextSpan(
        children: historyDigitAccentSpans(display.trailing, trailingStyle, trailingDigitStyle),
      );
    }

    final rowBody = Padding(
      padding: const EdgeInsets.symmetric(horizontal: timelineRowHorizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: timelineTimeColumnWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                display.timeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: timeStyle,
              ),
            ),
          ),
          const SizedBox(width: timelineTimeToDotGap),
          SizedBox(
            width: timelineDotColumnWidth,
            child: Center(
              child: Container(
                width: isNewest ? 7 : 5,
                height: isNewest ? 7 : 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNewest ? accent : accent.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: SizedBox(
                key: logoAnchorKey,
                width: logoSize,
                height: logoSize,
                child: Visibility(
                  visible: !hideLogoDuringFly,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: EventLogo(
                    definition: event,
                    size: logoSize,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(children: centerSpans),
            ),
          ),
          if (display.isActiveTiming &&
              activeElapsedLabel != null &&
              onStop != null)
            _ActiveTimingTrailing(
              elapsedLabel: activeElapsedLabel!,
              trailingStyle: trailingStyle,
              digitStyle: trailingDigitStyle,
              onStop: onStop!,
              stopInProgress: stopInProgress,
            )
          else if (trailingSpan != null) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: trailingSpan,
              ),
            ),
          ],
        ],
      ),
    );

    Widget tappableTile(Widget child) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: child,
        ),
      );
    }

    if (!showRelativeAgo || relativeAgoLabel == null) {
      return SizedBox(
        height: rowHeight,
        child: tappableTile(
          SizedBox(height: rowHeight, child: rowBody),
        ),
      );
    }

    final badgeFontSize = fontSize - 1;
    final themePrimary = Theme.of(context).colorScheme.primary;
    final badgeBg = themePrimary.withValues(alpha: 0.1);
    final badgeTextColor = _relativeAgoBadgeTextColor(accent);

    final badge = Padding(
      padding: EdgeInsets.only(
        left: timelineBadgeLeftInset,
        bottom: timelineBadgeBottomPadding,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            '[$relativeAgoLabel]',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: badgeFontSize,
              height: 1.2,
              color: badgeTextColor,
            ),
          ),
        ),
      ),
    );

    final slotHeight = slotHeightFor(showRelativeAgo: true);

    return SizedBox(
      height: slotHeight,
      child: tappableTile(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: rowHeight, child: rowBody),
            badge,
          ],
        ),
      ),
    );
  }
}

class _ActiveTimingTrailing extends StatelessWidget {
  const _ActiveTimingTrailing({
    required this.elapsedLabel,
    required this.trailingStyle,
    required this.digitStyle,
    required this.onStop,
    required this.stopInProgress,
  });

  final String elapsedLabel;
  final TextStyle trailingStyle;
  final TextStyle digitStyle;
  final VoidCallback onStop;
  final bool stopInProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            maxLines: 1,
            text: TextSpan(
              children: historyDigitAccentSpans(elapsedLabel, trailingStyle, digitStyle),
            ),
          ),
          const SizedBox(width: 2),
          TextButton(
            onPressed: stopInProgress ? null : onStop,
            style: TextButton.styleFrom(
              minimumSize: const Size(40, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: scheme.primary,
            ),
            child: Text(stopInProgress ? '…' : '停止', style: TextStyle(fontSize: trailingStyle.fontSize)),
          ),
        ],
      ),
    );
  }
}

/// 历史列表顶部淡出：叠层渐变（避免整表 [ShaderMask] 拖慢滚动）。
class HomeHistoryTopFadeMask extends StatelessWidget {
  const HomeHistoryTopFadeMask({super.key, required this.child});

  final Widget child;

  static const double _fadeHeight = 56;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shell = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _fadeHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.42, 1.0],
                  colors: [
                    shell.withValues(alpha: 0.92),
                    shell.withValues(alpha: 0.45),
                    shell.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
