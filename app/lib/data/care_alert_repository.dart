import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import 'prediction_care_alert.dart';

/// care-alert/daily 快照：列表 + 账号维日用量。
class CareAlertDailySnapshot {
  const CareAlertDailySnapshot({
    required this.items,
    this.usedToday = 0,
    this.dailyLimit = 5,
    this.day = '',
  });

  final List<CareAlertEventItem> items;
  final int usedToday;
  final int dailyLimit;
  final String day;
}

/// SSE 流事件（强制生成路径）。
sealed class CareAlertStreamEvent {
  const CareAlertStreamEvent();
}

class CareAlertThinkingDelta extends CareAlertStreamEvent {
  const CareAlertThinkingDelta(this.content);
  final String content;
}

class CareAlertResultEvent extends CareAlertStreamEvent {
  const CareAlertResultEvent(this.snapshot);
  final CareAlertDailySnapshot snapshot;
}

class CareAlertStreamErrorEvent extends CareAlertStreamEvent {
  const CareAlertStreamErrorEvent({required this.message, this.code = ''});
  final String message;
  final String code;
}

/// 护理留意日缓存 API（Go 编排）；业务/HTTP 失败抛出，由调用方 Toast。
class CareAlertRepository {
  CareAlertRepository(this._api);

  final ApiClient _api;

  /// GET latest；[force]=true 时触发生成（消耗日额度）。deviceNo 空返回 null。
  Future<CareAlertDailySnapshot?> fetchDaily({
    required String deviceNo,
    bool force = false,
  }) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return null;
    try {
      final query = <String, String>{'deviceNo': dn};
      if (force) query['force'] = '1';
      final data = await _api.getEnvelope(
        '/device/api/care-alert/daily',
        query: query,
        timeout: const Duration(seconds: 90),
      );
      final items = parseCareAlertEventItems(data?['items']);
      final usedToday = (data?['usedToday'] as num?)?.toInt() ?? 0;
      final dailyLimit = (data?['dailyLimit'] as num?)?.toInt() ?? 5;
      final day = (data?['day'] as String?)?.trim() ?? '';
      AppDebugLog.careAlert(
        'daily ok deviceNoLen=${dn.length} count=${items.length} '
        'day=$day used=$usedToday/$dailyLimit',
      );
      return CareAlertDailySnapshot(
        items: items,
        usedToday: usedToday,
        dailyLimit: dailyLimit > 0 ? dailyLimit : 5,
        day: day,
      );
    } on ApiBusinessException catch (e) {
      AppDebugLog.careAlert('daily business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.careAlert('daily http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.careAlert('daily err=$e');
      rethrow;
    }
  }

  /// GET force 生成 SSE：thinking → result(items+用量)。
  Stream<CareAlertStreamEvent> analyzeStream({required String deviceNo}) async* {
    final dn = deviceNo.trim();
    if (dn.isEmpty) {
      yield const CareAlertStreamErrorEvent(
        code: 'DEVICE_REQUIRED',
        message: '设备未就绪，请稍后重试',
      );
      return;
    }

    final client = http.Client();
    try {
      final base = Uri.parse(_api.baseUrl);
      final path = base.path.endsWith('/')
          ? '${base.path}device/api/care-alert/daily/stream'
          : '${base.path}/device/api/care-alert/daily/stream';
      final uri = base.replace(
        path: path,
        queryParameters: {'deviceNo': dn},
      );

      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream';

      final token = _api.accessTokenProvider();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await client.send(request).timeout(
            const Duration(seconds: 120),
          );

      if (response.statusCode != 200) {
        final bodyStr = await response.stream.bytesToString();
        try {
          final decoded = jsonDecode(bodyStr);
          if (decoded is Map) {
            final message = (decoded['message'] ?? '').toString();
            yield CareAlertStreamErrorEvent(
              message: message.isNotEmpty ? message : '分析失败，请稍后重试',
            );
            return;
          }
        } catch (_) {}
        yield CareAlertStreamErrorEvent(
          message: '分析失败（HTTP ${response.statusCode}）',
        );
        return;
      }

      var currentEvent = '';
      var buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        var lineEnd = 0;
        while ((lineEnd = buffer.indexOf('\n')) != -1) {
          final rawLine = buffer.substring(0, lineEnd);
          buffer = buffer.substring(lineEnd + 1);
          final line = rawLine.trimRight();
          if (line.isEmpty) {
            currentEvent = '';
            continue;
          }
          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
            continue;
          }
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;

          Map<String, dynamic>? map;
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic>) {
              map = decoded;
            } else if (decoded is Map) {
              map = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {
            if (currentEvent == 'thinking' || currentEvent.isEmpty) {
              yield CareAlertThinkingDelta(data);
            }
            continue;
          }
          if (map == null) continue;

          final type = currentEvent.isNotEmpty
              ? currentEvent
              : (map['type'] ?? '').toString();

          switch (type) {
            case 'thinking':
              final content = (map['content'] ?? '').toString();
              if (content.isNotEmpty) {
                yield CareAlertThinkingDelta(content);
              }
            case 'result':
              final items = parseCareAlertEventItems(map['items']);
              final usedToday = (map['usedToday'] as num?)?.toInt() ?? 0;
              final dailyLimit = (map['dailyLimit'] as num?)?.toInt() ?? 5;
              final day = (map['day'] as String?)?.trim() ?? '';
              yield CareAlertResultEvent(
                CareAlertDailySnapshot(
                  items: items,
                  usedToday: usedToday,
                  dailyLimit: dailyLimit > 0 ? dailyLimit : 5,
                  day: day,
                ),
              );
            case 'error':
              final message = (map['message'] ?? '').toString();
              yield CareAlertStreamErrorEvent(
                code: (map['code'] ?? '').toString(),
                message: message.isNotEmpty ? message : '分析失败，请稍后重试',
              );
            case 'done':
              return;
            default:
              break;
          }
        }
      }
    } catch (e) {
      AppDebugLog.careAlert('analyzeStream err=$e');
      yield const CareAlertStreamErrorEvent(message: '分析失败，请稍后重试');
    } finally {
      client.close();
    }
  }

  /// 从当日缓存删除单条 suggestionId（DELETE + query，对齐现有 ApiClient）。
  Future<bool> deleteDailyItem({
    required String deviceNo,
    required String suggestionId,
  }) async {
    final dn = deviceNo.trim();
    final id = suggestionId.trim();
    if (dn.isEmpty || id.isEmpty) return false;
    try {
      await _api.deleteEnvelope(
        '/device/api/care-alert/daily/item',
        query: {'deviceNo': dn, 'suggestionId': id},
      );
      AppDebugLog.careAlert('delete item ok idLen=${id.length}');
      return true;
    } catch (e) {
      AppDebugLog.careAlert('delete item err=$e');
      return false;
    }
  }

  /// 已废弃：Care 无飞轮；ignore/follow_up 仅本地/日缓存 UI。
  @Deprecated('Care 无飞轮；勿再调用')
  Future<bool> postFeedback({
    required String deviceNo,
    required String suggestionId,
    required String intent,
  }) async {
    AppDebugLog.careAlert(
      'postFeedback noop intent=${intent.trim()} (Care flywheel retired)',
    );
    return true;
  }
}
