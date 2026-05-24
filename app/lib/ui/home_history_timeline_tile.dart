import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import '../data/history_line_format.dart';
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
  });

  final HistoryHomeRowDisplay display;
  /// 0 = 视觉上最靠近底部（最新一条）。
  final int fromBottom;
  final VoidCallback onTap;
  final EventDefinition? event;
  final String? activeElapsedLabel;
  final VoidCallback? onStop;
  final bool stopInProgress;

  static const double rowHeight = 34;
  static const double _timeWidth = 44;
  static const double _logoSize = 16;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = resolveEventColor(context, event);
    final fontSize = (13 - fromBottom * 0.25).clamp(11.0, 13.0);
    final emphasis = (1.0 - fromBottom * 0.08).clamp(0.55, 1.0);
    final isNewest = fromBottom == 0;

    final timeStyle = TextStyle(
      fontSize: fontSize - 1,
      height: 1.15,
      color: scheme.onSurfaceVariant.withValues(alpha: emphasis),
    );
    final eventStyle = TextStyle(
      fontSize: fontSize,
      height: 1.15,
      fontWeight: FontWeight.w600,
      color: accent.withValues(alpha: emphasis),
    );
    final trailingStyle = TextStyle(
      fontSize: fontSize - 1,
      height: 1.15,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: scheme.primary.withValues(alpha: emphasis),
    );

    final centerLabel = display.remark == null || display.remark!.isEmpty
        ? display.eventName
        : '${display.eventName}(${display.remark})';

    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
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
                      EventLogo(definition: event, size: _logoSize),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: _timeWidth,
                        child: Text(
                          display.timeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: timeStyle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          centerLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: eventStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (display.isActiveTiming &&
              activeElapsedLabel != null &&
              onStop != null)
            _ActiveTimingTrailing(
              elapsedLabel: activeElapsedLabel!,
              trailingStyle: trailingStyle,
              onStop: onStop!,
              stopInProgress: stopInProgress,
            )
          else if (display.trailing.isNotEmpty) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                display.trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize - 1,
                  height: 1.15,
                  color: scheme.onSurfaceVariant.withValues(alpha: emphasis),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveTimingTrailing extends StatelessWidget {
  const _ActiveTimingTrailing({
    required this.elapsedLabel,
    required this.trailingStyle,
    required this.onStop,
    required this.stopInProgress,
  });

  final String elapsedLabel;
  final TextStyle trailingStyle;
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
          Text(
            elapsedLabel,
            maxLines: 1,
            style: trailingStyle,
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

/// 历史列表顶部淡出渐变（较旧记录在视觉上变弱）。
class HomeHistoryTopFadeMask extends StatelessWidget {
  const HomeHistoryTopFadeMask({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          stops: [0.0, 0.1, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
