import 'package:flutter/material.dart';

/// 产品语义色 ThemeExtension：shell / surface / content 卡 / modal / panelGlass / debate 等。
class AppVisualTokens extends ThemeExtension<AppVisualTokens> {
  const AppVisualTokens({
    required this.shellColor,
    required this.surfaceColor,
    required this.surfaceBorderColor,
    required this.pillBackground,
    required this.pillBorder,
    required this.recordsCardColor,
    required this.onRecordsCard,
    required this.onShell,
    required this.onSurface,
    required this.modalFill,
    required this.modalBorder,
    required this.onModal,
    required this.fieldFill,
    required this.fieldBorder,
    required this.barrierColor,
    required this.panelGlassTop,
    required this.panelGlassBottom,
    required this.onPanelGlass,
    required this.debateLeftStart,
    required this.debateLeftEnd,
    required this.debateRightStart,
    required this.debateRightEnd,
    required this.debateLeftLabel,
    required this.debateLeftPercent,
    required this.debateRightLabel,
    required this.debateRightPercent,
    required this.debateVsChipFill,
    required this.debateVsChipBorder,
    required this.debateVsOnChip,
    required this.debateVsBarBorder,
    required this.debateVsBarGlassTop,
    required this.debateVsSideBorder,
    required this.debateVsSideBorderSelected,
    required this.debateVsStickerFill,
    required this.debateVsStickerBorder,
    required this.mediaScrim,
    required this.onMediaScrim,
    required this.panelShadow,
    required this.isDarkShell,
    this.surfaceRadius = 14,
  });

  final Color shellColor;
  final Color surfaceColor;
  final Color surfaceBorderColor;
  final Color pillBackground;
  final Color pillBorder;

  /// 内容卡底（Feed/历史 records）；暗壳可偏亮。
  final Color recordsCardColor;

  /// 内容卡正文。
  final Color onRecordsCard;

  final Color onShell;
  final Color onSurface;

  /// 居中 Dialog / 软引导浮层底（暗壳为暗浮层，非浅 content 卡）。
  final Color modalFill;
  final Color modalBorder;
  final Color onModal;

  /// 输入壳底/边。
  final Color fieldFill;
  final Color fieldBorder;

  /// Dialog/Sheet 遮罩。
  final Color barrierColor;

  /// 页内 chrome 玻璃渐变顶（tip/留意/预测卡/UCG 广场；暗壳非近白 contentCard）。
  final Color panelGlassTop;

  /// 页内 chrome 玻璃渐变底。
  final Color panelGlassBottom;

  /// 压在 panelGlass 上的正文。
  final Color onPanelGlass;

  /// 辩论左侧条渐变起/止。
  final Color debateLeftStart;
  final Color debateLeftEnd;

  /// 辩论右侧条渐变起/止。
  final Color debateRightStart;
  final Color debateRightEnd;

  /// 辩论左/右侧标签与百分比字色。
  final Color debateLeftLabel;
  final Color debateLeftPercent;
  final Color debateRightLabel;
  final Color debateRightPercent;

  /// VS 中心 emoji 钮填色/描边/前景。
  final Color debateVsChipFill;
  final Color debateVsChipBorder;
  final Color debateVsOnChip;

  /// VS 条外框与条内浅玻璃顶。
  final Color debateVsBarBorder;
  final Color debateVsBarGlassTop;

  /// 辩论侧块描边（未选/选中）。
  final Color debateVsSideBorder;
  final Color debateVsSideBorderSelected;

  /// 百分比贴纸底/边。
  final Color debateVsStickerFill;
  final Color debateVsStickerBorder;

  /// 媒体沉浸遮罩底（viewer / 全屏预览）。
  final Color mediaScrim;

  /// 压在媒体遮罩上的字/图标。
  final Color onMediaScrim;

  final List<BoxShadow> panelShadow;
  final bool isDarkShell;
  final double surfaceRadius;

  /// 别名：content 卡 = records 卡。
  Color get contentCardColor => recordsCardColor;
  Color get onContentCard => onRecordsCard;

