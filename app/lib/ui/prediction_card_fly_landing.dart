import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'history_event_fly_landing.dart';

/// 预测页落点：root 预测卡当前展示 logo 槽。
class PredictionCardFlyLanding implements HistoryEventFlyLanding {
  PredictionCardFlyLanding({required this.logoAnchorKey});

  final GlobalKey? logoAnchorKey;

  static const _maxPrepareFrames = 24;

  @override
  Future<bool> prepare() async {
    for (var i = 0; i < _maxPrepareFrames; i++) {
      final ctx = logoAnchorKey?.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: i == 0
              ? const Duration(milliseconds: 280)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
        await SchedulerBinding.instance.endOfFrame;
        if (isAnchorVisible) return true;
      } else {
        await SchedulerBinding.instance.endOfFrame;
      }
    }
    return isAnchorVisible;
  }

  @override
  Offset? measureGlobalCenter() => measureGlobalCenterForKey(logoAnchorKey);

  @override
  bool get isAnchorVisible {
    final c = measureGlobalCenter();
    if (c == null) return false;
    // 粗略：有布局即视为可飞；精细可视由 ensureVisible 保证
    return true;
  }
}

/// 预测卡 logo 锚点注册表（按 root eventId）。
class PredictionLogoAnchorRegistry {
  final _keys = <String, GlobalKey>{};

  GlobalKey keyFor(String rootEventId) {
    final id = rootEventId.trim();
    return _keys.putIfAbsent(id, GlobalKey.new);
  }

  GlobalKey? maybeKey(String rootEventId) {
    final id = rootEventId.trim();
    if (id.isEmpty) return null;
    return _keys[id];
  }

  void retainOnly(Iterable<String> liveRootIds) {
    final live = liveRootIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    _keys.removeWhere((id, _) => !live.contains(id));
  }
}
