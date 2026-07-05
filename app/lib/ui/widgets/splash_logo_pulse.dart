import 'package:flutter/material.dart';

import '../startup_branding.dart';

/// 全屏启动遮罩：叠在 [MaterialApp] 子树之上，静态 Logo 与标语。
class StartupBrandingOverlay extends StatelessWidget {
  const StartupBrandingOverlay({super.key});

  static const _logoTaglineGap = 28.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: startupPageDecoration(),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StartupBrandingIcon(),
              SizedBox(height: _logoTaglineGap),
              StartupTaglineText(),
            ],
          ),
        ),
      ),
    );
  }
}
