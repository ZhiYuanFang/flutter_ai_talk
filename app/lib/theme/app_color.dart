import 'package:flutter/material.dart';

import 'app_visual_tokens.dart';

/// 业务取色唯一推荐入口：只选角色，主题分支在 token 派生内完成。
/// 事件品牌色不在此列，继续用 eventAccent / colorHex。
/// UCG 广场/辩论卡外壳挂 [panelGlassGradient]；辩论类别色用 [debateLeftStart] 等。
abstract final class AppColor {
  static AppVisualTokens _tokens(BuildContext context) {
    final t = Theme.of(context).extension<AppVisualTokens>();
    assert(t != null, 'AppVisualTokens missing from Theme');
    return t!;
  }

  static ColorScheme _scheme(BuildContext context) =>
      Theme.of(context).colorScheme;

  /// 整页背景：Scaffold / 全屏壳底（设置页渐变起点、主壳铺底）。
  static Color pageBg(BuildContext context) => _tokens(context).shellColor;

  /// 壳上主文案：AppBar 标题、设置列表主标题、页面一级正文（压在 pageBg/shell 上）。
  static Color textPrimary(BuildContext context) => _tokens(context).onShell;

  /// 壳上次要文案：副标题、说明句、列表辅助信息。
  static Color textSecondary(BuildContext context) =>
      _tokens(context).onShell.withValues(alpha: 0.72);

  /// 壳上弱文案：取消按钮字、「点击更换」类提示、协议灰字。
  static Color textMuted(BuildContext context) =>
      _tokens(context).onShell.withValues(alpha: 0.55);

  /// 分区/面板底：相对 pageBg 略抬起的区块（黏土卡底、分区表面；非 Dialog、非 Feed 浅卡）。
  static Color surface(BuildContext context) => _tokens(context).surfaceColor;

  /// surface 上的正文（压在分区面板上时用，勿与壳上 textPrimary 混场景）。
  static Color textOnSurface(BuildContext context) => _tokens(context).onSurface;

  /// 内容卡底：Feed 动态卡、历史 records 卡等列表内容块（暗壳可偏亮；≠ Dialog 浮层）。
  static Color contentCard(BuildContext context) =>
      _tokens(context).contentCardColor;

  /// 内容卡正文：Feed/历史卡内标题与正文（配对 contentCard）。
  static Color textOnContentCard(BuildContext context) =>
      _tokens(context).onContentCard;

  /// 居中 Dialog / 软引导浮层底：登录·绑定引导、showGlassDialog 默认面板（暗壳为暗浮层）。
  static Color modalFill(BuildContext context) => _tokens(context).modalFill;

  /// modal 描边：引导卡、确认 Dialog 边框。
  static Color modalBorder(BuildContext context) => _tokens(context).modalBorder;

  /// modal 主文案：Dialog 标题、引导卡主句。
  static Color textOnModal(BuildContext context) => _tokens(context).onModal;

  /// modal 次文案：Dialog 说明、引导卡副句。
  static Color textOnModalMuted(BuildContext context) =>
      _tokens(context).onModal.withValues(alpha: 0.72);

  /// 底部 Sheet 面板底：历史编辑玻璃 Sheet 等（当前与 modal 同源）。
  static Color sheetFill(BuildContext context) => _tokens(context).sheetFill;

  /// Sheet 描边。
  static Color sheetBorder(BuildContext context) => _tokens(context).sheetBorder;

  /// Sheet 内主文案：编辑 Sheet 标题/字段字。
  static Color textOnSheet(BuildContext context) => _tokens(context).onSheet;

  /// 输入壳底：TextField / 日期条 / chip 未选中底、轻 inset。
  static Color fieldFill(BuildContext context) => _tokens(context).fieldFill;

  /// 输入壳描边：输入框、未选中 chip 边。
  static Color fieldBorder(BuildContext context) => _tokens(context).fieldBorder;

  /// 主题强调色：FilledButton 底、选中态、链接强调（随设置主题种子）。
  static Color primary(BuildContext context) => _scheme(context).primary;

  /// 压在 primary 实心底上的字/图标（确认钮文字）。
  static Color onPrimary(BuildContext context) => _scheme(context).onPrimary;

  /// 分割线 / 轻描边：列表分隔、内容卡边框（替代硬编码白边）。
  static Color divider(BuildContext context) =>
      _tokens(context).surfaceBorderColor;

  /// 遮罩：Dialog / Sheet 背后的半透明 barrier。
  static Color barrier(BuildContext context) => _tokens(context).barrierColor;

