import 'package:flutter/material.dart';

import '../theme/app_visual_tokens.dart';

/// 首页沉浸式头部：不使用 AppBar 色块，和内容区共享 shell 背景语义。
class HomeImmersiveHeader extends StatelessWidget {
  const HomeImmersiveHeader({
    super.key,
    required this.title,
    required this.onTrendsTap,
    required this.onSettingsTap,
  });

  final String title;
  final VoidCallback onTrendsTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? theme.colorScheme.onSurface;

    const actionsWidth = 104.0;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: actionsWidth),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: fg,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.insights, color: fg),
                    tooltip: '趋势',
                    onPressed: onTrendsTap,
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: fg),
                    tooltip: '设置',
                    onPressed: onSettingsTap,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
