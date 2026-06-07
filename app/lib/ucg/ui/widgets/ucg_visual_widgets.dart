import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_theme_scope.dart';
import '../../../theme/app_visual_tokens.dart';
import '../../theme/ucg_theme.dart';

const _kHeaderContentSpacing = 10.0;
const _kShellGlassBlur = 18.0;

/// UCG 页面脚手架：shell 背景 + 安全区，无 AppBar 色块。
class UcgScaffold extends StatelessWidget {
  const UcgScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
  });

  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shellBg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: shellBg,
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// 与 [HomeImmersiveHeader] 同语义：大标题 + 可选副标题，共享 shell 背景。
class UcgImmersiveHeader extends StatelessWidget {
  const UcgImmersiveHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showTitle = true,
  });

  final String title;
  /// When set, replaces centered [title] with a left-aligned compact row (e.g. chat peer avatar + nickname).
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? theme.colorScheme.onSurface;
    const sideSlot = 52.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, 4, 8, showTitle || titleWidget != null ? _kHeaderContentSpacing : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleWidget != null)
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) leading!,
                  Expanded(child: titleWidget!),
                  if (actions.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: actions),
                ],
              ),
            )
          else if (showTitle)
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (leading != null)
                    Positioned(left: 0, top: 0, bottom: 0, child: leading!),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (leading != null || actions.isNotEmpty) ? sideSlot : 16,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                            fontSize: 28,
                            letterSpacing: -0.3,
                          ) ??
                          TextStyle(
                            color: fg,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                    ),
                ],
              ),
            )
          else if (leading != null)
            SizedBox(
              height: 44,
              child: Align(alignment: Alignment.centerLeft, child: leading!),
            ),
          if (titleWidget == null && showTitle && subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg.withValues(alpha: 0.58),
                fontSize: 13,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}

/// Tab 页统一布局：沉浸式顶栏 + 内容区。
class UcgTabPage extends StatelessWidget {
  const UcgTabPage({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.actions = const [],
    required this.body,
    this.headerBottom,
    this.showTitle = true,
  });

  final String title;
  final String? subtitle;
  /// When set, replaces centered [title] with a left-aligned compact row beside [leading].
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? headerBottom;
  final Widget body;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcgImmersiveHeader(
          title: title,
          subtitle: subtitle,
          titleWidget: titleWidget,
          leading: leading,
          actions: actions,
          showTitle: showTitle,
        ),
        if (headerBottom != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: headerBottom!,
          ),
          const SizedBox(height: 12),
        ],
        Expanded(child: body),
      ],
    );
  }
}

/// Shell 上玻璃拟态卡片（磨砂 + 主题色微渐变 + 柔光描边）。
class UcgShellGlassCard extends StatelessWidget {
  const UcgShellGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double? borderRadius;
  final EdgeInsets? margin;

