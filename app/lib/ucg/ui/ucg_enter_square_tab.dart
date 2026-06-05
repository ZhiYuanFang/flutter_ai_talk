import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme_scope.dart';
import '../../theme/app_visual_tokens.dart';

/// 喂养页右侧「进入广场」可展开拉条。
class UcgEnterSquareTab extends StatefulWidget {
  const UcgEnterSquareTab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<UcgEnterSquareTab> createState() => _UcgEnterSquareTabState();
}

class _UcgEnterSquareTabState extends State<UcgEnterSquareTab> with SingleTickerProviderStateMixin {
  static const _collapsedWidth = 20.0;
  static const _expandedWidth = 96.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final primary = scheme.primary;
    final border = tokens?.surfaceBorderColor ?? Colors.white.withValues(alpha: 0.22);

    return Positioned(
      right: 0,
      top: MediaQuery.sizeOf(context).height * 0.36,
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final w = lerpDouble(_collapsedWidth, _expandedWidth, _controller.value)!;
            final expanded = _controller.value > 0.35;
            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: w,
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: expanded ? 8 : 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color.alphaBlend(primary.withValues(alpha: 0.18), themePrimaryBlend(context, alpha: 0.2)),
                            Color.alphaBlend(primary.withValues(alpha: 0.08), themePrimaryBlend(context, alpha: 0.12)),
                          ],
                        ),
                        border: Border.all(color: border),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                        boxShadow: tokens?.panelShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 16, color: primary),
                          if (expanded) ...[
                            const SizedBox(height: 8),
                            RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                '进入广场',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
