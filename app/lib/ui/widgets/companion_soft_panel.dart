import 'package:flutter/material.dart';

import '../../theme/companion_soft_chat_colors.dart';

/// 树洞柔和拟态面板：近实心填色 + 双阴影，无 BackdropFilter（区别于玻璃拟态）。
class CompanionSoftPanel extends StatelessWidget {
  const CompanionSoftPanel({
    super.key,
    required this.child,
    required this.fill,
    this.contentPadding,
    this.borderRadius = 18,
    this.shadows,
  });

  final Widget child;
  final Color fill;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final soft = CompanionSoftChatColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? soft.softShadows,
      ),
      padding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: child,
    );
  }
}
