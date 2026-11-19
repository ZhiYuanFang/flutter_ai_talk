import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/client_usage_events.dart';
import '../../providers/client_usage_provider.dart';
import '../../providers/home_pager.dart';
import '../../providers/landscape_voice_provider.dart';
import '../../providers/predict_basic_feature_action_providers.dart';

/// pill 外扩 keep 区（logical px）：擦边不取消，需滑出更远。
const kGoRecordHoldKeepInflate = 32.0;

/// 长按进入 PTT 的阈值。
const kGoRecordLongPressMs = 400;

/// 预测竖屏底部：「去记录」短按切喂养；长按按住语音记录。
class PredictionGoRecordFab extends ConsumerStatefulWidget {
  const PredictionGoRecordFab({super.key});

  @override
  ConsumerState<PredictionGoRecordFab> createState() =>
      _PredictionGoRecordFabState();
}

class _PredictionGoRecordFabState extends ConsumerState<PredictionGoRecordFab>
    with SingleTickerProviderStateMixin {
  final _pillKey = GlobalKey();
  Timer? _longPressTimer;
  var _holdArmed = false;
  var _slideCancel = false;
  var _pointerDown = false;

  late final AnimationController _pulse;
  var _pulseLeft = 0;

  @override
  void initState() {
    super.initState();
    // 与预测卡心跳接近：缩放来回三次。
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // 每次心跳：放大再缩回；满 3 次后停。
    _pulse.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        unawaited(_pulse.reverse());
        return;
      }
      if (status != AnimationStatus.dismissed) return;
      if (_pulseLeft <= 0) return;
      _pulseLeft -= 1;
      if (_pulseLeft > 0) {
        unawaited(_pulse.forward());
      }
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// 基础版墙引导：心跳恰 3 次，不开麦。
  void _runHeartbeatThree() {
    _pulseLeft = 3;
    unawaited(_pulse.forward(from: 0));
  }

  Rect? _pillGlobalRect() {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  /// 指针是否仍在 pill+inflate keep 区内。
  bool _inKeepZone(Offset global) {
    final r = _pillGlobalRect();
    if (r == null) return true;
    final keep = r.inflate(kGoRecordHoldKeepInflate);
    return keep.contains(global);
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointerDown = true;
    _holdArmed = false;
    _slideCancel = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(
      const Duration(milliseconds: kGoRecordLongPressMs),
      () {
        if (!_pointerDown || !mounted) return;
        _holdArmed = true;
        // 按住期间锁主壳横滑，避免误切页
        ref.read(homePagerScrollBlockedProvider.notifier).state = true;
        HapticFeedback.mediumImpact();
        setState(() {});
        // startHold 与 endHold 竞态由 controller 协调；失败时字幕会更新，此处刷新 pill。
        unawaited(() async {
          final ok = await ref
              .read(landscapeVoiceControllerProvider.notifier)
              .startHold(context);
          if (!mounted) return;
          if (!ok) {
            // 仍按住时展示失败文案；松手走 endHold noop。
            setState(() {});
          }
        }());
      },
    );
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointerDown || !_holdArmed) return;
    final cancel = !_inKeepZone(e.position);
    if (cancel != _slideCancel) {
      setState(() => _slideCancel = cancel);
    }
  }

  Future<void> _onPointerUp(PointerUpEvent e) async {
    if (!_pointerDown) return;
    _pointerDown = false;
    _longPressTimer?.cancel();
    _longPressTimer = null;

    if (!_holdArmed) {
      // 短按：切喂养
      unawaited(
        ref
            .read(clientUsageReporterProvider)
            .reportEvent(ClientUsageEvents.predictionGoRecordFabTap),
      );
      ref
          .read(homePagerRequestProvider.notifier)
          .requestPage(HomePagerPage.feeding);
      return;
    }

    final cancel = _slideCancel || !_inKeepZone(e.position);
    _holdArmed = false;
    _slideCancel = false;
    ref.read(homePagerScrollBlockedProvider.notifier).state = false;
    setState(() {});
    // endHold 会等待 in-flight startHold，再 commit / 取消。
    await ref
        .read(landscapeVoiceControllerProvider.notifier)
        .endHold(cancel: cancel);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (!_pointerDown) return;
    _pointerDown = false;
    _longPressTimer?.cancel();
    _longPressTimer = null;
    if (_holdArmed) {
      _holdArmed = false;
      _slideCancel = false;
      ref.read(homePagerScrollBlockedProvider.notifier).state = false;
      setState(() {});
      unawaited(
        ref.read(landscapeVoiceControllerProvider.notifier).endHold(cancel: true),
      );
    }
  }

  /// 按住态单行文案：接通中 / 请说话 / 松手发送 / 松开取消 / 失败提示。
  /// 仅当 [chatListening] 为真才显示「请说话…」，避免麦已停仍伪装聆听。
  String _holdLabel(LandscapeVoiceUiState voice) {
    if (_slideCancel) return '松开取消';
    final sub = voice.subtitle.trim();
    if (voice.chatListening) {
      return sub.isNotEmpty ? '松手发送' : '请说话…';
    }
    if (sub.isNotEmpty) return sub;
    return '正在接通…';
  }

  @override
  Widget build(BuildContext context) {
    // 基础版墙关墙后请求心跳指引
    ref.listen<int?>(predictionGoRecordFabPulseRequestProvider, (prev, next) {
      if (next == null) return;
      _runHeartbeatThree();
      ref.read(predictionGoRecordFabPulseRequestProvider.notifier).clear();
    });

    final scheme = Theme.of(context).colorScheme;
    final voice = ref.watch(landscapeVoiceControllerProvider);
    final holding = _holdArmed;
    final cancelArmed = holding && _slideCancel;

    final scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    final label = holding
        ? _holdLabel(voice)
        : '去记录 · 长按语音记录';
    final labelColor = cancelArmed
        ? scheme.onErrorContainer
        : holding
            ? scheme.onTertiaryContainer
            : scheme.onPrimaryContainer;

    return ScaleTransition(
      scale: scale,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Material(
          key: _pillKey,
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          color: cancelArmed
              ? scheme.errorContainer
              : holding
                  ? scheme.tertiaryContainer
                  : scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // 宽度随文案：单行 Row + mainAxisSize.min，避免换行。
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  holding ? Icons.mic : Icons.edit_outlined,
                  size: 20,
                  color: labelColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
