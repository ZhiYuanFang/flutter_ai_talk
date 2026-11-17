import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/predict_capability_tier.dart';
import '../../theme/app_color.dart';

/// 基础版墙：能力条目列表（文案上、demo 下）；整行可点。
class PredictBasicFeatureList extends StatelessWidget {
  const PredictBasicFeatureList({
    super.key,
    required this.accent,
    this.onItemTap,
  });

  final Color accent;
  final ValueChanged<PredictBasicFeatureDemoKind>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    final muted = AppColor.textOnPanelGlassMuted(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < kPredictBasicFeatureItems.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _FeatureRow(
            item: kPredictBasicFeatureItems[i],
            accent: accent,
            titleColor: onGlass,
            subtitleColor: muted,
            onTap: onItemTap == null
                ? null
                : () => onItemTap!(kPredictBasicFeatureItems[i].kind),
          ),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.item,
    required this.accent,
    required this.titleColor,
    required this.subtitleColor,
    this.onTap,
  });

  final PredictBasicFeatureItem item;
  final Color accent;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${item.emoji} ${item.title}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.subtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: subtitleColor,
          ),
        ),
        const SizedBox(height: 8),
        // 假数据示意，吞点击（业务点整行）
        IgnorePointer(
          child: ExcludeSemantics(
            child: PredictBasicFeatureDemo(
              kind: item.kind,
              accent: accent,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return column;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: column,
        ),
      ),
    );
  }
}

/// 按 kind 绘制中档 demo（固定假数据）。
class PredictBasicFeatureDemo extends StatelessWidget {
  const PredictBasicFeatureDemo({
    super.key,
    required this.kind,
    required this.accent,
  });

  final PredictBasicFeatureDemoKind kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      PredictBasicFeatureDemoKind.nextEstimate =>
        _NextEstimateDemo(accent: accent),
      PredictBasicFeatureDemoKind.pushRemind => _PushRemindDemo(accent: accent),
      PredictBasicFeatureDemoKind.homeWidget => _HomeWidgetDemo(accent: accent),
      PredictBasicFeatureDemoKind.familyShare =>
        _FamilyShareDemo(accent: accent),
      PredictBasicFeatureDemoKind.landscapeCast =>
        _LandscapeCastDemo(accent: accent),
      PredictBasicFeatureDemoKind.voiceBall => _VoiceBallDemo(accent: accent),
      PredictBasicFeatureDemoKind.trendChart => _TrendChartDemo(accent: accent),
      PredictBasicFeatureDemoKind.xiaozhiSpeaker =>
        _XiaozhiSpeakerDemo(accent: accent),
    };
  }
}

/// 统一 demo 外壳：浅底圆角。
Widget _demoShell({
  required Color accent,
  required Widget child,
  double height = 88,
}) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    ),
  );
}

class _NextEstimateDemo extends StatelessWidget {
  const _NextEstimateDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _demoShell(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '母乳',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '还有 1:23:05',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PushRemindDemo extends StatelessWidget {
  const _PushRemindDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _demoShell(
      accent: accent,
      height: 72,
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: accent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '即将发生',
                  style: TextStyle(
                    fontSize: 11,
                    color: accent.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '母乳 · 约 10 分钟后',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeWidgetDemo extends StatelessWidget {
  const _HomeWidgetDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _demoShell(
      accent: accent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AspectRatio(
          aspectRatio: 1.15,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              // panelGlass 浅叠，禁止固定白底
              color: AppColor.textOnPanelGlass(context).withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Padding(
              // 壳高偏紧：少 padding、scaleDown，避免 Column 溢出
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '接下来',
                      style: TextStyle(
                        fontSize: 10,
                        color: accent.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '母乳',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Text(
                      '约 14:20',
                      style: TextStyle(
                        fontSize: 12,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyShareDemo extends StatelessWidget {
  const _FamilyShareDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = [
      accent,
      accent.withValues(alpha: 0.65),
      accent.withValues(alpha: 0.4),
    ];
    return _demoShell(
      accent: accent,
      height: 72,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < colors.length; i++)
                  Positioned(
                    left: i * 22.0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colors[i],
                      child: Text(
                        ['爸', '妈', '奶'][i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          // 相对头像底色成对
                          color: AppColor.onFill(context, colors[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '同一宝宝 · 全家同步',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandscapeCastDemo extends StatelessWidget {
  const _LandscapeCastDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _demoShell(
      accent: accent,
      height: 96,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.45), width: 2),
              color: accent.withValues(alpha: 0.06),
            ),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accent.withValues(alpha: 0.15),
                ),
                child: Text(
                  '横屏预测',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
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

class _VoiceBallDemo extends StatelessWidget {
  const _VoiceBallDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _demoShell(
      accent: accent,
      height: 96,
      child: Center(
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
                child: Icon(
                  Icons.mic,
                  // 相对 accent 实心圆
                  color: AppColor.onFill(context, accent),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChartDemo extends StatelessWidget {
  const _TrendChartDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _demoShell(
      accent: accent,
      height: 96,
      child: CustomPaint(
        painter: _MiniTrendPainter(color: accent),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  _MiniTrendPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[
      Offset(0, size.height * 0.65),
      Offset(size.width * 0.2, size.height * 0.45),
      Offset(size.width * 0.4, size.height * 0.55),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width, size.height * 0.22),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    final dot = Paint()..color = color;
    for (final p in pts) {
      canvas.drawCircle(p, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _XiaozhiSpeakerDemo extends StatelessWidget {
  const _XiaozhiSpeakerDemo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _demoShell(
      accent: accent,
      height: 96,
      child: Row(
        children: [
          // 简易音箱剪影
          SizedBox(
            width: 56,
            height: 64,
            child: CustomPaint(
              painter: _SpeakerSilhouettePainter(color: accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '小智音箱',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: accent.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    '可付费开通',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakerSilhouettePainter extends CustomPainter {
  _SpeakerSilhouettePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.15, size.width * 0.7,
          size.height * 0.7),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, paint);
    // 音箱孔高光：相对壳体亮度提亮/压暗，不用固定白
    final holeTint = color.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final hole = Paint()..color = holeTint.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.14,
      hole,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.68),
      size.width * 0.08,
      hole,
    );
    // 声波弧
    final arc = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 1; i <= 2; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.92, size.height * 0.5),
          radius: 6.0 * i,
        ),
        -math.pi / 3,
        2 * math.pi / 3,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeakerSilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}
