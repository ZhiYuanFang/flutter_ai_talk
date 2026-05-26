import 'package:flutter/material.dart';

/// 与 Android 原生启动页视觉对齐的中位色（渐变不可用时的 fallback）。
const kSplashBackgroundColor = Color(0xFFF0EEF2);

const kSplashLogoAsset = 'assets/images/splash_logo.png';

/// 冷启动品牌标语。
const kStartupTagline = '最懂你的胖宝';

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
