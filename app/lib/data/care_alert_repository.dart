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

      // 日限等预检在开 SSE 头之前失败：HTTP 200 + application/json 业务壳。
      final contentType = (response.headers['content-type'] ?? '').toLowerCase();
      final jsonBody = contentType.contains('application/json');
      if (response.statusCode != 200 || jsonBody) {
        final bodyStr = await response.stream.bytesToString();
        final envelope = _tryBusinessEnvelope(bodyStr);
        // 非 200 的壳一律当失败；200 仅 code 非 0（日限 40304）才当失败。
        if (envelope != null &&
            (response.statusCode != 200 ||
                (envelope.code != null && envelope.code != 0))) {
          final message = envelope.message.trim();
          AppDebugLog.careAlert(
            'stream envelope code=${envelope.code} msgLen=${message.length}',
          );
          yield CareAlertStreamErrorEvent(
            code: envelope.code == null ? '' : '${envelope.code}',
            message: message.isNotEmpty ? message : '分析失败，请稍后重试',
          );
          return;
        }
        yield CareAlertStreamErrorEvent(
          message: response.statusCode == 200
              ? '分析失败，请稍后重试'
              : '分析失败（HTTP ${response.statusCode}）',
        );
        return;
      }

      var currentEvent = '';
      var buffer = '';
      // 尚未看到 SSE 帧时攒原文，防止 Content-Type 被改写后整包 JSON 被丢掉。
      var sawSseFrame = false;
      final preamble = StringBuffer();

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
          if (!sawSseFrame &&
              !line.startsWith('event:') &&
              !line.startsWith('data:')) {
            preamble.writeln(line);
            continue;
          }
          sawSseFrame = true;
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
      // 没有 SSE 帧：可能是不带换行的业务壳（Content-Type 未标成 JSON）。
      if (!sawSseFrame) {
        final raw = '${preamble.toString()}$buffer';
        final envelope = _tryBusinessEnvelope(raw);
        if (envelope != null && envelope.code != null && envelope.code != 0) {
          final message = envelope.message.trim();
          AppDebugLog.careAlert(
            'stream preamble envelope code=${envelope.code} msgLen=${message.length}',
          );
          yield CareAlertStreamErrorEvent(
            code: '${envelope.code}',
            message: message.isNotEmpty ? message : '分析失败，请稍后重试',
          );
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

/// `{code, message}` 业务壳；不是 JSON 对象时返回 null。
class _BusinessEnvelope {
  const _BusinessEnvelope({required this.code, required this.message});

  final int? code;
  final String message;
}

_BusinessEnvelope? _tryBusinessEnvelope(String body) {
  final trimmed = body.trim();
  // 不是对象开头就不是 envelope，避免把 SSE 残行当 JSON 去解析。
  if (trimmed.isEmpty || !trimmed.startsWith('{')) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map) return null;
    final codeVal = decoded['code'];
    int? code;
    if (codeVal is int) {
      code = codeVal;
    } else if (codeVal is num) {
      code = codeVal.toInt();
    } else if (codeVal != null) {
      code = int.tryParse('$codeVal');
    }
    return _BusinessEnvelope(
      code: code,
      message: (decoded['message'] ?? '').toString(),
    );
  } catch (e) {
    AppDebugLog.careAlert('envelope parse err=$e');
    return null;
  }
}
