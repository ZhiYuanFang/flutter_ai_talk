import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geolocator/geolocator.dart';

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

const _ucgLocationRationaleTitle = '使用定位';
const _ucgLocationRationaleBody = '用于展示动态与你的距离。拒绝后仍可使用广场，只是不显示距离。';

const _ucgLocationBackgroundInterval = Duration(minutes: 10);

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

/// 唯一写入 UCG 坐标；业务侧只读缓存，首冷无缓存时才同步等待 GPS。
class UcgLocationCoordinator extends Notifier<UcgCachedCoords?> {
  Timer? _backgroundTimer;
  Future<UcgCoords?>? _refreshInFlight;

  UcgCoords? get cached {
    final entry = state;
    if (entry == null) return null;
    return (lat: entry.lat, lng: entry.lng);
  }

  @override
  UcgCachedCoords? build() {
    ref.onDispose(_stopBackgroundTimer);
    return null;
  }

  /// 已授权时读缓存；无缓存则同步刷新一次（供详情等无 context 场景）。
  Future<UcgCoords?> coordsIfGranted() async {
    if (!await _isPermissionGranted()) return null;
    final existing = cached;
    if (existing != null) {
      final entry = state!;
      final ageSec = DateTime.now().difference(entry.updatedAt).inSeconds;
      AppDebugLog.ucgLocation('coordsIfGranted cache hit age=${ageSec}s');
      return existing;
    }
    AppDebugLog.ucgLocation('coordsIfGranted cache miss, refreshing GPS');
    final sw = Stopwatch()..start();
    final result = await refreshOnce();
    AppDebugLog.ucgLocation(
      'coordsIfGranted refresh done ${sw.elapsedMilliseconds}ms hasCoords=${result != null}',
    );
    return result;
  }

  bool _refreshTriggered = false;

  Future<UcgCoords?> getOrWaitInitial() async {
    final existing = cached;
    if (existing != null) {
      final entry = state!;
      final ageSec = DateTime.now().difference(entry.updatedAt).inSeconds;
      AppDebugLog.ucgLocation(
          'cache hit age=${ageSec}s lat=${entry.lat} lng=${entry.lng}');
      return existing;
    }

    AppDebugLog.ucgLocation('cache miss, refreshing GPS');
    if (!_refreshTriggered) {
      _refreshTriggered = true;
      refreshOnce();
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
    if (!await _isPermissionGranted()) return cached;

    try {
      final coords = await _fetchPosition(
        timeLimit: timeLimit,
        preferLastKnown: preferLastKnown,
      );
      if (coords != null) {
        state = UcgCachedCoords(
          lat: coords.lat,
          lng: coords.lng,
          updatedAt: DateTime.now(),
        );
        _ensureBackgroundTimer();
      }
      return coords ?? cached;
    } catch (_) {
      return cached;
    }
  }

  void _ensureBackgroundTimer() {
    if (_backgroundTimer != null) return;
    _backgroundTimer = Timer.periodic(_ucgLocationBackgroundInterval, (_) {
      unawaited(
        refreshOnce(
          timeLimit: const Duration(seconds: 3),
          preferLastKnown: true,
        ),
      );
    });
  }

  void _stopBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  Future<bool> _isPermissionGranted() async {
    if (kIsWeb) return false;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      final perm = await Geolocator.checkPermission();
      return perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<UcgCoords?> _fetchPosition({
    required Duration timeLimit,
    required bool preferLastKnown,
  }) async {
    if (preferLastKnown) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return (lat: last.latitude, lng: last.longitude);
      }
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: timeLimit,
      ),
    );
    return (lat: pos.latitude, lng: pos.longitude);
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

/// UCG 主动场景：先检测 GPS，再用途说明与系统权限；session 拒绝后不再 request。
Future<UcgCoords?> ensureUcgLocationForDistance(
  BuildContext context,
  WidgetRef ref,
) async {
  if (kIsWeb) return null;

  void setHint(UcgLocationHintKind kind) {
    ref.read(ucgLocationHintKindProvider.notifier).state = kind;
  }

  final coordinator = ref.read(ucgLocationCoordinatorProvider.notifier);

  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setHint(UcgLocationHintKind.gpsServiceOff);
      AppDebugLog.ucgLocation('ensure aborted: gps service off');
      return null;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      setHint(UcgLocationHintKind.none);
      AppDebugLog.ucgLocation('ensure permission granted');
      return coordinator.getOrWaitInitial();
    }

    if (perm == LocationPermission.deniedForever ||
        ref.read(ucgLocationDeniedThisSessionProvider)) {
      setHint(UcgLocationHintKind.appPermissionDenied);
      AppDebugLog.ucgLocation('ensure aborted: permission denied');
      return null;
    }

    if (!context.mounted) return null;
    AppDebugLog.ucgLocation('ensure showing consent dialog');
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(_ucgLocationRationaleTitle),
        content: const Text(_ucgLocationRationaleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('暂不'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );

    if (proceed != true) {
      ref.read(ucgLocationDeniedThisSessionProvider.notifier).state = true;
      setHint(UcgLocationHintKind.appPermissionDenied);
      return null;
    }

    perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      setHint(UcgLocationHintKind.none);
      return coordinator.getOrWaitInitial();
    }

    ref.read(ucgLocationDeniedThisSessionProvider.notifier).state = true;
    setHint(UcgLocationHintKind.appPermissionDenied);
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> openUcgAppLocationSettings() => Geolocator.openAppSettings();

Future<void> openUcgLocationServiceSettings() =>
    Geolocator.openLocationSettings();
