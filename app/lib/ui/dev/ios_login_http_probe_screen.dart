import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exceptions.dart';
import '../../config/env.dart';
import '../../data/history_list_page.dart';
import '../../data/repositories.dart';
import '../../providers/authorized_api_client_provider.dart';
import '../../providers/device_no_notifier.dart';
import '../../providers/session_provider.dart';
import '../../session/token_expiry.dart';
import 'ios_login_probe_transports.dart';

/// iOS 登录后 pangbao HTTP/WS 隔离探针：不 mount Home、不 bootstrap。
class IosLoginHttpProbeScreen extends ConsumerStatefulWidget {
  const IosLoginHttpProbeScreen({super.key});

  @override
  ConsumerState<IosLoginHttpProbeScreen> createState() => _IosLoginHttpProbeScreenState();
}

enum _ProbeScenario {
  httpParallel,
  httpSerial,
  wsFirstThenHttpParallel,
  wsAndHttpParallel,
}

class _ProbeResult {
  const _ProbeResult({
    required this.label,
    required this.ok,
    required this.elapsedMs,
    this.detail,
    this.skipped = false,
  });

  final String label;
  final bool ok;
  final int elapsedMs;
  final String? detail;
  final bool skipped;
}

class _IosLoginHttpProbeScreenState extends ConsumerState<IosLoginHttpProbeScreen> {
  static const _defaultDeviceNo = 'PANGAIDEV';

  final _deviceNoCtrl = TextEditingController(text: _defaultDeviceNo);
  final _transports = IosLoginProbeTransports();

