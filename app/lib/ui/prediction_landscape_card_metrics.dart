/// 横屏 compact 预测卡尺寸：相对基准列宽等比 scale。
class PredictionLandscapeCardMetrics {
  const PredictionLandscapeCardMetrics({required double scale})
      : scale = scale < 0.01 ? 0.01 : scale;

  final double scale;

  static const baselineColumnGap = 12.0;
  static const baselineRowGap = 12.0;
  static const baselineCardBorderRadius = 18.0;

  /// 基准列数：手机 3、平板 5；当前列宽 / 基准列宽 → scale。
  static PredictionLandscapeCardMetrics forGrid({
    required double gridWidth,
    required int columnCount,
    required bool isTabletLandscape,
    double columnGap = baselineColumnGap,
  }) {
    final baseline = isTabletLandscape ? 5 : 3;
    final n = columnCount.clamp(3, 7);
    if (gridWidth <= 0) {
      return const PredictionLandscapeCardMetrics(scale: 1);
    }
    final refCell =
        (gridWidth - (baseline - 1) * columnGap) / baseline;
    final cell = (gridWidth - (n - 1) * columnGap) / n;
    final ref = refCell > 0 ? refCell : 1.0;
    return PredictionLandscapeCardMetrics(scale: cell / ref);
  }

  double get columnGap => baselineColumnGap * scale;
  double get rowGap => baselineRowGap * scale;

  double get titleFontSize => 14 * scale;
  double get relativeFontSize => 12 * scale;
  double get captionFontSize => 10 * scale;
  double get countdownFontSize => 26 * scale;
  double get titleLogoSize => 28 * scale;
  double get heroLogoSize => 52 * scale;
  double get switchScale => 0.72 * scale;

  static const baselineSwitchWidth = 52.0;
  static const baselineSwitchHeight = 32.0;

  double get switchColumnWidth => baselineSwitchWidth * switchScale;
  double get switchColumnHeight => baselineSwitchHeight * switchScale;
  double get captionRowGap => 6 * scale;

  double get paddingLeft => 10 * scale;
  double get paddingTop => 8 * scale;
  double get paddingRight => 6 * scale;
  double get paddingBottom => 10 * scale;

  double get cardBorderRadius => baselineCardBorderRadius * scale;

  double get titleLogoGap => 8 * scale;
  double get sectionGapSm => 4 * scale;
  double get sectionGapMd => 10 * scale;
  double get sectionGapLg => 12 * scale;
  double get heroGap => 8 * scale;
}
