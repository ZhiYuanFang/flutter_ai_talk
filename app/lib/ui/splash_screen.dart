import 'package:flutter/material.dart';

import 'startup_branding.dart';

/// 占位路由；冷启动动画由 [StartupBrandingOverlay] 全屏遮罩负责。
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: startupPageDecoration(),
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.expand(),
      ),
    );
  }
}
