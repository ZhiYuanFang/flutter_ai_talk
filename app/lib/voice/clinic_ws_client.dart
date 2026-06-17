import 'dart:async';

import 'dart:convert';

import 'dart:math';



import 'package:web_socket_channel/web_socket_channel.dart';



import '../api/ai_quota_codes.dart';

import '../config/env.dart';



typedef ClinicWsFrameHandler = void Function(Map<String, dynamic> frame);



/// 胖宝诊疗 WebSocket 客户端：连接后首帧 auth，auth_ok 后接收 session_sync 并可发送 question/cancel。

class ClinicWsClient {

  ClinicWsClient({

    required this.wsUrl,

    required this.accessTokenGetter,

    required this.deviceNoGetter,

  });



  final String wsUrl;

  final String? Function() accessTokenGetter;

  final String? Function() deviceNoGetter;



  WebSocketChannel? _channel;

  StreamSubscription<dynamic>? _sub;

  var _authed = false;

  var _shouldStayConnected = false;

  Timer? _reconnectTimer;

  String? _activeTurnId;



  final _frameController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get frames => _frameController.stream;



  bool get isConnected => _channel != null && _authed;



  /// 当前进行中的 turnId（question 发送后至 answer_done / turn_cancelled 前）。

  String? get activeTurnId => _activeTurnId;



  void dispose() {

    _shouldStayConnected = false;

    _reconnectTimer?.cancel();

    unawaited(cancelActiveAndDisconnect());

    _frameController.close();

  }



  void setConnectionDesired(bool desired) {

    _shouldStayConnected = desired;

    if (desired) {

      unawaited(connect());

    } else {

      unawaited(cancelActiveAndDisconnect());

    }

  }



  Future<bool> connect() async {

    final url = wsUrl.trim();

    final token = accessTokenGetter()?.trim();

    final deviceNo = deviceNoGetter()?.trim();

    if (url.isEmpty || token == null || token.isEmpty || deviceNo == null || deviceNo.isEmpty) {

      return false;

    }

    _tearDown();

    try {

      _channel = WebSocketChannel.connect(Uri.parse(url));

      _sub = _channel!.stream.listen(

        _onMessage,

        onError: (_) => _scheduleReconnect(),

        onDone: () => _scheduleReconnect(),

      );

      _channel!.sink.add(jsonEncode({

        'type': 'auth',

        'accessToken': token,

        'deviceNo': deviceNo,

      }));

      return true;

    } catch (_) {

      _scheduleReconnect();

      return false;

    }

  }



  /// 发送 question 并分配新 turnId；返回 turnId 供 UI 过滤 stale 帧。

  Future<String?> sendQuestion(String text) async {

    final trimmed = text.trim();

    if (trimmed.isEmpty || _channel == null) return null;

    if (!_authed) {

      await connect();

      if (!_authed) return null;

    }

    final turnId = _newTurnId();

    _activeTurnId = turnId;

    _channel!.sink.add(jsonEncode({'type': 'question', 'text': trimmed, 'turnId': turnId}));

    return turnId;

  }



  /// 显式 cancel 指定 turn；离开页面/后台时 best-effort 发送后再断连。

  Future<void> sendCancel(String turnId) async {

    final tid = turnId.trim();

    if (tid.isEmpty || _channel == null) return;

    try {

      _channel!.sink.add(jsonEncode({'type': 'cancel', 'turnId': tid}));

    } catch (_) {}

  }



  /// 先 cancel active turn（若有），再断开 WebSocket。

  Future<void> cancelActiveAndDisconnect() async {

    final turnId = _activeTurnId;

    if (turnId != null && turnId.isNotEmpty) {

      await sendCancel(turnId);

      // best-effort 等待帧发出

      await Future<void>.delayed(const Duration(milliseconds: 80));

    }

    _activeTurnId = null;

    _tearDown();

  }



  void _clearActiveTurn(String turnId) {

    if (_activeTurnId == turnId) {

      _activeTurnId = null;

    }

  }



  void _onMessage(dynamic raw) {

    try {

      final decoded = jsonDecode(raw as String);

      if (decoded is! Map<String, dynamic>) return;

      final type = (decoded['type'] as String? ?? '').toLowerCase();

      if (type == 'auth_ok') {

        _authed = true;

      } else if (type == 'error') {

        _authed = false;

      } else if (type == 'answer_done') {

        _clearActiveTurn(decoded['turnId'] as String? ?? '');

      } else if (type == 'turn_cancelled') {

        _clearActiveTurn(decoded['turnId'] as String? ?? '');

      }

      if (!_frameController.isClosed) {

        _frameController.add(decoded);

      }

    } catch (_) {}

  }



  void _tearDown() {

    _authed = false;

    _sub?.cancel();

    _sub = null;

    _channel?.sink.close();

    _channel = null;

  }



  void _scheduleReconnect() {

    _tearDown();

    if (!_shouldStayConnected) return;

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(const Duration(seconds: 3), () {

      unawaited(connect());

    });

  }



  /// 解析 WS error 帧是否为额度/登录业务码。

  static int? businessCodeFromFrame(Map<String, dynamic> frame) {

    return parseWsErrorBusinessCode(frame);

  }



  /// 解析 session_sync 帧中的已完成 Q&A 轮次（不含 thinking）。

  static List<ClinicSessionTurn> parseSessionSyncTurns(Map<String, dynamic> frame) {

    final raw = frame['turns'];

    if (raw is! List) return const [];

    final out = <ClinicSessionTurn>[];

    for (final item in raw) {

      if (item is! Map) continue;

      final q = (item['question'] as String? ?? '').trim();

      final a = (item['answer'] as String? ?? '').trim();

      if (q.isEmpty || a.isEmpty) continue;

      out.add(ClinicSessionTurn(question: q, answer: a));

    }

    return out;

  }



  static String _newTurnId() {

    final r = Random.secure();

    final bytes = List<int>.generate(16, (_) => r.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int b) => b.toRadixString(16).padLeft(2, '0');

    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'

        '${hex(bytes[4])}${hex(bytes[5])}-'

        '${hex(bytes[6])}${hex(bytes[7])}-'

        '${hex(bytes[8])}${hex(bytes[9])}-'

        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';

  }

}



/// session_sync 中单轮已完成 Q&A（服务端 Redis 不存 thinking）。

class ClinicSessionTurn {

  const ClinicSessionTurn({required this.question, required this.answer});



  final String question;

  final String answer;

}



/// 默认由 gateway-app 主机推导的胖宝 WS URL。

String defaultClinicWsUrl() => AppEnv.wsClinicUrlEffective;

