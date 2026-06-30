import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../network/resilient_websocket_client.dart';
import '../../network/ws_connect_context.dart';
import '../../network/ws_connection_config.dart';
import '../../network/ws_connection_phase.dart';
import '../../providers/session_provider.dart';
import '../../session/token_expiry.dart';
import '../../voice/voice_asr_ws_client.dart';

/// 探针页专用 WS 传输（不 mount UCG repo，避免 unread/push 副作用）。
class IosLoginProbeTransports {
  ResilientWebSocketClient? _historyClient;
  ResilientWebSocketClient? _chatClient;
  VoiceAsrWsClient? _voiceAsrClient;

  Future<ProbeWsOutcome> connectHistory({
    required WidgetRef ref,
    required String deviceNo,
  }) async {
    if (AppEnv.wsHistoryUrlEffective.isEmpty) {
      return ProbeWsOutcome.skipped('history url empty');
    }
    if (deviceNo.isEmpty) {
      return ProbeWsOutcome.skipped('deviceNo empty');
    }
    _tearDownHistory();
    final client = ResilientWebSocketClient(
      WsConnectionConfig(
        url: AppEnv.wsHistoryUrlEffective,
        channelLabel: 'probe-history',
        requireSubscribeGate: true,
        shouldConnect: () async => deviceNo.isNotEmpty,
        prepareToken: () => prepareDeviceWsConnectContextFromWidget(
          ref,
          deviceNo: deviceNo,
          toastOnHardFailure: false,
          toastOnDeviceSyncFailure: false,
        ),
        buildAuthFrame: (ctx) => {
          'type': 'auth',
          'accessToken': ctx.accessToken,
          'deviceNo': ctx.deviceNo,
        },
        onErrorFrame: (_) async => false,
      ),
    );
    _historyClient = client;
    client.setSubscribeActive(true);
    client.setConnectionDesired(true);
    return _awaitReady(client);
  }

  Future<ProbeWsOutcome> connectVoiceAsr({required String deviceNo}) async {
    if (AppEnv.disablePangbaoWebSocketSpike) {
      return ProbeWsOutcome.skipped('DISABLE_PANGBAO_WS');
    }
    if (AppEnv.wsVoiceAsrUrlEffective.isEmpty) {
      return ProbeWsOutcome.skipped('voice asr url empty');
    }
    if (deviceNo.isEmpty) {
      return ProbeWsOutcome.skipped('deviceNo empty');
    }
    _tearDownVoiceAsr();
    final client = VoiceAsrWsClient(
      wsUrl: AppEnv.wsVoiceAsrUrlEffective,
      deviceNoGetter: () => deviceNo,
    );
    _voiceAsrClient = client;
    final sw = Stopwatch()..start();
    final ok = await client.connect();
    if (ok) {
      return ProbeWsOutcome.ok('ready', sw.elapsedMilliseconds);
    }
    return ProbeWsOutcome.fail('connect failed', sw.elapsedMilliseconds);
  }

  Future<ProbeWsOutcome> connectChat({
    required WidgetRef ref,
    required bool forceIgnoreWxId,
  }) async {
    if (AppEnv.wsUcgChatUrlEffective.isEmpty) {
      return ProbeWsOutcome.skipped('chat url empty');
    }
    final session = ref.read(sessionProvider);
    if (!session.isLoggedIn) {
      return ProbeWsOutcome.skipped('not logged in');
    }
    final wxId = readJwtWxId(session.accessToken);
    if (!forceIgnoreWxId && !isUcgWxAccountBound(wxId)) {
      return ProbeWsOutcome.skipped('no wxId (use force)');
    }
    _tearDownChat();
    final client = ResilientWebSocketClient(
      WsConnectionConfig(
        url: AppEnv.wsUcgChatUrlEffective,
        channelLabel: 'probe-ucg-chat',
        shouldConnect: () async {
          if (!ref.read(sessionProvider).isLoggedIn) return false;
          final token = ref.read(sessionProvider).accessToken;
          return token != null && token.isNotEmpty;
        },
        prepareToken: () async {
          final ok = await ref.read(sessionProvider).ensureFreshSession();
          if (!ok) return null;
          final token = ref.read(sessionProvider).accessToken;
          if (token == null || token.isEmpty) return null;
          return WsConnectContext(accessToken: token);
        },
        buildAuthFrame: (ctx) => {'type': 'auth', 'token': ctx.accessToken},
        onErrorFrame: (_) async => false,
      ),
    );
    _chatClient = client;
    client.setConnectionDesired(true);
    return _awaitReady(client);
  }

  Future<ProbeWsOutcome> _awaitReady(ResilientWebSocketClient client) async {
    final sw = Stopwatch()..start();
    if (client.isReady) {
      return ProbeWsOutcome.ok('ready', sw.elapsedMilliseconds);
    }
    final completer = Completer<ProbeWsOutcome>();
    StreamSubscription<bool>? readySub;
    StreamSubscription<WsConnectionPhase>? phaseSub;
    Timer? timer;

    void finish(ProbeWsOutcome outcome) {
      if (completer.isCompleted) return;
      timer?.cancel();
      readySub?.cancel();
      phaseSub?.cancel();
      completer.complete(outcome);
    }

    timer = Timer(const Duration(seconds: 15), () {
      finish(ProbeWsOutcome.fail('timeout phase=${client.phase}', sw.elapsedMilliseconds));
    });
    readySub = client.readyStream.listen((ready) {
      if (ready) finish(ProbeWsOutcome.ok('ready', sw.elapsedMilliseconds));
    });
    phaseSub = client.phaseStream.listen((phase) {
      if (phase == WsConnectionPhase.gaveUp) {
        finish(ProbeWsOutcome.fail('gaveUp', sw.elapsedMilliseconds));
      }
    });

    return completer.future;
  }

  void disconnectAll() {
    _tearDownHistory();
    _tearDownChat();
    _tearDownVoiceAsr();
  }

  void dispose() => disconnectAll();

  void _tearDownHistory() {
    _historyClient?.setSubscribeActive(false);
    _historyClient?.setConnectionDesired(false);
    _historyClient?.dispose();
    _historyClient = null;
  }

  void _tearDownChat() {
    _chatClient?.setConnectionDesired(false);
    _chatClient?.dispose();
    _chatClient = null;
  }

  void _tearDownVoiceAsr() {
    final client = _voiceAsrClient;
    _voiceAsrClient = null;
    if (client != null) {
      unawaited(client.dispose());
    }
  }
}

class ProbeWsOutcome {
  const ProbeWsOutcome._({
    required this.skipped,
    required this.ok,
    required this.elapsedMs,
    this.detail,
  });

  final bool skipped;
  final bool ok;
  final int elapsedMs;
  final String? detail;

  factory ProbeWsOutcome.ok(String detail, int elapsedMs) =>
      ProbeWsOutcome._(skipped: false, ok: true, elapsedMs: elapsedMs, detail: detail);

  factory ProbeWsOutcome.fail(String detail, int elapsedMs) =>
      ProbeWsOutcome._(skipped: false, ok: false, elapsedMs: elapsedMs, detail: detail);

  factory ProbeWsOutcome.skipped(String reason) =>
      ProbeWsOutcome._(skipped: true, ok: true, elapsedMs: 0, detail: reason);
}