  /// 功能锁定浅透罩：压在 [BackdropFilter] 之上，底图依稀可辨但看不清（勿用实心 panelGlass）。
  static Color lockScrim(BuildContext context) {
    final t = _tokens(context);
    if (t.isDarkShell) {
      return t.shellColor.withValues(alpha: 0.40);
    }
    return t.surfaceColor.withValues(alpha: 0.34);
  }

  /// 页内 chrome 渐变顶：tip / 留意壳 / 预测卡外壳（暗壳为略亮主题色，非近白 contentCard）。
  static Color panelGlassTop(BuildContext context) =>
      _tokens(context).panelGlassTop;

  /// 页内 chrome 渐变底。
  static Color panelGlassBottom(BuildContext context) =>
      _tokens(context).panelGlassBottom;

  /// 压在 panelGlass 上的主文案。
  static Color textOnPanelGlass(BuildContext context) =>
      _tokens(context).onPanelGlass;

  /// 压在 panelGlass 上的次文案。
  static Color textOnPanelGlassMuted(BuildContext context) =>
      _tokens(context).onPanelGlass.withValues(alpha: 0.72);

  /// 页内 chrome 对角渐变；[accent] 非空时用事件/强调色叠在 surface/content 底上（α 封在原子内）。
  /// 亦用于 UCG 广场假玻璃 / 辩论卡外壳（与预测 tip/留意同族）。
  static LinearGradient panelGlassGradient(
    BuildContext context, {
    Color? accent,
  }) {
    final tokens = _tokens(context);
    final Color top;
    if (accent == null) {
      top = tokens.panelGlassTop;
    } else {
      final base =
          tokens.isDarkShell ? tokens.surfaceColor : tokens.contentCardColor;
      top = Color.alphaBlend(
        accent.withValues(alpha: tokens.isDarkShell ? 0.24 : 0.18),
        base,
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [top, tokens.panelGlassBottom],
    );
  }

  /// 辩论左侧条渐变起点。
  static Color debateLeftStart(BuildContext context) =>
      _tokens(context).debateLeftStart;

  /// 辩论左侧条渐变终点。
  static Color debateLeftEnd(BuildContext context) =>
      _tokens(context).debateLeftEnd;

  /// 辩论右侧条渐变起点。
  static Color debateRightStart(BuildContext context) =>
      _tokens(context).debateRightStart;

  /// 辩论右侧条渐变终点。
  static Color debateRightEnd(BuildContext context) =>
      _tokens(context).debateRightEnd;

  /// 辩论左侧标签字色。
  static Color debateLeftLabel(BuildContext context) =>
      _tokens(context).debateLeftLabel;

  /// 辩论左侧百分比字色。
  static Color debateLeftPercent(BuildContext context) =>
      _tokens(context).debateLeftPercent;

  /// 辩论右侧标签字色。
  static Color debateRightLabel(BuildContext context) =>
      _tokens(context).debateRightLabel;

  /// 辩论右侧百分比字色。
  static Color debateRightPercent(BuildContext context) =>
      _tokens(context).debateRightPercent;

  /// VS 中心钮填色。
  static Color debateVsChipFill(BuildContext context) =>
      _tokens(context).debateVsChipFill;

  /// VS 中心钮描边。
  static Color debateVsChipBorder(BuildContext context) =>
      _tokens(context).debateVsChipBorder;

  /// 压在 VS 中心钮上的前景（emoji 区可读底推导）。
  static Color debateVsOnChip(BuildContext context) =>
      _tokens(context).debateVsOnChip;

  /// VS 条外框描边。
  static Color debateVsBarBorder(BuildContext context) =>
      _tokens(context).debateVsBarBorder;

  /// VS 条内浅玻璃顶色。
  static Color debateVsBarGlassTop(BuildContext context) =>
      _tokens(context).debateVsBarGlassTop;

  /// 辩论侧块未选中描边。
  static Color debateVsSideBorder(BuildContext context) =>
      _tokens(context).debateVsSideBorder;

  /// 辩论侧块选中描边。
  static Color debateVsSideBorderSelected(BuildContext context) =>
      _tokens(context).debateVsSideBorderSelected;

  /// 百分比贴纸底。
  static Color debateVsStickerFill(BuildContext context) =>
      _tokens(context).debateVsStickerFill;

  /// 百分比贴纸描边。
  static Color debateVsStickerBorder(BuildContext context) =>
      _tokens(context).debateVsStickerBorder;

  /// 媒体沉浸遮罩（viewer / 全屏预览黑底）。
  static Color mediaScrim(BuildContext context) => _tokens(context).mediaScrim;

  /// 压在媒体遮罩上的字/图标。
  static Color onMediaScrim(BuildContext context) =>
      _tokens(context).onMediaScrim;
}
