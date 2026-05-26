import 'package:flutter/material.dart';

import '../startup_branding.dart';

/// 全屏启动遮罩：叠在 [MaterialApp] 子树之上，静态 Logo 与标语。
class StartupBrandingOverlay extends StatelessWidget {
  const StartupBrandingOverlay({super.key});

  static const _logoSize = 168.0;
  static const _logoTaglineGap = 28.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: startupPageDecoration(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _logoSize,
                height: _logoSize,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.94,
                    child: Image.asset(
                      kSplashLogoAsset,
                      width: _logoSize,
                      height: _logoSize,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.child_care_rounded,
                        size: _logoSize * 0.5,
                        color: kStartupTaglineColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _logoTaglineGap),
              const StartupTaglineText(),
            ],
          ),
        ),
      ),
    );
  }
}
