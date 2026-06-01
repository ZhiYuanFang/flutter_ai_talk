import 'package:flutter/material.dart';

/// 与 Android 原生启动页视觉对齐的中位色（渐变不可用时的 fallback）。
const kSplashBackgroundColor = Color(0xFFF0EEF2);

/// 启动中心图标使用与桌面图标同源的主资源，避免品牌双源漂移。
const kStartupIconAsset = 'assets/images/app_icon_round.png';

/// 启动图标尺寸（启动遮罩与 `/splash` 占位页共用）。
const kStartupIconSize = 168.0;

/// 冷启动品牌标语。
const kStartupTagline = '记录宝宝成长每一步';

/// 标语固定品牌蓝（不随性别 primary 变化）。
const kStartupTaglineColor = Color(0xFF2B6CB0);

/// 启动页竖向渐变（上粉 → 近白 → 浅青）。
const kStartupPageGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFF8D4E0),
    Color(0xFFF7F8FA),
    Color(0xFFD4EFF5),
  ],
  stops: [0.0, 0.45, 1.0],
);

BoxDecoration startupPageDecoration() => const BoxDecoration(
      gradient: kStartupPageGradient,
    );

/// 冷启动中心图标：桌面图标同源 + 圆形裁剪 + 填满容器。
///
/// 说明：历史上启动页曾使用 `splash_logo`，本组件统一改为 `kStartupIconAsset`
/// 以保证与桌面图标一致，并通过 `BoxFit.cover` 保证圆形容器无明显留白。
class StartupBrandingIcon extends StatelessWidget {
  const StartupBrandingIcon({
    super.key,
    this.size = kStartupIconSize,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          kStartupIconAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Icon(
            Icons.child_care_rounded,
            size: size * 0.5,
            color: kStartupTaglineColor,
          ),
        ),
      ),
    );
  }
}

/// 启动标语样式：无下划线、无额外行高留白。
const kStartupTaglineTextStyle = TextStyle(
  inherit: false,
  fontSize: 21,
  fontWeight: FontWeight.w700,
  color: kStartupTaglineColor,
  height: 1.0,
  letterSpacing: 0,
  decoration: TextDecoration.none,
  decorationThickness: 0,
);

/// 冷启动遮罩上的品牌标语（纯文字，无装饰线）。
class StartupTaglineText extends StatelessWidget {
  const StartupTaglineText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      kStartupTagline,
      maxLines: 1,
      textAlign: TextAlign.center,
      semanticsLabel: kStartupTagline,
      textHeightBehavior: TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: false,
      ),
      style: kStartupTaglineTextStyle,
    );
  }
}