  var _running = false;
  var _mode = '';
  var _includeHistoryWs = true;
  var _includeChatWs = true;
  var _forceChatWs = false;
  List<_ProbeResult> _results = const [];
  String? _version;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cached = ref.read(deviceNoNotifierProvider).asData?.value;
      if (cached != null && cached.isNotEmpty) {
        _deviceNoCtrl.text = cached;
      }
      unawaited(_loadVersion());
    });
  }

  @override
  void dispose() {
    _transports.dispose();
    _deviceNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final v = await readPackageVersion();
      if (mounted) setState(() => _version = v);
    } catch (_) {}
  }

  Future<_ProbeResult> _probe({
    required String label,
    required Future<void> Function() run,
  }) async {
    final sw = Stopwatch()..start();
    try {
      await run();
      return _ProbeResult(label: label, ok: true, elapsedMs: sw.elapsedMilliseconds);
    } on ApiHttpException catch (e) {
      return _ProbeResult(
        label: label,
        ok: false,
        elapsedMs: sw.elapsedMilliseconds,
        detail: 'HTTP ${e.statusCode}',
      );
    } on ApiBusinessException catch (e) {
      return _ProbeResult(
        label: label,
        ok: false,
        elapsedMs: sw.elapsedMilliseconds,
        detail: 'code=${e.code} ${e.message}',
      );
    } catch (e) {
      return _ProbeResult(
        label: label,
        ok: false,
        elapsedMs: sw.elapsedMilliseconds,
        detail: e.runtimeType.toString(),
      );
    }
  }

  _ProbeResult _wsOutcomeToResult(String label, ProbeWsOutcome o) {
    if (o.skipped) {
      return _ProbeResult(
        label: label,
        ok: true,
        elapsedMs: o.elapsedMs,
        detail: 'skipped: ${o.detail}',
        skipped: true,
      );
    }
    return _ProbeResult(
      label: label,
      ok: o.ok,
      elapsedMs: o.elapsedMs,
      detail: o.detail,
    );
  }

  Future<void> _runOptions(String deviceNo) {
    final api = ref.read(authorizedApiClientProvider);
    return api.getEnvelope(
      '/device/history/api/event/options',
      query: {'deviceNo': deviceNo},
      withAuthorization: true,
    ).then((_) {});
  }

  Future<void> _runHistoryList(String deviceNo) {
    final api = ref.read(authorizedApiClientProvider);
    return api.getEnvelope(
      '/device/history/api/list',
      query: {
        'deviceNo': deviceNo,
        'page': '1',
        'pageSize': '$kHomeHistoryPageSize',
      },
      withAuthorization: true,
    ).then((_) {});
  }

  Future<void> _runUserGet(String deviceNo) {
    final api = ref.read(authorizedApiClientProvider);
    return api.getEnvelope(
      '/device/app/api/user/get',
      query: {'deviceNo': deviceNo},
      withAuthorization: true,
    ).then((_) {});
  }

  Future<void> _runVersionCheck(String currentVersion) {
    final api = ref.read(authorizedApiClientProvider);
    return api.getEnvelope(
      '/device/app/api/version/check',
      query: {'currentVersion': currentVersion},
      withAuthorization: false,
    ).then((_) {});
  }

  List<Future<_ProbeResult> Function()> _buildHttpProbes(String deviceNo, String version) {
    return [
      () => _probe(label: 'HTTP event/options', run: () => _runOptions(deviceNo)),
      () => _probe(label: 'HTTP history/list', run: () => _runHistoryList(deviceNo)),
      () => _probe(label: 'HTTP user/get', run: () => _runUserGet(deviceNo)),
      () => _probe(label: 'HTTP version/check', run: () => _runVersionCheck(version)),
    ];
  }

  Future<List<_ProbeResult>> _runHttpProbes({
    required String deviceNo,
    required String version,
    required bool parallel,
  }) async {
    final probes = _buildHttpProbes(deviceNo, version);
    if (parallel) {
      return Future.wait(probes.map((p) => p()));
    }
    final out = <_ProbeResult>[];
    for (final p in probes) {
      out.add(await p());
    }
    return out;
  }

  Future<List<_ProbeResult>> _runWsProbes(String deviceNo) async {
    final out = <_ProbeResult>[];
    if (_includeHistoryWs && _includeChatWs) {
      final pair = await Future.wait([
        _transports.connectHistory(ref: ref, deviceNo: deviceNo),
        _transports.connectChat(ref: ref, forceIgnoreWxId: _forceChatWs),
      ]);
      out.add(_wsOutcomeToResult('WS history', pair[0]));
      out.add(_wsOutcomeToResult('WS ucg/chat', pair[1]));
      return out;
    }
    if (_includeHistoryWs) {
      final o = await _transports.connectHistory(ref: ref, deviceNo: deviceNo);
      out.add(_wsOutcomeToResult('WS history', o));
    }
    if (_includeChatWs) {
      final o = await _transports.connectChat(ref: ref, forceIgnoreWxId: _forceChatWs);
      out.add(_wsOutcomeToResult('WS ucg/chat', o));
    }
    return out;
  }

  String _scenarioLabel(_ProbeScenario scenario) {
    switch (scenario) {
      case _ProbeScenario.httpParallel:
        return 'HTTP 并发';
      case _ProbeScenario.httpSerial:
        return 'HTTP 串行';
      case _ProbeScenario.wsFirstThenHttpParallel:
        return '先 WS 再 HTTP 并发';
      case _ProbeScenario.wsAndHttpParallel:
        return 'WS + HTTP 同时并发';
    }
  }

  Future<void> _runScenario(_ProbeScenario scenario) async {
    if (_running) return;
    final deviceNo = _deviceNoCtrl.text.trim();
    if (deviceNo.isEmpty) return;
    final version = _version ?? await readPackageVersion();
    if (!mounted) return;

    setState(() {
      _running = true;
      _mode = _scenarioLabel(scenario);
      _results = const [];
    });

    List<_ProbeResult> out;
    switch (scenario) {
      case _ProbeScenario.httpParallel:
        out = await _runHttpProbes(deviceNo: deviceNo, version: version, parallel: true);
      case _ProbeScenario.httpSerial:
        out = await _runHttpProbes(deviceNo: deviceNo, version: version, parallel: false);
      case _ProbeScenario.wsFirstThenHttpParallel:
        out = [
          ...await _runWsProbes(deviceNo),
          ...await _runHttpProbes(deviceNo: deviceNo, version: version, parallel: true),
        ];
      case _ProbeScenario.wsAndHttpParallel:
        final wsFuture = _runWsProbes(deviceNo);
        final httpFuture = _runHttpProbes(deviceNo: deviceNo, version: version, parallel: true);
        final pair = await Future.wait([wsFuture, httpFuture]);
        out = [...pair[0], ...pair[1]];
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _results = out;
    });
  }

  void _disconnectWs() {
    _transports.disconnectAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WS 已断开')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final token = ref.watch(sessionProvider.select((s) => s.accessToken));
    final hasToken = token != null && token.isNotEmpty;
    final wxId = readJwtWxId(token);
    final wxBound = isUcgWxAccountBound(wxId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS Login HTTP Probe'),
        actions: [
          TextButton(
            onPressed: _running ? null : () => context.go('/home'),
            child: const Text('进首页'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('base: ${AppEnv.apiBaseUrl}', style: Theme.of(context).textTheme.bodySmall),
          Text('history WS: ${AppEnv.wsHistoryUrlEffective}', style: Theme.of(context).textTheme.bodySmall),
          Text('ucg chat WS: ${AppEnv.wsUcgChatUrlEffective}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('loggedIn=$loggedIn token=${hasToken ? 'yes' : 'no'} wxBound=$wxBound'),
          Text('version=${_version ?? '…'}'),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceNoCtrl,
            decoration: const InputDecoration(
              labelText: 'deviceNo',
              border: OutlineInputBorder(),
            ),
            enabled: !_running,
          ),
          const SizedBox(height: 12),
          Text('WebSocket（独立 client，不 mount UCG repo）', style: Theme.of(context).textTheme.titleSmall),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('history WS'),
            value: _includeHistoryWs,
            onChanged: _running
                ? null
                : (v) => setState(() => _includeHistoryWs = v ?? true),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ucg/chat WS'),
            subtitle: wxBound
                ? null
                : const Text('账号/Apple 登录无 wxId，需勾选「强制 chat WS」'),
            value: _includeChatWs,
            onChanged: _running ? null : (v) => setState(() => _includeChatWs = v ?? true),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('强制 chat WS（忽略 wxId）'),
            value: _forceChatWs,
            onChanged: _running ? null : (v) => setState(() => _forceChatWs = v ?? false),
          ),
          OutlinedButton(
            onPressed: _running ? null : _disconnectWs,
            child: const Text('断开 WS'),
          ),
          const SizedBox(height: 16),
          Text('HTTP 4 接口', style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _running ? null : () => _runScenario(_ProbeScenario.httpParallel),
                  child: const Text('并发 4 HTTP'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _running ? null : () => _runScenario(_ProbeScenario.httpSerial),
                  child: const Text('串行 4 HTTP'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('HTTP + WS（4+2=6 槽位）', style: Theme.of(context).textTheme.titleSmall),
          FilledButton.tonal(
            onPressed: _running ? null : () => _runScenario(_ProbeScenario.wsFirstThenHttpParallel),
            child: const Text('先 WS 再 HTTP 并发'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _running ? null : () => _runScenario(_ProbeScenario.wsAndHttpParallel),
            child: const Text('WS + HTTP 同时并发'),
          ),
          if (_mode.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('模式: $_mode', style: Theme.of(context).textTheme.titleSmall),
          ],
          for (final r in _results) ...[
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r.label),
              subtitle: r.detail != null ? Text(r.detail!) : null,
              trailing: Text(
                r.skipped
                    ? '– skip'
                    : r.ok
                        ? '✓ ${r.elapsedMs}ms'
                        : '✗ ${r.elapsedMs}ms',
                style: TextStyle(
                  color: r.skipped
                      ? Colors.grey
                      : r.ok
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
