import 'package:flutter/material.dart';

/// 占位路由；冷启动动画由 [StartupBrandingOverlay] 全屏遮罩负责。
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: SizedBox.expand(),
    );
  }
}
