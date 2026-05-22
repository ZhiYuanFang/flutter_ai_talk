import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../audio/voice_level_smoother.dart';
import '../asr/home_speech_factory.dart';
import '../asr/home_speech_recognizer.dart';
import '../config/recording_diagnostics_store.dart';
import '../config/speech_engine.dart';
import '../config/speech_engine_store.dart';
import '../config/web_home_input_mode.dart';
import '../providers/voice_asr_ws_provider.dart';
import '../data/history_record_metric.dart';
import '../data/models.dart';
import 'home_history_scroll.dart';
import 'home_history_timeline_tile.dart';
import 'home_input_caption.dart';
import 'home_reply_bottom_sheet.dart';
import 'home_today_summary_panel.dart';
import 'home_voice_level_bars.dart';
import 'home_voice_message_strip.dart';
import 'home_voice_recording_stats.dart';
import '../providers/device_no_notifier.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeInputChannel { voice, text }

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeSpeechRecognizer? _recognizer;
  var _voiceReady = false;
  var _listening = false;
  String _partial = '';

  /// 首页输入方式：语音 / 文字（移动端可切换；Web 由环境决定默认项）。
  _HomeInputChannel _inputChannel = _HomeInputChannel.voice;

  late final WebHomeInputMode _webHomeInputMode;

  List<HistoryRecord> _items = [];
  StreamSubscription<SseHistoryPayload>? _sseSub;
  StreamSubscription<bool>? _wsReadySub;
  StreamSubscription<bool>? _voiceAsrReadySub;
  var _wsReady = false;
  var _voiceAsrReady = false;
  var _voiceAsrConnecting = false;
  /// 语音球按下期间为 true；松手递增 [_voiceHoldSeq] 以取消进行中的连接/开录。
  var _voiceHoldActive = false;
  var _voiceHoldSeq = 0;
  /// 当前手势是否在语音圆上按下（用于底部区跟踪移出圆取消）。
  var _activeVoicePointer = false;
  var _slideToCancel = false;
  final _voiceOrbKey = GlobalKey();
  static const _voiceOrbRadius = 66.0;
  static const _voiceOrbHitSlop = 8.0;
  SpeechEngine? _speechEngine;

  final _webController = TextEditingController();
  String? _chatReply;

  late final ValueNotifier<double> _voiceLevelNotifier;
  late final VoiceLevelSmoother _voiceLevelSmoother;
  late final ValueNotifier<RecordingDiagnosticsSnapshot> _recordingDiagnosticsNotifier;

  var _showRecordingDiagnostics = false;
  Timer? _diagnosticsTickTimer;
  Stopwatch? _listenStopwatch;
  DateTime? _lastDiagnosticsEmit;

  bool get _showRecordingStatsPanel =>
      _showRecordingDiagnostics &&
      _speechEngine == SpeechEngine.cloudAsr &&
      _inputChannel == _HomeInputChannel.voice &&
      _listening;

  @override
  void initState() {
    super.initState();
    _voiceLevelNotifier = ValueNotifier(0);
    _voiceLevelSmoother = VoiceLevelSmoother(_voiceLevelNotifier);
    _recordingDiagnosticsNotifier =
        ValueNotifier(const RecordingDiagnosticsSnapshot());
    _webHomeInputMode = kIsWeb ? resolveWebHomeInputMode() : WebHomeInputMode.text;
    if (kIsWeb && _webHomeInputMode == WebHomeInputMode.text) {
      _inputChannel = _HomeInputChannel.text;
    }
    _init();
  }

  bool get _canSwitchInputMode =>
      !kIsWeb || _webHomeInputMode == WebHomeInputMode.voice;

  Future<void> _bindVoiceAsrReadyListener() async {
    await _voiceAsrReadySub?.cancel();
    _voiceAsrReadySub = null;
    if (kIsWeb || _speechEngine != SpeechEngine.cloudAsr) {
      if (mounted) setState(() => _voiceAsrReady = true);
      return;
    }
    final client = ref.read(voiceAsrWsClientProvider);
    _voiceAsrReady = client.isReady;
    _voiceAsrReadySub = client.readyStream.listen((v) {
      if (mounted) setState(() => _voiceAsrReady = v);
    });
    if (mounted) setState(() {});
  }

  /// 进入首页或 deviceNo 就绪后尝试连接语音转写 WS（需已登录且有 deviceNo）。
  void _scheduleVoiceAsrConnectIfNeeded() {
    if (kIsWeb || _speechEngine != SpeechEngine.cloudAsr) return;
    if (!ref.read(sessionProvider).isLoggedIn) return;
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) return;
    unawaited(_connectVoiceAsrWsIfNeeded());
  }

  Future<void> _connectVoiceAsrWsIfNeeded() async {
    if (kIsWeb || _speechEngine != SpeechEngine.cloudAsr) return;
    if (_voiceAsrReady || _voiceAsrConnecting) return;
    if (!mounted) return;
    setState(() => _voiceAsrConnecting = true);
    try {
      final ok = await ref.read(voiceAsrWsClientProvider).connect();
      if (!mounted) return;
      setState(() {
        _voiceAsrReady = ok;
        _voiceAsrConnecting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _voiceAsrReady = false;
        _voiceAsrConnecting = false;
      });
    }
  }

  /// 用户选择语音输入时：按设置加载 Vosk / 系统 STT / 云端 ASR。
  Future<bool> _prepareVoiceInput() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音识别不可用，请改用文字输入')),
        );
      }
      return false;
    }

    try {
      final engine = await SpeechEngineStore.load();
      _showRecordingDiagnostics = await RecordingDiagnosticsStore.load();
      if (_speechEngine != engine) {
        _recognizer?.dispose();
        _recognizer = null;
        _voiceReady = false;
        _speechEngine = engine;
        await _bindVoiceAsrReadyListener();
      } else {
        _speechEngine ??= engine;
      }

      if (_speechEngine == SpeechEngine.cloudAsr && !_voiceAsrReady) {
        await _connectVoiceAsrWsIfNeeded();
        if (!_voiceAsrReady && !_voiceAsrConnecting && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('语音转写未连接，请检查网络')),
          );
        }
      }

      if (_voiceReady && _recognizer != null) {
        if (_speechEngine != SpeechEngine.cloudAsr || _voiceAsrReady) return true;
      }

      _recognizer ??= await createHomeSpeechRecognizer(ref);
      final ok = await _recognizer!.prepare();
      _voiceReady = ok && (_speechEngine != SpeechEngine.cloudAsr || _voiceAsrReady);
      if (!ok && mounted) {
        final failure = _recognizer!.lastPrepareFailure ?? HomeSpeechPrepareFailure.engineError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      } else if (!_voiceReady && mounted && _speechEngine == SpeechEngine.cloudAsr) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音转写服务未连接，请稍后再试')),
        );
      }
      return _voiceReady;
    } catch (e) {
      debugPrint('prepare voice input failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音识别初始化失败，请改用文字输入')),
        );
      }
      return false;
    }
  }

  Future<void> _selectInputChannel(_HomeInputChannel channel) async {
    if (_inputChannel == channel) return;
    setState(() => _inputChannel = channel);
    if (channel == _HomeInputChannel.voice) {
      _speechEngine ??= await SpeechEngineStore.load();
      await _bindVoiceAsrReadyListener();
      if (_speechEngine == SpeechEngine.cloudAsr) {
        unawaited(_connectVoiceAsrWsIfNeeded());
      }
      await _prepareVoiceInput();
      if (mounted) setState(() {});
    }
  }

  Future<void> _init() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _speechEngine = await SpeechEngineStore.load();
      _showRecordingDiagnostics = await RecordingDiagnosticsStore.load();
      await _bindVoiceAsrReadyListener();
    }
    if (ref.read(sessionProvider).isLoggedIn) {
      await ref.read(deviceNoNotifierProvider.notifier).refresh();
    }
    await ref.read(eventCatalogProvider.notifier).loadFromDisk();
    unawaited(ref.read(eventCatalogProvider.notifier).refreshFromRemote());
    _scheduleVoiceAsrConnectIfNeeded();
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

  /// 语音模式统一消息条：回复 > partial > 按住且无 partial 时的「聆听中…」。
  String? get _voiceStripText {
    if (_inputChannel != _HomeInputChannel.voice) return null;
    final reply = _chatReply?.trim();
    if (reply != null && reply.isNotEmpty) return reply;
    final partial = _partial.trim();
    if (partial.isNotEmpty) return partial;
    if (_listening) return '聆听中…';
    return null;
  }

  bool get _showVoiceMessageStrip => _voiceStripText != null;

  String get _voiceMessageStripKey {
    if (_isVoiceStripShowingReply) return 'reply';
    if (_listening && _partial.trim().isEmpty) return 'listening';
    return _partial;
  }

  bool get _isVoiceStripShowingReply {
    final reply = _chatReply?.trim();
    return _inputChannel == _HomeInputChannel.voice &&
        reply != null &&
        reply.isNotEmpty;
  }

  /// 底栏字幕框：仅文字模式展示服务端回复（语音由消息条展示）。
  String? _homeInputCaptionText() {
    if (_inputChannel != _HomeInputChannel.text) return null;
    final reply = _chatReply?.trim();
    if (reply != null && reply.isNotEmpty) return reply;
    return null;
  }

  bool get _isCaptionShowingServerReply {
    final reply = _chatReply?.trim();
    if (reply == null || reply.isEmpty) return false;
    return _homeInputCaptionText() == reply;
  }

  Widget _buildHomeInputCaption(BuildContext context) {
    final reply = _chatReply?.trim() ?? '';
    return HomeInputCaption(
      text: _homeInputCaptionText(),
      expandable: _isCaptionShowingServerReply,
      onExpand: _isCaptionShowingServerReply
          ? () => showHomeReplyBottomSheet(context, reply)
          : null,
    );
  }

  void _applyChatReply(String? reply) {
    final trimmed = reply?.trim();
    setState(() {
      _chatReply = trimmed != null && trimmed.isNotEmpty ? trimmed : null;
      _partial = '';
    });
  }

  Future<void> _onVoiceEnd() async {
    if (!_voiceReady || _recognizer == null) return;
    final recognizer = _recognizer!;
    final fromEngine = await recognizer.endSession();
    final text = (fromEngine.isNotEmpty ? fromEngine : _partial).trim();
    if (!mounted) return;
    setState(() {
      _listening = false;
      if (text.isNotEmpty) {
        _partial = text;
      }
    });
    _resetVoiceLevel();
    _stopRecordingDiagnosticsSession();
    if (text.isEmpty) return;
    if (!await _ensureRemoteGate()) return;
    if (!_ensureHistoryWsForSend()) return;
    final reply = await ref.read(feedRepositoryProvider).sendCommand(text);
    if (!mounted) return;
    _applyChatReply(reply);
  }

  void _releaseVoiceHold() {
    _voiceHoldActive = false;
    _voiceHoldSeq++;
  }

  bool _isVoiceHoldCurrent(int seq) => _voiceHoldActive && seq == _voiceHoldSeq;

  void _resetVoiceLevel() => _voiceLevelSmoother.reset();

  /// 设置页修改「显示录音数据」后需重新读取（[_init] 只执行一次）。
  Future<void> _refreshRecordingDiagnosticsPref() async {
    if (kIsWeb) return;
    final show = await RecordingDiagnosticsStore.load();
    if (!mounted) return;
    if (_showRecordingDiagnostics != show) {
      setState(() => _showRecordingDiagnostics = show);
    } else {
      _showRecordingDiagnostics = show;
    }
  }

  void _startRecordingDiagnosticsSession() {
    _listenStopwatch = Stopwatch()..start();
    _lastDiagnosticsEmit = null;
    _recordingDiagnosticsNotifier.value = const RecordingDiagnosticsSnapshot();
    _diagnosticsTickTimer?.cancel();
    _diagnosticsTickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_listening || _listenStopwatch == null) return;
      final cur = _recordingDiagnosticsNotifier.value;
      _recordingDiagnosticsNotifier.value = RecordingDiagnosticsSnapshot(
        chunkAvgAbs: cur.chunkAvgAbs,
        sessionAvgAbs: cur.sessionAvgAbs,
        elapsedSeconds: _listenStopwatch!.elapsedMilliseconds / 1000.0,
      );
    });
  }

  void _stopRecordingDiagnosticsSession() {
    _diagnosticsTickTimer?.cancel();
    _diagnosticsTickTimer = null;
    _listenStopwatch = null;
    _lastDiagnosticsEmit = null;
    _recordingDiagnosticsNotifier.value = const RecordingDiagnosticsSnapshot();
  }

  void _pushPcmDiagnostics({
    required int chunkAvgAbs,
    required int sessionAvgAbs,
  }) {
    final now = DateTime.now();
    if (_lastDiagnosticsEmit != null &&
        now.difference(_lastDiagnosticsEmit!) < const Duration(milliseconds: 100)) {
      return;
    }
    _lastDiagnosticsEmit = now;
    final elapsedMs = _listenStopwatch?.elapsedMilliseconds ?? 0;
    _recordingDiagnosticsNotifier.value = RecordingDiagnosticsSnapshot(
      chunkAvgAbs: chunkAvgAbs,
      sessionAvgAbs: sessionAvgAbs,
      elapsedSeconds: elapsedMs / 1000.0,
    );
  }

  Future<void> _onVoicePointerDown() async {
    final seq = ++_voiceHoldSeq;
    _voiceHoldActive = true;

    if (!await _ensureRemoteGate()) return;
    if (!_isVoiceHoldCurrent(seq) || !mounted) return;
    if (!_ensureHistoryWsForSend()) return;
    if (!await _prepareVoiceInput()) return;
    if (!_isVoiceHoldCurrent(seq) || !mounted || _recognizer == null) return;

    setState(() {
      _listening = true;
      _chatReply = null;
      _partial = '';
    });
    _resetVoiceLevel();
    if (_showRecordingDiagnostics && _speechEngine == SpeechEngine.cloudAsr) {
      _startRecordingDiagnosticsSession();
    }
    final cloudDiagnostics =
        _showRecordingDiagnostics && _speechEngine == SpeechEngine.cloudAsr;
    await _recognizer!.startSession(
      (partial) {
        if (!mounted || !_isVoiceHoldCurrent(seq)) return;
        setState(() => _partial = partial);
      },
      onLevel: (level) {
        if (!mounted || !_isVoiceHoldCurrent(seq)) return;
        _voiceLevelSmoother.pushRaw(level);
      },
      onPcmDiagnostics: cloudDiagnostics
          ? ({required chunkAvgAbs, required sessionAvgAbs}) {
              if (!mounted || !_isVoiceHoldCurrent(seq)) return;
              _pushPcmDiagnostics(
                chunkAvgAbs: chunkAvgAbs,
                sessionAvgAbs: sessionAvgAbs,
              );
            }
          : null,
    );
    if (!_isVoiceHoldCurrent(seq) && mounted && _listening) {
      await _recognizer?.cancelSession();
      if (!mounted) return;
      setState(() {
        _listening = false;
        _partial = '';
      });
      _resetVoiceLevel();
      _stopRecordingDiagnosticsSession();
    }
  }

  bool _hitInsideVoiceOrb(Offset globalPosition) {
    final box = _voiceOrbKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final local = box.globalToLocal(globalPosition);
    final center = Offset(box.size.width / 2, box.size.height / 2);
    return (local - center).distance <= _voiceOrbRadius + _voiceOrbHitSlop;
  }

  void _onVoiceAreaPointerDown(PointerDownEvent event) {
    if (!_hitInsideVoiceOrb(event.position)) return;
    _activeVoicePointer = true;
    setState(() => _slideToCancel = false);
    unawaited(_onVoicePointerDown());
  }

  void _onVoiceAreaPointerMove(PointerMoveEvent event) {
    if (!_activeVoicePointer) return;
    final cancel = !_hitInsideVoiceOrb(event.position);
    if (_slideToCancel != cancel) {
      setState(() => _slideToCancel = cancel);
    }
  }

  void _onVoiceAreaPointerUp(PointerUpEvent event) {
    if (!_activeVoicePointer) return;
    _activeVoicePointer = false;
    final cancel = _slideToCancel;
    _releaseVoiceHold();
    setState(() => _slideToCancel = false);
    if (cancel) {
      unawaited(_onVoiceCancel(skipReleaseHold: true));
    } else {
      unawaited(_onVoiceEnd());
    }
  }

  void _onVoiceAreaPointerCancel(PointerCancelEvent event) {
    if (!_activeVoicePointer) return;
    _activeVoicePointer = false;
    setState(() => _slideToCancel = false);
    unawaited(_onVoiceCancel());
  }

  Future<void> _onVoiceCancel({bool skipReleaseHold = false}) async {
    if (!skipReleaseHold) {
      _releaseVoiceHold();
    }
    if (_recognizer != null) {
      await _recognizer!.cancelSession();
    }
    if (!mounted) return;
    setState(() {
      _listening = false;
      _partial = '';
    });
    _resetVoiceLevel();
    _stopRecordingDiagnosticsSession();
  }

  Future<void> _onTextSubmit() async {
    final text = _webController.text.trim();
    if (text.isEmpty) return;
    if (!await _ensureRemoteGate()) return;
    if (!_ensureHistoryWsForSend()) return;
    final reply = await ref.read(feedRepositoryProvider).sendCommand(text);
    _webController.clear();
    if (!mounted) return;
    _applyChatReply(reply);
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
    _voiceAsrReadySub?.cancel();
    _webController.dispose();
    _voiceLevelNotifier.dispose();
    _recordingDiagnosticsNotifier.dispose();
    _diagnosticsTickTimer?.cancel();
    _recognizer?.dispose();
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
      _scheduleVoiceAsrConnectIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, loggedIn) {
      if (!loggedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(ref.read(deviceNoNotifierProvider.notifier).refresh());
        _reloadHistoryIfLoggedIn();
        _scheduleVoiceAsrConnectIfNeeded();
      });
    });
    ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
      if (!ref.read(sessionProvider).isLoggedIn) return;
      final nextDn = next.asData?.value;
      if (nextDn == null || nextDn.isEmpty) return;
      final prevDn = prev?.asData?.value;
      if (prevDn == nextDn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reloadHistoryIfLoggedIn();
        _scheduleVoiceAsrConnectIfNeeded();
      });
    });
    final todayTotals = aggregateTodayTotals(_items);
    final eventCatalog = ref.watch(eventCatalogProvider);
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
            icon: const Icon(Icons.insights),
            tooltip: '趋势',
            onPressed: () => context.push('/trends'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await context.push('/settings');
              if (mounted) await _refreshRecordingDiagnosticsPref();
            },
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
            HomeTodaySummaryPanel(totals: todayTotals),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _items.isEmpty && !showBindBanner
                        ? const Center(child: Text('暂无历史记录'))
                        : HomeHistoryTopFadeMask(
                            child: HomeHistoryScroll(
                              itemsAsc: _items,
                              eventCatalog: eventCatalog,
                              onRecordTap: _openHistory,
                            ),
                          ),
                  ),
                  if (_showVoiceMessageStrip)
                    HomeVoiceMessageStrip(
                      key: ValueKey<String>(_voiceMessageStripKey),
                      text: _voiceStripText!,
                      expandable: _isVoiceStripShowingReply,
                      onExpand: _isVoiceStripShowingReply
                          ? () {
                              final reply = _chatReply?.trim() ?? '';
                              if (reply.isNotEmpty) {
                                showHomeReplyBottomSheet(context, reply);
                              }
                            }
                          : null,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 220,
              child: _buildBottomInputPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInputPanel(BuildContext context) {
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.center,
          child: _buildPrimaryHomeInput(context),
        ),
        if (_inputChannel == _HomeInputChannel.voice)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onVoiceAreaPointerDown,
              onPointerMove: _onVoiceAreaPointerMove,
              onPointerUp: _onVoiceAreaPointerUp,
              onPointerCancel: _onVoiceAreaPointerCancel,
              child: const SizedBox.expand(),
            ),
          ),
        if (_showRecordingStatsPanel)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ListenableBuilder(
                  listenable: _recordingDiagnosticsNotifier,
                  builder: (context, _) => HomeVoiceRecordingStats(
                    stats: _recordingDiagnosticsNotifier.value,
                  ),
                ),
              ),
            ),
          ),
        if (_inputChannel == _HomeInputChannel.voice && _listening)
          Positioned(
            top: 4,
            right: _canSwitchInputMode ? 56 : 16,
            child: IgnorePointer(
              child: ListenableBuilder(
                listenable: _voiceLevelNotifier,
                builder: (context, _) => HomeVoiceLevelBars(
                  level: _voiceLevelNotifier.value,
                  cancelled: _slideToCancel,
                ),
              ),
            ),
          ),
        if (_canSwitchInputMode)
          Positioned(
            right: 16,
            bottom: 8,
            child: _buildInputModeToggle(context),
          ),
      ],
    );

    if (_inputChannel == _HomeInputChannel.voice) {
      return stack;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_homeInputCaptionText()?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(child: _buildHomeInputCaption(context)),
          ),
        Expanded(child: stack),
      ],
    );
  }

  Widget _buildPrimaryHomeInput(BuildContext context) {
    return _inputChannel == _HomeInputChannel.voice
        ? _buildVoiceOrb(context)
        : _buildTextInput(context);
  }

  Widget _buildInputModeToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(22),
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputModeIcon(
              context: context,
              selected: _inputChannel == _HomeInputChannel.voice,
              icon: Icons.mic_rounded,
              tooltip: '语音输入',
              onTap: () => unawaited(_selectInputChannel(_HomeInputChannel.voice)),
            ),
            _inputModeIcon(
              context: context,
              selected: _inputChannel == _HomeInputChannel.text,
              icon: Icons.keyboard_rounded,
              tooltip: '文字输入',
              onTap: () => unawaited(_selectInputChannel(_HomeInputChannel.text)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputModeIcon({
    required BuildContext context,
    required bool selected,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 22,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, _canSwitchInputMode ? 56 : 24, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _webController,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: kIsWeb ? '输入后按 Enter 或点按钮提交' : '输入后点按钮提交',
            ),
            onSubmitted: (_) => _onTextSubmit(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _onTextSubmit,
            icon: const Icon(Icons.send),
            label: const Text('提交到服务端'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOrb(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cloudMode = _speechEngine == SpeechEngine.cloudAsr;
    final cloudDisconnected = cloudMode && !_voiceAsrReady && !_voiceAsrConnecting;
    final color = cloudDisconnected ? scheme.outline : scheme.primary;
    final orbBorderColor = _listening && _slideToCancel
        ? scheme.error
        : (cloudMode ? null : color);

    IconData? cloudStatusIcon;
    String? cloudStatusLabel;
    Color? cloudStatusColor;
    if (cloudMode) {
      if (_voiceAsrConnecting) {
        cloudStatusIcon = Icons.sync_rounded;
        cloudStatusLabel = '连接中';
        cloudStatusColor = scheme.primary;
      } else if (_voiceAsrReady) {
        cloudStatusIcon = Icons.cloud_done_outlined;
        cloudStatusLabel = '已连接';
        cloudStatusColor = const Color(0xFF2E7D32);
      } else {
        cloudStatusIcon = Icons.cloud_off_outlined;
        cloudStatusLabel = '未连接';
        cloudStatusColor = scheme.error;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: _listening ? 1.06 : 1,
          duration: const Duration(milliseconds: 160),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                key: _voiceOrbKey,
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: orbBorderColor ?? cloudStatusColor ?? color,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      spreadRadius: 1,
                      color: color.withValues(alpha: 0.25),
                    ),
                  ],
                ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (cloudMode) ...[
                        Icon(cloudStatusIcon!, size: 20, color: cloudStatusColor),
                        const SizedBox(height: 2),
                        Text(
                          cloudStatusLabel!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cloudStatusColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        _listening
                            ? (_slideToCancel ? '松开取消' : '松开结束')
                            : '按住说话',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _listening && _slideToCancel ? scheme.error : color,
                          fontWeight: FontWeight.w600,
                          fontSize: cloudMode ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
              ),
              if (cloudMode)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _voiceAsrConnecting
                          ? scheme.primary
                          : (_voiceAsrReady ? const Color(0xFF2E7D32) : scheme.error),
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
