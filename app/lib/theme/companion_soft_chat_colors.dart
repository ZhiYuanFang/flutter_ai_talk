import 'package:flutter/material.dart';

import 'app_visual_tokens.dart';

/// 树洞「柔和拟态」软聊色：由当前主题 seed / ColorScheme 衍生，不写死粉色。
class CompanionSoftChatColors {
  const CompanionSoftChatColors({
    required this.pageBg,
    required this.assistantBubble,
    required this.userBubble,
    required this.inputBar,
    required this.onBubble,
    required this.softShadows,
    required this.inputShadows,
  });

  /// 对话区页底（明显浅于气泡，拉开层次）
  final Color pageBg;

  /// 助手气泡填色
  final Color assistantBubble;

  /// 用户气泡填色
  final Color userBubble;

  /// 底部输入区填色（主色 tint，忌近白卡片）
  final Color inputBar;

  /// 气泡上正文色
  final Color onBubble;

  /// 气泡：右下暗 + 左上亮
  final List<BoxShadow> softShadows;

  /// 输入栏：极轻双阴影（保留一点浮起，避免「外框卡片」轮廓）
  final List<BoxShadow> inputShadows;

  static CompanionSoftChatColors of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final isDark = tokens?.isDarkShell ?? false;
    final primary = scheme.primary;
    final surface = tokens?.surfaceColor ?? scheme.surface;

    if (isDark) {
      // 页底更浅（相对气泡），气泡 tint 更高；输入介于页底与气泡之间
      final pageBg = Color.alphaBlend(primary.withValues(alpha: 0.06), surface);
      final assistant = Color.alphaBlend(
        primary.withValues(alpha: 0.22),
        scheme.surfaceContainerHighest,
      );
      final user = scheme.surfaceContainerHigh;
      // 输入：主色 / primaryContainer tint，随主题，非近白
      final input = Color.alphaBlend(
        scheme.primaryContainer.withValues(alpha: 0.55),
        Color.alphaBlend(primary.withValues(alpha: 0.16), pageBg),
      );
      final bubbleShadows = <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 14,
          offset: const Offset(3, 5),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.07),
          blurRadius: 10,
          offset: const Offset(-2, -2),
        ),
      ];
      // 输入阴影：极轻，去「白卡片外框」
      final inputShadows = <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 8,
          offset: const Offset(2, 3),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.05),
          blurRadius: 5,
          offset: const Offset(-1, -1),
        ),
      ];
      return CompanionSoftChatColors(
        pageBg: pageBg,
        assistantBubble: assistant,
        userBubble: user,
        inputBar: input,
        onBubble: scheme.onSurface,
        softShadows: bubbleShadows,
        inputShadows: inputShadows,
      );
    }

    // 页底：近白极淡；气泡：明显 tint；输入：主色 tint（方案 B，非近白卡片）
    final pageBg = Color.alphaBlend(
      primary.withValues(alpha: 0.2),
      Color.alphaBlend(Colors.white.withValues(alpha: 0.88), surface),
    );
    final assistant = Color.alphaBlend(
      primary.withValues(alpha: 0.3),
      Colors.white,
    );
    final user = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.92),
      pageBg,
    );
    // 输入填色：primaryContainer + primary 叠页底，随主题可见
    final input = Color.alphaBlend(
      scheme.primaryContainer.withValues(alpha: 0.70),
      Color.alphaBlend(primary.withValues(alpha: 0.10), pageBg),
    );
    final onBubble = tokens?.onRecordsCard ?? scheme.onSurface;

    final bubbleShadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 14,
        offset: const Offset(4, 6),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.90),
        blurRadius: 10,
        offset: const Offset(-3, -3),
      ),
    ];
    // 输入阴影：极轻，弱化「外框」轮廓，仍留一点浮起
    final inputShadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(2, 3),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.45),
        blurRadius: 5,
        offset: const Offset(-1, -1),
      ),
    ];

    return CompanionSoftChatColors(
      pageBg: pageBg,
      assistantBubble: assistant,
      userBubble: user,
      inputBar: input,
      onBubble: onBubble,
      softShadows: bubbleShadows,
      inputShadows: inputShadows,
    );
  }
}
