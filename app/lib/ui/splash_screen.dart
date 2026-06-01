import 'package:flutter/material.dart';

import 'startup_branding.dart';

/// 占位路由；冷启动动画由 [StartupBrandingOverlay] 全屏遮罩负责。
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _iconTaglineGap = 28.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: startupPageDecoration(),
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StartupBrandingIcon(),
                SizedBox(height: _iconTaglineGap),
                StartupTaglineText(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