  /// Gradient fill matching the card interior (e.g. sliding pane cover in 我的动态).
  static BoxDecoration interiorFillDecoration(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final isDark = tokens?.isDarkShell ?? false;

    final fillTop = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.14 : 0.10),
      (tokens?.recordsCardColor ?? themePrimaryBlend(context, alpha: 0.14))
          .withValues(alpha: isDark ? 0.72 : 0.82),
    );
    final fillBottom = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.08 : 0.06),
      tokens?.surfaceColor.withValues(alpha: isDark ? 0.55 : 0.65) ??
          themePrimaryBlend(context, alpha: 0.08),
    );

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fillTop, fillBottom],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final radius = borderRadius ?? (tokens?.surfaceRadius ?? 14) + 4;
    final isDark = tokens?.isDarkShell ?? false;

    final fillTop = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.14 : 0.10),
      (tokens?.recordsCardColor ?? themePrimaryBlend(context, alpha: 0.14))
          .withValues(alpha: isDark ? 0.72 : 0.82),
    );
    final fillBottom = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.08 : 0.06),
      tokens?.surfaceColor.withValues(alpha: isDark ? 0.55 : 0.65) ??
          themePrimaryBlend(context, alpha: 0.08),
    );
    final border = tokens?.surfaceBorderColor ?? UcgTheme.surfaceBorder(context);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _kShellGlassBlur, sigmaY: _kShellGlassBlur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [fillTop, fillBottom],
            ),
            boxShadow: tokens?.panelShadow ??
                [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

/// 兼容旧名。
typedef UcgGlassCard = UcgShellGlassCard;

class UcgSectionLabel extends StatelessWidget {
  const UcgSectionLabel({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: fg,
                ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

/// 内嵌 pill 分段（关注/推荐等）。
class UcgSegmentedPills<T> extends StatelessWidget {
  const UcgSegmentedPills({
    super.key,
    required this.segments,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> segments;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onShell = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;

    return UcgShellGlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 999,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final seg in segments) ...[
            if (seg != segments.first) const SizedBox(width: 2),
            _Pill(
              label: labelBuilder(seg),
              selected: seg == selected,
              primary: primary,
              onShell: onShell,
              onTap: () => onSelected(seg),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onShell,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final Color onShell;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Color.alphaBlend(primary.withValues(alpha: 0.22), const Color(0x00000000)) : const Color(0x00000000),
            borderRadius: BorderRadius.circular(999),
            border: selected ? Border.all(color: primary.withValues(alpha: 0.35)) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primary : onShell.withValues(alpha: 0.68),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// 空态 / 占位（可爱、大气）。
class UcgEmptyState extends StatelessWidget {
  const UcgEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: UcgShellGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                  border: Border.all(color: primary.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, size: 32, color: primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fg.withValues(alpha: 0.58), height: 1.4),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Feed 互动条（胶囊底）。
class UcgInteractionChip extends StatelessWidget {
  const UcgInteractionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final color = active ? primary : fg.withValues(alpha: 0.62);

    return Material(
      color: active ? primary.withValues(alpha: 0.1) : tokens?.pillBackground ?? themePrimaryBlend(context, alpha: 0.08),
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? primary.withValues(alpha: 0.35) : (tokens?.pillBorder ?? primary.withValues(alpha: 0.15)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部五栏玻璃悬浮 dock。
class UcgGlassBottomDock extends StatelessWidget {
  const UcgGlassBottomDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onComposeTap,
    this.showMessageBadge = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onComposeTap;
  final bool showMessageBadge;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isDark = tokens?.isDarkShell ?? false;
    final surface = tokens?.surfaceColor ?? themePrimaryBlend(context, alpha: 0.24);
    final border = tokens?.surfaceBorderColor ?? UcgTheme.surfaceBorder(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: border),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  surface.withValues(alpha: isDark ? 0.78 : 0.88),
                  Color.alphaBlend(primary.withValues(alpha: 0.06), surface.withValues(alpha: isDark ? 0.68 : 0.78)),
                ],
              ),
              boxShadow: tokens?.panelShadow,
            ),
            child: SizedBox(
              height: 66,
              child: Row(
                children: [
                  _DockItem(icon: Icons.auto_awesome_rounded, label: '广场', selected: currentIndex == 0, onTap: () => onTap(0)),
                  _DockItem(icon: Icons.diamond_outlined, label: '宝藏', selected: currentIndex == 1, onTap: () => onTap(1)),
                  Expanded(
                    child: Center(
                      child: _ComposeButton(onTap: onComposeTap, primary: primary),
                    ),
                  ),
                  _DockItem(
                    icon: Icons.chat_bubble_rounded,
                    label: '消息',
                    selected: currentIndex == 3,
                    showBadge: showMessageBadge,
                    onTap: () => onTap(3),
                  ),
                  _DockItem(icon: Icons.face_retouching_natural_rounded, label: '我的', selected: currentIndex == 4, onTap: () => onTap(4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onTap, required this.primary});

  final VoidCallback onTap;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final onPrimary = UcgTheme.onPrimary(context);
    return Material(
      color: const Color(0x00000000),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, UcgTheme.primaryGradientEnd(context)],
            ),
            boxShadow: [
              BoxShadow(color: primary.withValues(alpha: 0.38), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Icon(Icons.add_rounded, color: onPrimary, size: 28),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final muted = (tokens?.onShell ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.55);
    final fg = selected ? primary : muted;

    return Expanded(
      child: Material(
        color: const Color(0x00000000),
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: selected ? 10 : 0, vertical: selected ? 4 : 0),
                decoration: selected
                    ? BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: fg, size: selected ? 23 : 21),
                    if (showBadge)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: fg, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部玻璃输入条（聊天、评论等）。
class UcgGlassInputDock extends StatelessWidget {
  const UcgGlassInputDock({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    this.onAttach,
    this.enabled = true,
    this.busy = false,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final primary = Theme.of(context).colorScheme.primary;
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final onPrimary = UcgTheme.onPrimary(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 10),
      child: UcgShellGlassCard(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        borderRadius: 28,
        child: Row(
          children: [
            if (onAttach != null) ...[
              IconButton(
                onPressed: enabled && !busy ? onAttach : null,
                icon: Icon(Icons.add_circle_outline_rounded, color: fg.withValues(alpha: 0.55)),
                tooltip: '添加图片或视频',
              ),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !busy,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  hintStyle: TextStyle(color: fg.withValues(alpha: 0.42)),
                ),
              ),
            ),
            Material(
              color: const Color(0x00000000),
              child: InkWell(
                onTap: enabled && !busy ? onSend : null,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, UcgTheme.primaryGradientEnd(context)],
                    ),
                  ),
                  child: busy
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary.withValues(alpha: 0.9)),
                        )
                      : Icon(Icons.send_rounded, color: onPrimary, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget? ucgBackLeading(BuildContext context, VoidCallback? onBack, {String tooltip = '返回喂养'}) {
  if (onBack == null) return null;
  final tokens = Theme.of(context).extension<AppVisualTokens>();
  final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
  return IconButton(
    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: fg.withValues(alpha: 0.75)),
    tooltip: tooltip,
    onPressed: onBack,
  );
}
