import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../config/web_home_input_mode.dart';
import '../data/history_line_format.dart';
import '../data/models.dart';
import '../providers/device_no_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _speech = stt.SpeechToText();
  var _speechReady = false;
  var _listening = false;
  String _partial = '';

  /// 仅 Web 使用；移动端为 [WebHomeInputMode.text] 占位，不参与分支。
  late final WebHomeInputMode _webHomeInputMode;

  List<HistoryRecord> _items = [];
  StreamSubscription<SseHistoryPayload>? _sseSub;
  StreamSubscription<bool>? _wsReadySub;
  var _wsReady = false;

  final _webController = TextEditingController();
  String? _chatReply;

  @override
  void initState() {
    super.initState();
    _webHomeInputMode = kIsWeb ? resolveWebHomeInputMode() : WebHomeInputMode.text;
    _init();
  }

  Future<void> _init() async {
    final initSpeech = !kIsWeb || _webHomeInputMode == WebHomeInputMode.voice;
    if (initSpeech) {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if (s == 'notListening') setState(() => _listening = false);
        },
        onError: (e) => debugPrint('speech error: $e'),
      );
      if (kIsWeb && _webHomeInputMode == WebHomeInputMode.voice && !_speechReady && mounted) {
        debugPrint('web speech init failed, using text input');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('语音识别不可用，已改用文字输入')),
          );
        });
      }
      setState(() {});
    }
    if (ref.read(sessionProvider).isLoggedIn) {
      await ref.read(deviceNoNotifierProvider.notifier).refresh();
    }
    await _reloadHistoryIfLoggedIn();
    final feed = ref.read(feedRepositoryProvider);
    _wsReady = feed.isHistoryWebSocketReady;
    _wsReadySub = feed.historyWsReadyStream.listen((v) {
      if (mounted) setState(() => _wsReady = v);
    });
    _sseSub = feed.watchLatest().listen((payload) {
      final removed = payload.removedRecordId;
      if (removed != null) {
        setState(() {
          _items = _items.where((e) => e.id != removed).toList();
        });
        return;
      }
      final r = payload.record!;
      setState(() {
        // 与底部「消息往上顶」一致：推送来的记录（新建或更新）始终放在列表末尾（视觉最下方）。
        _items = [..._items.where((e) => e.id != r.id), r];
      });
    });
  }

  Future<bool> _ensureRemoteGate() async {
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    if (!loggedIn) {
      final go = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('需要登录'),
              content: const Text('请先登录后再操作。'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('去登录')),
              ],
            ),
          ) ??
          false;
      if (go && mounted) await context.push('/login');
      return false;
    }
    final dnState = ref.read(deviceNoNotifierProvider);
    if (dnState.isLoading) return true;
    final dn = dnState.asData?.value;
    if (dn == null || dn.isEmpty) {
      final go = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('绑定宝宝'),
              content: const Text('请先绑定宝宝信息。'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('去绑定')),
              ],
            ),
          ) ??
          false;
      if (go && mounted) await context.push('/settings/bind-baby');
      return false;
    }
    return true;
  }

  bool _ensureHistoryWsForSend() {
    final ok = ref.read(feedRepositoryProvider).isHistoryWebSocketReady;
    if (!ok) {
      ref.read(apiToastProvider.notifier).state = '历史实时连接未就绪，无法发送，请点击右上角「重连历史」后再试';
    }
    return ok;
  }

  Future<void> _reconnectHistoryWs() async {
    await ref.read(feedRepositoryProvider).reconnectHistoryWebSocket();
  }

  Future<void> _reloadHistory() async {
    final list = await ref.read(feedRepositoryProvider).loadHistory();
    if (!mounted) return;
    // 接口为最新在前；首页 `_items` 按时间升序（最旧→最新），配合 reverse ListView 让最新靠近底部输入区。
    setState(() => _items = list.reversed.toList());
  }

  /// 已登录时拉取历史列表；未登录不请求接口（列表保持空）。
  Future<void> _reloadHistoryIfLoggedIn() async {
    if (!ref.read(sessionProvider).isLoggedIn) {
      if (!mounted) return;
      setState(() => _items = []);
      return;
    }
    await _reloadHistory();
  }

  Future<void> _onVoiceEnd() async {
    if (!_speechReady) return;
    await _speech.stop();
    setState(() => _listening = false);
    final text = _partial.trim();
    _partial = '';
    if (text.isEmpty) return;
    if (!await _ensureRemoteGate()) return;
    if (!_ensureHistoryWsForSend()) return;
    final reply = await ref.read(feedRepositoryProvider).sendCommand(text);
    if (!mounted) return;
    setState(() => _chatReply = reply?.trim().isNotEmpty == true ? reply : null);
  }

  Future<void> _onWebSubmit() async {
    final text = _webController.text.trim();
    if (text.isEmpty) return;
    if (!await _ensureRemoteGate()) return;
    if (!_ensureHistoryWsForSend()) return;
    final reply = await ref.read(feedRepositoryProvider).sendCommand(text);
    _webController.clear();
    if (!mounted) return;
    setState(() => _chatReply = reply?.trim().isNotEmpty == true ? reply : null);
  }

  Future<void> _openHistory(HistoryRecord record) async {
    if (!await _ensureRemoteGate()) return;
    if (!mounted) return;
    final changed = await context.push<bool>('/history/${record.id}');
    if (changed == true && mounted) {
      await _reloadHistoryIfLoggedIn();
    }
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _wsReadySub?.cancel();
    _webController.dispose();
    super.dispose();
  }

  Future<void> _onBindBannerTap() async {
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    if (!loggedIn) {
      await context.push('/login');
      return;
    }
    await context.push('/settings/bind-baby');
    if (mounted) {
      await ref.read(deviceNoNotifierProvider.notifier).refresh();
      await _reloadHistoryIfLoggedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, loggedIn) {
      if (!loggedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadHistoryIfLoggedIn();
      });
    });
    ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
      if (!ref.read(sessionProvider).isLoggedIn) return;
      final nextDn = next.asData?.value;
      if (nextDn == null || nextDn.isEmpty) return;
      final prevDn = prev?.asData?.value;
      if (prevDn == nextDn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadHistoryIfLoggedIn();
      });
    });
    final count = _items.length;
    // 仅当本地未缓存 deviceNo 时提示绑定；无历史记录见下方「暂无历史记录」。
    final dnAsync = ref.watch(deviceNoNotifierProvider);
    final needsDeviceBind = dnAsync.maybeWhen(
      data: (dn) => dn == null || dn.isEmpty,
      orElse: () => false,
    );
    final showBindBanner = needsDeviceBind;
    return Scaffold(
      appBar: AppBar(
        title: const Text('胖宝'),
        actions: [
          IconButton(
            tooltip: _wsReady ? '历史连接就绪' : '重连历史连接',
            icon: Icon(_wsReady ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
            color: _wsReady ? null : Theme.of(context).colorScheme.error,
            onPressed: _reconnectHistoryWs,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showBindBanner)
              Material(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
                child: InkWell(
                  onTap: _onBindBannerTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('请绑定宝宝信息', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: count == 0 && !showBindBanner
                  ? const Center(child: Text('暂无历史记录'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      reverse: true,
                      itemCount: count,
                      itemBuilder: (context, index) {
                        final record = _items[count - 1 - index];
                        final fromBottom = index;
                        final opacity = (0.35 + fromBottom * 0.05).clamp(0.35, 1.0);
                        final fontSize = (18 - fromBottom * 0.45).clamp(12.0, 18.0);
                        return Opacity(
                          opacity: opacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openHistory(record),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(fontSize: fontSize, height: 1.25),
                                        children: historyLineSpans(
                                          record,
                                          TextStyle(
                                            fontSize: fontSize,
                                            height: 1.25,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 220,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: _buildPrimaryHomeInput(context),
                  ),
                  Positioned(
                    right: 24,
                    top: 16,
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.push('/trends'),
                      icon: const Icon(Icons.insights),
                      label: const Text('趋势'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryHomeInput(BuildContext context) {
    if (!kIsWeb) return _buildVoiceOrb(context);
    if (_webHomeInputMode == WebHomeInputMode.text) return _buildWebInput(context);
    if (_speechReady) return _buildVoiceOrb(context);
    return _buildWebInput(context);
  }

  Widget _buildWebInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _webController,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入后按 Enter 或点按钮提交',
            ),
            onSubmitted: (_) => _onWebSubmit(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _onWebSubmit,
            icon: const Icon(Icons.send),
            label: const Text('提交到服务端'),
          ),
          if (_chatReply != null) ...[
            const SizedBox(height: 8),
            Text(
              _chatReply!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceOrb(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (_) async {
            if (!await _ensureRemoteGate()) return;
            if (!_ensureHistoryWsForSend()) return;
            if (!_speechReady) return;
            setState(() {
              _listening = true;
              _partial = '';
            });
            await _speech.listen(
              onResult: (r) {
                setState(() => _partial = r.recognizedWords);
              },
              cancelOnError: true,
              listenMode: stt.ListenMode.dictation,
            );
          },
          onPointerUp: (_) => _onVoiceEnd(),
          onPointerCancel: (_) => _onVoiceEnd(),
          child: AnimatedScale(
            scale: _listening ? 1.06 : 1,
            duration: const Duration(milliseconds: 160),
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 1,
                    color: color.withValues(alpha: 0.25),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _listening ? '松开结束' : '按住说话',
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        if (_chatReply != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: Text(
              _chatReply!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
