import 'package:flutter/material.dart';

import '../../data/ucg_feature_flags.dart';
import '../../../theme/app_theme_scope.dart';
import '../../../theme/app_visual_tokens.dart';
import '../../../ui/widgets/managed_keyboard_text_field.dart';
const _kHeaderContentSpacing = 10.0;

/// UCG 页面脚手架：shell 背景 + 安全区，无 AppBar 色块。
class UcgScaffold extends StatelessWidget {
  const UcgScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = false,
  });

  final Widget body;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shellBg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: shellBg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
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

/// Shell 上轻表面卡片（单色浅底、无 blur/阴影）。
class UcgSurfaceCard extends StatelessWidget {
  const UcgSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
    this.margin,
    this.showBorder = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double? borderRadius;
  final EdgeInsets? margin;
  final bool showBorder;

  static Color surfaceFillColor(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    return tokens?.recordsCardColor ?? themePrimaryBlend(context, alpha: 0.06);
  }

  /// 与卡片内填充一致的单色装饰（如滑动面板遮罩）。
  static BoxDecoration interiorFillDecoration(BuildContext context) {
    return BoxDecoration(color: surfaceFillColor(context));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final radius = borderRadius ?? (tokens?.surfaceRadius ?? 14).toDouble();

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceFillColor(context),
        borderRadius: BorderRadius.circular(radius),
        border: showBorder ? Border.all(color: fg.withValues(alpha: 0.08)) : null,
      ),
      child: Padding(padding: padding, child: child),
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

@Deprecated('Use UcgSurfaceCard')
typedef UcgShellGlassCard = UcgSurfaceCard;

@Deprecated('Use UcgSurfaceCard')
typedef UcgGlassCard = UcgSurfaceCard;

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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final seg in segments) ...[
          if (seg != segments.first) const SizedBox(width: 8),
          _Pill(
            label: labelBuilder(seg),
            selected: seg == selected,
            primary: primary,
            onShell: onShell,
            onTap: () => onSelected(seg),
          ),
        ],
      ],
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? primary : onShell.withValues(alpha: 0.55),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// 空态 / 占位。
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
        child: UcgSurfaceCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: primary.withValues(alpha: 0.75)),
              const SizedBox(height: 14),
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

/// Feed 互动条（轻量 icon + 文字）。
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

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部五栏扁平 dock，嵌入 shell 背景。
class UcgBottomDock extends StatelessWidget {
  const UcgBottomDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onComposeTap,
    this.onComposeLongPress,
    this.showMessageBadge = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onComposeTap;
  final VoidCallback? onComposeLongPress;
  final bool showMessageBadge;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _DockItem(icon: Icons.auto_awesome_rounded, label: '广场', selected: currentIndex == 0, onTap: () => onTap(0)),
            if (kUcgTreasureEnabled)
              _DockItem(icon: Icons.diamond_outlined, label: '宝藏', selected: currentIndex == 1, onTap: () => onTap(1)),
            _DockItem(
              icon: Icons.add_rounded,
              label: '发布',
              selected: false,
              onTap: onComposeTap,
              onLongPress: onComposeLongPress,
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
    );
  }
}

@Deprecated('Use UcgBottomDock')
typedef UcgGlassBottomDock = UcgBottomDock;

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
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
          onLongPress: onLongPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
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
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部扁平输入条（聊天等）。
class UcgInputDock extends StatelessWidget {
  const UcgInputDock({
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
    final fieldEnabled = enabled && !busy;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 8),
      child: Row(
        children: [
          if (onAttach != null) ...[
            IconButton(
              onPressed: fieldEnabled ? onAttach : null,
              icon: Icon(Icons.add_circle_outline_rounded, color: fg.withValues(alpha: 0.55)),
              tooltip: '添加图片或视频',
            ),
          ],
          Expanded(
            child: ManagedKeyboardTextField(
              controller: controller,
              hint: hintText,
              scene: 'ucg.chat',
              onConfirm: fieldEnabled ? onSend : null,
              enabled: fieldEnabled,
              textInputAction: TextInputAction.send,
              onSubmitted: fieldEnabled ? (_) => onSend() : null,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: UcgSurfaceCard.surfaceFillColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                hintStyle: TextStyle(color: fg.withValues(alpha: 0.42)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: fieldEnabled ? onSend : null,
            icon: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                  )
                : Icon(Icons.send_rounded, color: primary),
          ),
        ],
      ),
    );
  }
}

@Deprecated('Use UcgInputDock')
typedef UcgGlassInputDock = UcgInputDock;

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
