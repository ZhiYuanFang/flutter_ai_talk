import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// 通用 modal 玻璃面板：底/边/默认字色绑定 [AppColor.modal*] 原子。
class AppModalGlassPanel extends StatelessWidget {
  const AppModalGlassPanel({
    super.key,
    required this.child,
    this.onClose,
    this.eventAccent,
    this.contentPadding,
    this.borderRadius = 20,
    this.blurSigma = 16,
  });

  final Widget child;
  final VoidCallback? onClose;
  final Color? eventAccent;
  final EdgeInsets? contentPadding;
  final double borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final fill = AppColor.modalFill(context);
    final border = AppColor.modalBorder(context);
    final onModal = AppColor.textOnModal(context);
    // 事件 accent 仅作渐变强调，不覆盖 modal 角色底
    final accent = eventAccent ?? AppColor.primary(context);
    final fillBottom = Color.alphaBlend(
      accent.withValues(alpha: 0.18),
      fill,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [fill, fillBottom],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: contentPadding ??
                    const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: onModal),
                  child: child,
                ),
              ),
              if (onClose != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, size: 22, color: onModal.withValues(alpha: 0.92)),
                    tooltip: '关闭',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
