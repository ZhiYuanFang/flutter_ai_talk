import 'package:flutter/material.dart';

import 'home_history_timeline_tile.dart';

/// 同一日历日卡片内，相邻历史行圆点之间的竖向渐变连线。
class HomeHistoryDayTimelineLinks extends StatelessWidget {
  const HomeHistoryDayTimelineLinks({
    super.key,
    required this.dotColors,
    required this.dotRadii,
    required this.rowSlotHeights,
  });

  final List<Color> dotColors;
  final List<double> dotRadii;
  /// 与 tiles 一一对应；含 badge 行可高于 [HomeHistoryTimelineTile.rowHeight]。
  final List<double> rowSlotHeights;

  @override
  Widget build(BuildContext context) {
    if (dotColors.length < 2 ||
        dotRadii.length != dotColors.length ||
        rowSlotHeights.length != dotColors.length) {
      return const SizedBox.shrink();
    }
    final height = rowSlotHeights.fold<double>(0, (sum, h) => sum + h);
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _HomeHistoryDayTimelineLinksPainter(
            dotColors: dotColors,
            dotRadii: dotRadii,
            rowSlotHeights: rowSlotHeights,
          ),
        ),
      ),
    );
  }
}

class _HomeHistoryDayTimelineLinksPainter extends CustomPainter {
  _HomeHistoryDayTimelineLinksPainter({
    required this.dotColors,
    required this.dotRadii,
    required this.rowSlotHeights,
  });

  final List<Color> dotColors;
  final List<double> dotRadii;
  final List<double> rowSlotHeights;

  static const _lineWidth = 1.0;
  static const _lineColorOpacity = 0.7;
  static const _gap = 1.0;

  double _dotCenterY(int index) {
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += rowSlotHeights[i];
    }
    return offset + HomeHistoryTimelineTile.rowHeight / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final x = HomeHistoryTimelineTile.timelineDotCenterX;

    for (var i = 0; i < dotColors.length - 1; i++) {
      final topCenterY = _dotCenterY(i);
      final bottomCenterY = _dotCenterY(i + 1);
      final y1 = topCenterY + dotRadii[i] + _gap;
      final y2 = bottomCenterY - dotRadii[i + 1] - _gap;
      if (y2 <= y1) continue;

      final rect = Rect.fromLTWH(x - _lineWidth, y1, _lineWidth * 2, y2 - y1);
      final paint = Paint()
        ..strokeWidth = _lineWidth
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            dotColors[i].withValues(alpha: _lineColorOpacity),
            dotColors[i + 1].withValues(alpha: _lineColorOpacity),
          ],
        ).createShader(rect);

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HomeHistoryDayTimelineLinksPainter oldDelegate) {
    if (oldDelegate.dotColors.length != dotColors.length) return true;
    if (oldDelegate.rowSlotHeights.length != rowSlotHeights.length) return true;
    for (var i = 0; i < dotColors.length; i++) {
      if (oldDelegate.dotColors[i] != dotColors[i]) return true;
      if (oldDelegate.dotRadii[i] != dotRadii[i]) return true;
      if (oldDelegate.rowSlotHeights[i] != rowSlotHeights[i]) return true;
    }
    return false;
  }
}
