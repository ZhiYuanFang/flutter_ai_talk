import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_provider.dart';

const _kDeviceNoCache = 'pangbao_device_no_v1';

/// 当前宝宝 `deviceNo`：由登录接口、`bindwx`、`auto_save` 写入本地缓存。
class DeviceNoNotifier extends StateNotifier<AsyncValue<String?>> {
  DeviceNoNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> refresh() async {
    final session = ref.read(sessionProvider);
    if (!session.isLoggedIn) {
      state = const AsyncValue.data(null);
      return;
    }
    // 不使用 loading：否则 `asData?.value` 在刷新窗口内为 null，远程仓库无法拉历史。
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_kDeviceNoCache);
      final normalized = (v == null || v.isEmpty) ? null : v;
      state = AsyncValue.data(normalized);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setLocal(String deviceNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceNoCache, deviceNo);
    state = AsyncValue.data(deviceNo);
  }

  Future<void> clearLocal() async {
    state = const AsyncValue.data(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDeviceNoCache);
  }
}

final deviceNoNotifierProvider =
    StateNotifierProvider<DeviceNoNotifier, AsyncValue<String?>>((ref) => DeviceNoNotifier(ref));
