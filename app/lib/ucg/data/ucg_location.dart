import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/app_debug_log.dart';

typedef UcgCoords = ({double lat, double lng});

/// 广场顶部定位提示类型。
enum UcgLocationHintKind {
  none,

  /// 系统定位/GPS 总开关未开。
  gpsServiceOff,

  /// App 位置权限未授予或被 session 拒绝。
  appPermissionDenied,
}

/// Session 内用户拒绝 UCG 定位后不再 request。
final ucgLocationDeniedThisSessionProvider =
    StateProvider<bool>((ref) => false);

/// 广场横幅提示类型（GPS 关 vs App 权限）。
final ucgLocationHintKindProvider =
    StateProvider<UcgLocationHintKind>((ref) => UcgLocationHintKind.none);

class UcgCachedCoords {
  const UcgCachedCoords({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  final double lat;
  final double lng;
  final DateTime updatedAt;
}

/// UCG 坐标协调器。
///
/// 业务说明：发布包已剔除 geolocator；定位能力固定为未启用桩实现，
/// 所有读坐标 / 申请权限路径返回空或拒绝，避免扫包检出定位 SDK。
///
/// 开通 UCG 定位前恢复清单：pubspec 加回 geolocator → 还原本文件真实现 →
/// Manifest LOCATION + 隐私披露 → 扫包确认有意进包。
class UcgLocationCoordinator extends Notifier<UcgCachedCoords?> {
  Future<UcgCoords?>? _refreshInFlight;

  UcgCoords? get cached {
    final entry = state;
    if (entry == null) return null;
    return (lat: entry.lat, lng: entry.lng);
  }

  @override
  UcgCachedCoords? build() => null;

  /// 已授权时读缓存；无定位 SDK 时恒为未授权。
  Future<UcgCoords?> coordsIfGranted() async {
    if (!await _isPermissionGranted()) return null;
    return cached;
  }

  bool _refreshTriggered = false;

  Future<UcgCoords?> getOrWaitInitial() async {
    final existing = cached;
    if (existing != null) return existing;
    if (!_refreshTriggered) {
      _refreshTriggered = true;
      unawaited(refreshOnce());
    }
    return null;
  }

  Future<UcgCoords?> refreshOnce({
    Duration timeLimit = const Duration(seconds: 8),
    bool preferLastKnown = false,
  }) async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshOnceBody(
      timeLimit: timeLimit,
      preferLastKnown: preferLastKnown,
    );
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<UcgCoords?> _refreshOnceBody({
    required Duration timeLimit,
    required bool preferLastKnown,
  }) async {
    // 无定位 SDK：不刷新坐标。
    AppDebugLog.ucgLocation(
      'refreshOnce skipped (geolocator removed) preferLastKnown=$preferLastKnown limit=${timeLimit.inSeconds}s',
    );
    return cached;
  }

  /// 发布包无定位权限与 SDK，恒为未授予。
  Future<bool> _isPermissionGranted() async {
    if (kIsWeb) return false;
    return false;
  }
}

final ucgLocationCoordinatorProvider =
    NotifierProvider<UcgLocationCoordinator, UcgCachedCoords?>(
  UcgLocationCoordinator.new,
);

/// 已授权时读取坐标；不弹窗、不 request（供详情等无 context 场景）。
Future<UcgCoords?> readCurrentCoordsIfGranted(Ref ref) async {
  return ref.read(ucgLocationCoordinatorProvider.notifier).coordsIfGranted();
}

/// UCG 主动场景：定位已下线，直接标记权限不可用。
Future<UcgCoords?> ensureUcgLocationForDistance(
  BuildContext context,
  WidgetRef ref,
) async {
  if (kIsWeb) return null;
  // context 保留与调用方签名一致（入口关闭时仍可能被编译引用）。
  if (!context.mounted) return null;
  ref.read(ucgLocationHintKindProvider.notifier).state =
      UcgLocationHintKind.appPermissionDenied;
  AppDebugLog.ucgLocation('ensure aborted: geolocator removed');
  return null;
}

/// 打开应用设置：无定位 SDK 时为空操作。
Future<void> openUcgAppLocationSettings() async {}

/// 打开系统定位设置：无定位 SDK 时为空操作。
Future<void> openUcgLocationServiceSettings() async {}
