import 'package:flutter/material.dart';

import '../startup_branding.dart';

/// 全屏启动遮罩：叠在 [MaterialApp] 子树之上，静态 Logo 与标语。
class StartupBrandingOverlay extends StatelessWidget {
  const StartupBrandingOverlay({super.key});

  static const _logoSize = 168.0;
  static const _taglineFontSize = 21.0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: ColoredBox(
        color: kSplashBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                kSplashLogoAsset,
                width: _logoSize,
                height: _logoSize,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.child_care_rounded,
                  size: _logoSize * 0.5,
                  color: primary,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                kStartupTagline,
                maxLines: 1,
                textAlign: TextAlign.center,
                semanticsLabel: kStartupTagline,
                style: TextStyle(
                  fontSize: _taglineFontSize,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
