import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import 'growth_trajectory_models.dart';

/// 成长轨迹 API：latest JSON + turn SSE（失败抛业务异常或产出 error 事件）。
class GrowthTrajectoryRepository {
  GrowthTrajectoryRepository(this._api);

  final ApiClient _api;

  /// GET 最新 Markdown；无结果时 markdown 为空。
  Future<GrowthTrajectoryLatest?> fetchLatest({
    required String deviceNo,
  }) async {
    final dn = deviceNo.trim();
    if (dn.isEmpty) return null;
    try {
      final data = await _api.getEnvelope(
        '/device/api/growth-trajectory/latest',
        query: {'deviceNo': dn},
        timeout: const Duration(seconds: 30),
      );
      final latest = GrowthTrajectoryLatest.fromJson(data);
      AppDebugLog.growthTrajectory(
        'latest ok hasResult=${latest.hasResult} sessionLen=${latest.sessionId.length}',
      );
      return latest;
    } on ApiBusinessException catch (e) {
      AppDebugLog.growthTrajectory('latest business err=${e.code} ${e.message}');
      rethrow;
    } on ApiHttpException catch (e) {
      AppDebugLog.growthTrajectory('latest http err=${e.statusCode}');
      rethrow;
    } catch (e) {
      AppDebugLog.growthTrajectory('latest err=$e');
      rethrow;
    }
  }

  /// POST turn SSE；预检失败抛 [ApiBusinessException]。
  Stream<GrowthTrajectoryStreamEvent> turnStream({
    required String deviceNo,
    required String action,
    String sessionId = '',
    String questionId = '',
    String answerValue = '',
  }) async* {
    final dn = deviceNo.trim();
    if (dn.isEmpty) {
      yield const GrowthTrajectoryErrorEvent(
        code: 'DEVICE_REQUIRED',
        message: '请先绑定宝宝信息',
      );
      return;
    }

    final client = http.Client();
    try {
      final base = Uri.parse(_api.baseUrl);
      final path = base.path.endsWith('/')
          ? '${base.path}device/api/growth-trajectory/turn'
          : '${base.path}/device/api/growth-trajectory/turn';
      final uri = base.replace(path: path);

      final bodyMap = <String, dynamic>{
        'deviceNo': dn,
        'action': action,
        if (sessionId.trim().isNotEmpty) 'sessionId': sessionId.trim(),
      };
      if (action == 'answer') {
        bodyMap['answer'] = {
          'questionId': questionId,
          'value': answerValue,
        };
      }

      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = jsonEncode(bodyMap);

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
            final codeVal = decoded['code'];
            final code =
                codeVal is int ? codeVal : (codeVal is num ? codeVal.toInt() : -1);
            final message = (decoded['message'] ?? '').toString();
            throw ApiBusinessException(code, message);
          }
        } catch (e) {
          if (e is ApiBusinessException) rethrow;
        }
        throw ApiHttpException(response.statusCode, bodyStr);
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
            // thinking 偶发纯文本：当作 content
            if (currentEvent == 'thinking' || currentEvent.isEmpty) {
              yield GrowthTrajectoryThinkingDelta(data);
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
                yield GrowthTrajectoryThinkingDelta(content);
              }
            case 'question':
              yield GrowthTrajectoryQuestionEvent(
                GrowthTrajectoryQuestion.fromJson(map),
              );
            case 'result':
              yield GrowthTrajectoryResultEvent(
                markdown: (map['markdown'] ?? '').toString(),
                sessionId: (map['sessionId'] ?? '').toString(),
                usedToday: map.containsKey('usedToday')
                    ? (map['usedToday'] is int
                        ? map['usedToday'] as int
                        : int.tryParse('${map['usedToday']}'))
                    : null,
                dailyLimit: map.containsKey('dailyLimit')
                    ? (map['dailyLimit'] is int
                        ? map['dailyLimit'] as int
                        : int.tryParse('${map['dailyLimit']}'))
                    : null,
              );
            case 'error':
              yield GrowthTrajectoryErrorEvent(
                code: (map['code'] ?? '').toString(),
                message: (map['message'] ?? '成长轨迹预测失败').toString(),
              );
            case 'done':
              yield const GrowthTrajectoryDoneEvent();
          }
        }
      }
    } on ApiBusinessException {
      rethrow;
    } on TimeoutException {
      AppDebugLog.growthTrajectory('turn timeout');
      yield const GrowthTrajectoryErrorEvent(
        code: 'TIMEOUT',
        message: '成长轨迹预测超时，请稍后重试',
      );
    } catch (e) {
      AppDebugLog.growthTrajectory('turn err=$e');
      if (e is ApiHttpException) rethrow;
      yield GrowthTrajectoryErrorEvent(
        code: 'STREAM',
        message: '成长轨迹预测暂时不可用，请稍后再试',
      );
    } finally {
      client.close();
    }
  }
}
