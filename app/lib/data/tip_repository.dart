import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 小贴士 SSE 事件数据
///
/// 业务含义：Go 侧 POST /device/tip/generate 通过 SSE 推送的每一帧事件。
/// 方言对齐 Go writeSSEEvent：`event:` 定类型，`data:` 为纯文本（非 JSON 包一层 type/content）。
/// - type=thinking：思考过程增量文本
/// - type=answer：回答内容增量文本
/// - type=done：完成帧，content 为原始 data（通常含 answerId JSON）；answerId 已解析时单独字段
/// - type=error：服务端错误提示文本
/// - done=true：流式结束标记（对应 SSE data: [DONE]）
class TipSSEEvent {
  /// 事件类型：thinking / answer / done / error，结束标记时为空字符串
  final String type;

  /// 增量内容或 done/error 的 data 纯文本
  final String content;

  /// 从 event: done 的 JSON data 解析出的回答 ID；非 done 帧为 null
  final String? answerId;

  /// 是否为结束标记（data: [DONE]）
  final bool done;

  TipSSEEvent({
    required this.type,
    this.content = '',
    this.answerId,
    this.done = false,
  });
}

/// 小贴士 Repository，负责调用 Go /device/tip/generate 接口接收 SSE 流
///
/// 业务说明：
/// ApiClient 使用 {code,message,data} 信封格式且不支持 SSE 流式，
/// 因此此处直接使用 http 包的 Client.send 处理 text/event-stream。
/// SSE 解析与 chat 流（remote_feed_repository）对齐：event + 纯文本 data。
/// 同时提供 tip feedback 提交（字段对齐 answerId；完整反馈飞轮属包 C）。
class TipRepository {
  /// 网关基址，复用 AppEnv.apiBaseUrl
  final String _baseUrl;

  /// 鉴权 token 提供器，复用 sessionProvider 的 accessToken
  final String Function()? _tokenProvider;

  TipRepository({
    required String baseUrl,
    String Function()? tokenProvider,
  })  : _baseUrl = baseUrl,
        _tokenProvider = tokenProvider;

  /// 请求小贴士生成，返回 SSE 事件流
  ///
  /// 业务流程：
  /// 1. POST /device/tip/generate，body 携带设备号、事件 ID、事件名（月龄/时间由服务端派生）
  /// 2. 服务端以 text/event-stream 推送 event: thinking|answer|done|error + data 纯文本
  /// 3. 收到 data: [DONE] 时结束流
  /// 4. 逐帧 yield TipSSEEvent 供 Notifier 累积；done 事件携带 answerId
  Stream<TipSSEEvent> streamTip({
    required String deviceNo,
    required int eventId,
    required String eventName,
  }) async* {
    // App 路径锁定：/device/tip/generate（经 gateway 反代到 voice）
    final url = Uri.parse('$_baseUrl/device/tip/generate');

    // 构建 POST 请求体（字段与 api/v1 DeviceTipGenerateReq 对齐；不含月龄/时间）
    final body = jsonEncode({
      'deviceNo': deviceNo,
      'eventId': eventId,
      'eventName': eventName,
    });

    // 使用 http.Client 发送 POST 请求，接收流式响应
    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = body;

      // 添加鉴权头：复用 sessionProvider 的 accessToken（需登录，非 exempt）
      final tokenProvider = _tokenProvider;
      if (tokenProvider != null) {
        final token = tokenProvider();
        if (token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('小贴士请求失败: ${response.statusCode}');
      }

      // 逐行解析 SSE：对齐 chat 方言（event: + data 纯文本），缓冲跨 chunk 不完整行
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
            // 空行：帧分隔，清空当前 event 上下文（与标准 SSE 一致）
            currentEvent = '';
            continue;
          }

          // event: <type>
          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
            continue;
          }

          // data: <content>
          if (line.startsWith('data:')) {
            final data = line.substring(5).trim();
            // 结束标记
            if (data == '[DONE]') {
              yield TipSSEEvent(type: '', done: true);
              return;
            }

            if (currentEvent == 'thinking' || currentEvent == 'answer') {
              // thinking/answer：data 为纯文本增量
              yield TipSSEEvent(type: currentEvent, content: data);
            } else if (currentEvent == 'done') {
              // done：data 为 {"answerId":"..."}，解析后供反馈字段对齐
              String? answerId;
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                answerId = json['answerId'] as String?;
              } catch (_) {
                // 解析失败仍透传原始 data，避免丢帧
              }
              yield TipSSEEvent(
                type: 'done',
                content: data,
                answerId: answerId,
              );
            } else if (currentEvent == 'error') {
              yield TipSSEEvent(type: 'error', content: data);
            }
            continue;
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// 提交小贴士反馈
  ///
  /// 业务说明：用户点击 thumbs up/down 后调用。
  /// Body 对齐 Go api/v1 DeviceTipFeedbackReq：`answerId`（string）+ `feedback`（1|-1）。
  /// 路径：`POST /device/api/tip/feedback`（经 gateway 反代到 voice，非 tip generate 前缀）。
  Future<void> submitFeedback({
    required String answerId,
    required int feedback,
  }) async {
    final url = Uri.parse('$_baseUrl/device/api/tip/feedback');
    final body = jsonEncode({
      'answerId': answerId,
      'feedback': feedback,
    });

    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = body;

      // 添加鉴权头
      final tokenProvider = _tokenProvider;
      if (tokenProvider != null) {
        final token = tokenProvider();
        if (token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('反馈提交失败: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }
}