  /// Sheet 默认与 modal 同源。
  Color get sheetFill => modalFill;
  Color get sheetBorder => modalBorder;
  Color get onSheet => onModal;

  @override
  AppVisualTokens copyWith({
    Color? shellColor,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    Color? pillBackground,
    Color? pillBorder,
    Color? recordsCardColor,
    Color? onRecordsCard,
    Color? onShell,
    Color? onSurface,
    Color? modalFill,
    Color? modalBorder,
    Color? onModal,
    Color? fieldFill,
    Color? fieldBorder,
    Color? barrierColor,
    Color? panelGlassTop,
    Color? panelGlassBottom,
    Color? onPanelGlass,
    Color? debateLeftStart,
    Color? debateLeftEnd,
    Color? debateRightStart,
    Color? debateRightEnd,
    Color? debateLeftLabel,
    Color? debateLeftPercent,
    Color? debateRightLabel,
    Color? debateRightPercent,
    Color? debateVsChipFill,
    Color? debateVsChipBorder,
    Color? debateVsOnChip,
    Color? debateVsBarBorder,
    Color? debateVsBarGlassTop,
    Color? debateVsSideBorder,
    Color? debateVsSideBorderSelected,
    Color? debateVsStickerFill,
    Color? debateVsStickerBorder,
    Color? mediaScrim,
    Color? onMediaScrim,
    List<BoxShadow>? panelShadow,
    bool? isDarkShell,
    double? surfaceRadius,
  }) {
    return AppVisualTokens(
      shellColor: shellColor ?? this.shellColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceBorderColor: surfaceBorderColor ?? this.surfaceBorderColor,
      pillBackground: pillBackground ?? this.pillBackground,
      pillBorder: pillBorder ?? this.pillBorder,
      recordsCardColor: recordsCardColor ?? this.recordsCardColor,
      onRecordsCard: onRecordsCard ?? this.onRecordsCard,
      onShell: onShell ?? this.onShell,
      onSurface: onSurface ?? this.onSurface,
      modalFill: modalFill ?? this.modalFill,
      modalBorder: modalBorder ?? this.modalBorder,
      onModal: onModal ?? this.onModal,
      fieldFill: fieldFill ?? this.fieldFill,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      barrierColor: barrierColor ?? this.barrierColor,
      panelGlassTop: panelGlassTop ?? this.panelGlassTop,
      panelGlassBottom: panelGlassBottom ?? this.panelGlassBottom,
      onPanelGlass: onPanelGlass ?? this.onPanelGlass,
      debateLeftStart: debateLeftStart ?? this.debateLeftStart,
      debateLeftEnd: debateLeftEnd ?? this.debateLeftEnd,
      debateRightStart: debateRightStart ?? this.debateRightStart,
      debateRightEnd: debateRightEnd ?? this.debateRightEnd,
      debateLeftLabel: debateLeftLabel ?? this.debateLeftLabel,
      debateLeftPercent: debateLeftPercent ?? this.debateLeftPercent,
      debateRightLabel: debateRightLabel ?? this.debateRightLabel,
      debateRightPercent: debateRightPercent ?? this.debateRightPercent,
      debateVsChipFill: debateVsChipFill ?? this.debateVsChipFill,
      debateVsChipBorder: debateVsChipBorder ?? this.debateVsChipBorder,
      debateVsOnChip: debateVsOnChip ?? this.debateVsOnChip,
      debateVsBarBorder: debateVsBarBorder ?? this.debateVsBarBorder,
      debateVsBarGlassTop: debateVsBarGlassTop ?? this.debateVsBarGlassTop,
      debateVsSideBorder: debateVsSideBorder ?? this.debateVsSideBorder,
      debateVsSideBorderSelected:
          debateVsSideBorderSelected ?? this.debateVsSideBorderSelected,
      debateVsStickerFill: debateVsStickerFill ?? this.debateVsStickerFill,
      debateVsStickerBorder:
          debateVsStickerBorder ?? this.debateVsStickerBorder,
      mediaScrim: mediaScrim ?? this.mediaScrim,
      onMediaScrim: onMediaScrim ?? this.onMediaScrim,
      panelShadow: panelShadow ?? this.panelShadow,
      isDarkShell: isDarkShell ?? this.isDarkShell,
      surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    );
  }

