import 'dart:async';

/// 建连上下文：由 [prepareToken] 与 [shouldConnect] 结果注入鉴权帧所需字段。
class WsConnectContext {
  const WsConnectContext({this.accessToken, this.deviceNo});

  final String? accessToken;
  final String? deviceNo;
}

/// 共享韧性 WebSocket 通道配置。
class WsConnectionConfig {
  const WsConnectionConfig({
    required this.url,
    required this.shouldConnect,
    required this.prepareToken,
    required this.buildAuthFrame,
    this.onApplicationFrame,
    this.onErrorFrame,
    this.log,
    this.channelLabel = 'ws',
    this.requireSubscribeGate = false,
    this.requireHandshakePong = true,
  });

  final String url;

  /// 返回 false 时不建连（如无 deviceNo / 未绑定 wxId）。
  final Future<bool> Function() shouldConnect;

  /// 建连前刷新 token；返回 null 则中止本次 attempt。
  final Future<WsConnectContext?> Function() prepareToken;

  final Map<String, dynamic> Function(WsConnectContext ctx) buildAuthFrame;

  /// 非 auth_ok / pong / error 的业务帧。
  final void Function(Map<String, dynamic> frame)? onApplicationFrame;

  /// 处理 error 帧；返回 true 表示应 scheduleReconnect，false 表示不重连。
  final Future<bool> Function(Map<String, dynamic> frame)? onErrorFrame;

  final void Function(String message)? log;

  final String channelLabel;

  /// 为 true 时仅当 [ResilientWebSocketClient.setSubscribeActive] 为 true 才自动重连（喂养历史）。
  final bool requireSubscribeGate;

  /// 为 true 时就绪须 auth_ok + 首次 pong；为 false 时 auth_ok 即 ready（胖宝 clinic 等）。
  final bool requireHandshakePong;
}
