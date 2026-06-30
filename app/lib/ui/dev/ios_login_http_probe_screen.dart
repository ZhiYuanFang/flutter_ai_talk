import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../data/repositories.dart';
import '../../providers/device_no_notifier.dart';
import '../../providers/session_provider.dart';
import '../../session/token_expiry.dart';
import 'ios_login_probe_items.dart';
import 'ios_login_probe_runner.dart';
import 'ios_login_probe_transports.dart';

/// iOS 登录后 Home 全量探针：逐项勾选，复刻进房 HTTP/WS，不 mount Home。
class IosLoginHttpProbeScreen extends ConsumerStatefulWidget {
  const IosLoginHttpProbeScreen({super.key});

  @override
  ConsumerState<IosLoginHttpProbeScreen> createState() => _IosLoginHttpProbeScreenState();
}

enum _RunMode { parallel, homeTimeline }

class _IosLoginHttpProbeScreenState extends ConsumerState<IosLoginHttpProbeScreen> {
  static const _defaultDeviceNo = 'PANGAIDEV';

  final _deviceNoCtrl = TextEditingController(text: _defaultDeviceNo);
  final _transports = IosLoginProbeTransports();
  final _selected = <HomeProbeItem, bool>{};

  var _running = false;
  var _mode = '';
  var _forceChatWs = false;
  var _logoCount = 2;
  var _logoConcurrency = 2;
  List<ProbeRunResult> _results = const [];
  String? _version;

  @override
  void initState() {
    super.initState();
    for (final item in HomeProbeItem.values) {
      _selected[item] = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cached = ref.read(deviceNoNotifierProvider).asData?.value;
      if (cached != null && cached.isNotEmpty) {
        _deviceNoCtrl.text = cached;
      }
      final wxBound = isUcgWxAccountBound(readJwtWxId(ref.read(sessionProvider).accessToken));
      if (wxBound) {
        _applyPreset(homeProbeWxPreset());
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

  void _applyPreset(Set<HomeProbeItem> items) {
    for (final item in HomeProbeItem.values) {
      _selected[item] = items.contains(item);
    }
  }

  Future<void> _loadVersion() async {
    try {
      final v = await readPackageVersion();
      if (mounted) setState(() => _version = v);
    } catch (_) {}
  }

  Set<HomeProbeItem> get _checkedItems => _selected.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toSet();

  int _estimatePangbaoSlots(Set<HomeProbeItem> items) {
    var n = 0;
    for (final item in items) {
      if (item.isNotifyHost || item.isDelayOnly) continue;
      n += item.slotWeight(logoConcurrency: _logoConcurrency);
    }
    return n;
  }

  IosLoginProbeRunner _buildRunner({
    required String deviceNo,
    required String version,
    required bool wxBound,
  }) {
    return IosLoginProbeRunner(
      ref: ref,
      transports: _transports,
      deviceNo: deviceNo,
      version: version,
      wxBound: wxBound,
      forceChatWs: _forceChatWs,
      logoCount: _logoCount,
      logoConcurrency: _logoConcurrency,
    );
  }

  String _modeLabel(_RunMode mode) => switch (mode) {
        _RunMode.parallel => '已选并发',
        _RunMode.homeTimeline => 'Home 时序',
      };

  Future<void> _run(_RunMode mode) async {
    if (_running) return;
    final deviceNo = _deviceNoCtrl.text.trim();
    if (deviceNo.isEmpty) return;
    final selected = _checkedItems;
    if (selected.isEmpty) return;
    final version = _version ?? await readPackageVersion();
    if (!mounted) return;

    final wxBound = isUcgWxAccountBound(readJwtWxId(ref.read(sessionProvider).accessToken));
    setState(() {
      _running = true;
      _mode = _modeLabel(mode);
      _results = const [];
    });

    final runner = _buildRunner(deviceNo: deviceNo, version: version, wxBound: wxBound);
    final out = switch (mode) {
      _RunMode.parallel => await runner.runParallel(selected),
      _RunMode.homeTimeline => await runner.runHomeTimeline(selected),
    };

    if (!mounted) return;
    setState(() {
      _running = false;
      _results = out;
    });
  }

  void _disconnectAll() {
    _transports.disconnectAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WS / Voice ASR 已断开')),
    );
  }

  List<Widget> _buildItemCheckboxes(bool wxBound) {
    final widgets = <Widget>[];
    String? lastPhase;
    for (final item in HomeProbeItem.values) {
      if (item.phaseTitle != lastPhase) {
        lastPhase = item.phaseTitle;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(lastPhase, style: Theme.of(context).textTheme.titleSmall),
        ));
      }
      final needsWx = item.requiresWx && !wxBound;
      widgets.add(CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(item.label),
        subtitle: needsWx ? const Text('需 wxId（chat 可强制）') : null,
        value: _selected[item] ?? false,
        onChanged: _running
            ? null
            : (v) => setState(() => _selected[item] = v ?? false),
      ));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final token = ref.watch(sessionProvider.select((s) => s.accessToken));
    final wxId = readJwtWxId(token);
    final wxBound = isUcgWxAccountBound(wxId);
    final checked = _checkedItems;
    final slots = _estimatePangbaoSlots(checked);

    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS Home Probe'),
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
          Text('pangbao: ${AppEnv.apiBaseUrl}', style: Theme.of(context).textTheme.bodySmall),
          Text('notify: ${AppEnv.notifyBaseUrl}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('loggedIn=$loggedIn wxId=${wxId ?? '–'} wxBound=$wxBound'),
          Text('version=${_version ?? '…'} · 已选 pangbao 槽≈$slots / ~6'),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceNoCtrl,
            decoration: const InputDecoration(
              labelText: 'deviceNo',
              border: OutlineInputBorder(),
            ),
            enabled: !_running,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _running ? null : () => setState(() => _applyPreset(homeProbeWxPreset())),
                child: const Text('全选 Home(wx)'),
              ),
              TextButton(
                onPressed: _running
                    ? null
                    : () => setState(() {
                          for (final item in HomeProbeItem.values) {
                            _selected[item] = false;
                          }
                        }),
                child: const Text('全不选'),
              ),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('强制 ucg/chat WS（无 wxId 时）'),
            value: _forceChatWs,
            onChanged: _running ? null : (v) => setState(() => _forceChatWs = v ?? false),
          ),
          if (_selected[HomeProbeItem.logoDownload] == true) ...[
            Text('Logo 探针', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'logo 数量'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _logoCount,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1')),
                          DropdownMenuItem(value: 2, child: Text('2')),
                          DropdownMenuItem(value: 6, child: Text('6')),
                        ],
                        onChanged: _running ? null : (v) => setState(() => _logoCount = v ?? 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '并发 HttpClient'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _logoConcurrency,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1')),
                          DropdownMenuItem(value: 2, child: Text('2')),
                        ],
                        onChanged: _running ? null : (v) => setState(() => _logoConcurrency = v ?? 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          ..._buildItemCheckboxes(wxBound),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _running ? null : _disconnectAll,
            child: const Text('断开 WS / Voice ASR'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _running || checked.isEmpty ? null : () => _run(_RunMode.parallel),
            child: const Text('运行已选（并发）'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _running || checked.isEmpty ? null : () => _run(_RunMode.homeTimeline),
            child: const Text('运行已选（Home 时序）'),
          ),
          if (_mode.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('模式: $_mode', style: Theme.of(context).textTheme.titleSmall),
          ],
          for (final r in _results) ...[
            const Divider(height: 20),
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
