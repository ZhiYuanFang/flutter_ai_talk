import 'models.dart';

abstract class FeedRepository {
  Future<List<HistoryRecord>> loadHistory();
  Future<HistoryRecord?> getRecord(String id);
  Future<void> updateHistoryRecord(String id, {String? eventName, String? action});
  /// 提交自然语言指令；服务端在 `data.reply` 返回文本回复（可为空）。
  Future<String?> sendCommand(String text);
  Stream<SseHistoryPayload> watchLatest();
}
