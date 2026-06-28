import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 喂养/诊疗等页共用空态：Lottie（或占位图标）+ 标题 + 副标题 + 可选操作按钮。
class AppEmptyStateGallery extends StatelessWidget {
  const AppEmptyStateGallery({
    super.key,
    required this.animationPath,
    required this.title,
    required this.subtitle,
    this.footnote,
    this.actionLabel,
    this.onAction,
    this.fallbackIcon = Icons.child_care,
  });

  static const visualSlotWidth = 240.0;
  static const visualSlotHeight = 128.0;
  static const visualToTitleGap = 8.0;
  static const titleToSubtitleGap = 8.0;
  static const footnoteToActionGap = 20.0;
  static const subtitleToActionGap = 24.0;

  final String animationPath;
  final String title;
  final String subtitle;
  final String? footnote;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData fallbackIcon;

  static bool _shouldUseFallback(LottieComposition? composition) {
    if (composition == null) return false;
    return composition.layers.isEmpty;
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        fallbackIcon,
        size: 120,
        color: theme.colorScheme.primary.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildAnimationSlot(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: visualSlotWidth,
      height: visualSlotHeight,
      child: ClipRect(
        child: Lottie.asset(
          animationPath,
          width: visualSlotWidth,
          height: visualSlotHeight,
          fit: BoxFit.contain,
          addRepaintBoundary: false,
          frameBuilder: (context, child, composition) {
            if (composition == null) {
              return _buildPlaceholder(theme);
            }
            if (_shouldUseFallback(composition)) {
              return _buildPlaceholder(theme);
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimationSlot(context),
            const SizedBox(height: visualToTitleGap),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: titleToSubtitleGap),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: titleToSubtitleGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_left_alt_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      footnote!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(
                height: footnote != null ? footnoteToActionGap : subtitleToActionGap,
              ),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
