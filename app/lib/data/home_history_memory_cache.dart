import 'models.dart';

/// 进程内历史热缓存：Activity 重建但 Dart VM 未重启时，首帧可同步恢复列表。
class HomeHistoryMemoryCache {
  HomeHistoryMemoryCache._();

  static String? _deviceNo;
  static List<HistoryRecord> _items = const [];

  static List<HistoryRecord> peek(String? deviceNo) {
    if (deviceNo == null || deviceNo.isEmpty) return const [];
    if (_deviceNo != deviceNo || _items.isEmpty) return const [];
    return _items;
  }

  static void update(String? deviceNo, List<HistoryRecord> items) {
    if (deviceNo == null || deviceNo.isEmpty || items.isEmpty) return;
    _deviceNo = deviceNo;
    _items = List<HistoryRecord>.unmodifiable(items);
  }

  static void clear() {
    _deviceNo = null;
    _items = const [];
  }
}