  @override
  AppVisualTokens lerp(ThemeExtension<AppVisualTokens>? other, double t) {
    if (other is! AppVisualTokens) return this;
    return AppVisualTokens(
      shellColor: Color.lerp(shellColor, other.shellColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      surfaceBorderColor:
          Color.lerp(surfaceBorderColor, other.surfaceBorderColor, t)!,
      pillBackground: Color.lerp(pillBackground, other.pillBackground, t)!,
      pillBorder: Color.lerp(pillBorder, other.pillBorder, t)!,
      recordsCardColor: Color.lerp(recordsCardColor, other.recordsCardColor, t)!,
      onRecordsCard: Color.lerp(onRecordsCard, other.onRecordsCard, t)!,
      onShell: Color.lerp(onShell, other.onShell, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      modalFill: Color.lerp(modalFill, other.modalFill, t)!,
      modalBorder: Color.lerp(modalBorder, other.modalBorder, t)!,
      onModal: Color.lerp(onModal, other.onModal, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
      panelGlassTop: Color.lerp(panelGlassTop, other.panelGlassTop, t)!,
      panelGlassBottom: Color.lerp(panelGlassBottom, other.panelGlassBottom, t)!,
      onPanelGlass: Color.lerp(onPanelGlass, other.onPanelGlass, t)!,
      debateLeftStart: Color.lerp(debateLeftStart, other.debateLeftStart, t)!,
      debateLeftEnd: Color.lerp(debateLeftEnd, other.debateLeftEnd, t)!,
      debateRightStart: Color.lerp(debateRightStart, other.debateRightStart, t)!,
      debateRightEnd: Color.lerp(debateRightEnd, other.debateRightEnd, t)!,
      debateLeftLabel: Color.lerp(debateLeftLabel, other.debateLeftLabel, t)!,
      debateLeftPercent:
          Color.lerp(debateLeftPercent, other.debateLeftPercent, t)!,
      debateRightLabel: Color.lerp(debateRightLabel, other.debateRightLabel, t)!,
      debateRightPercent:
          Color.lerp(debateRightPercent, other.debateRightPercent, t)!,
      debateVsChipFill: Color.lerp(debateVsChipFill, other.debateVsChipFill, t)!,
      debateVsChipBorder:
          Color.lerp(debateVsChipBorder, other.debateVsChipBorder, t)!,
      debateVsOnChip: Color.lerp(debateVsOnChip, other.debateVsOnChip, t)!,
      debateVsBarBorder:
          Color.lerp(debateVsBarBorder, other.debateVsBarBorder, t)!,
      debateVsBarGlassTop:
          Color.lerp(debateVsBarGlassTop, other.debateVsBarGlassTop, t)!,
      debateVsSideBorder:
          Color.lerp(debateVsSideBorder, other.debateVsSideBorder, t)!,
      debateVsSideBorderSelected: Color.lerp(
        debateVsSideBorderSelected,
        other.debateVsSideBorderSelected,
        t,
      )!,
      debateVsStickerFill:
          Color.lerp(debateVsStickerFill, other.debateVsStickerFill, t)!,
      debateVsStickerBorder:
          Color.lerp(debateVsStickerBorder, other.debateVsStickerBorder, t)!,
      mediaScrim: Color.lerp(mediaScrim, other.mediaScrim, t)!,
      onMediaScrim: Color.lerp(onMediaScrim, other.onMediaScrim, t)!,
      panelShadow: t < 0.5 ? panelShadow : other.panelShadow,
      isDarkShell: t < 0.5 ? isDarkShell : other.isDarkShell,
      surfaceRadius: surfaceRadius + (other.surfaceRadius - surfaceRadius) * t,
    );
  }
}

AppVisualTokens? visualTokensOf(BuildContext context) {
  return Theme.of(context).extension<AppVisualTokens>();
}
