import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// 底部偏上字幕条：panelGlass；思考态浅字+慢弱脉冲；首次挂载短淡入。
class LandscapeVoiceSubtitleToast extends StatefulWidget {
  const LandscapeVoiceSubtitleToast({
    super.key,
    required this.text,
    required this.isThinking,
    this.breathe = false,
  });

  final String text;
  final bool isThinking;

  /// 状态字幕与思考字幕共用呼吸透明度。
  final bool breathe;

  @override
  State<LandscapeVoiceSubtitleToast> createState() =>
      _LandscapeVoiceSubtitleToastState();
}

class _LandscapeVoiceSubtitleToastState
    extends State<LandscapeVoiceSubtitleToast> with TickerProviderStateMixin {
  late final AnimationController _fade;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // 仅挂载时淡入；换字不重置。
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    // 思考态慢弱脉冲（约 1.5s 往返）。
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _syncPulse(widget.isThinking || widget.breathe);
  }

  @override
  void didUpdateWidget(covariant LandscapeVoiceSubtitleToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅 kind 切入/离开 thinking 时启停；换字不重启相位。
    final pulse = widget.isThinking || widget.breathe;
    if (oldWidget.isThinking != widget.isThinking ||
        oldWidget.breathe != widget.breathe) {
      _syncPulse(pulse);
    }
  }

  void _syncPulse(bool thinking) {
    if (thinking) {
      if (!_pulse.isAnimating) {
        unawaited(_pulse.repeat(reverse: true));
      }
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onGlass = AppColor.textOnPanelGlass(context);
    // 思考用 muted，答案/ASR 满对比。
    final textColor = widget.isThinking
        ? AppColor.textOnPanelGlassMuted(context)
        : onGlass.withValues(alpha: 0.95);
    const toastRadius = 16.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_fade, _pulse]),
      builder: (context, child) {
        // 挂载淡入 × 思考脉冲（非思考时 pulse=1）。
        final pulseOn = widget.isThinking || widget.breathe;
        final pulseOpacity = pulseOn ? (0.65 + 0.35 * _pulse.value) : 1.0;
        return Opacity(
          opacity: _fade.value * pulseOpacity,
          child: child,
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColor.panelGlassGradient(context),
              borderRadius: BorderRadius.circular(toastRadius),
              border: Border.all(
                color: onGlass.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: textColor,
                // 压掉父级/OEM 拼写检查带来的黄下划线
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
