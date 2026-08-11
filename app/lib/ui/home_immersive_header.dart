import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_visual_tokens.dart';
import 'widgets/baby_avatar.dart';
import 'theme_palette_sheet.dart';

/// 首页沉浸式头部：不使用 AppBar 色块，和内容区共享 shell 背景语义。
/// 左侧宝宝身份横条（头像可进设置），右侧趋势 + 调色盘（最右）。
class HomeImmersiveHeader extends StatelessWidget {
  const HomeImmersiveHeader({
    super.key,
    required this.babyId,
    required this.sex,
    required this.nickname,
    required this.ageText,
    required this.onAvatarTap,
    required this.onTrendsTap,
  });

  final String babyId;
  final BabySex sex;
  /// 已回退的昵称（空则调用方应传入「宝宝」）。
  final String nickname;
  /// 已格式化的月龄文案；空串表示不展示月龄段（未登录/未绑定）。
  final String ageText;
  final VoidCallback onAvatarTap;
  final VoidCallback onTrendsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? theme.colorScheme.onSurface;
    // 无月龄时仅昵称；有月龄时「昵称 · 月龄」，超长尾部省略。
    final identityLine =
        ageText.trim().isEmpty ? nickname : '$nickname · $ageText';

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          // 仅头像可点 → 设置；昵称/月龄无手势。
          BabyAvatar(
            babyId: babyId,
            sex: sex,
            radius: 17,
            onTap: onAvatarTap,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              identityLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.insights, color: fg),
            tooltip: '趋势',
            onPressed: onTrendsTap,
          ),
          const ThemePaletteIconButton(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
