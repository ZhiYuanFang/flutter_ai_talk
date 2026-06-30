import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/ai_quota_errors.dart';
import '../api/api_exceptions.dart';
import '../audio/voice_level_smoother.dart';
import '../asr/home_speech_factory.dart';
import '../asr/home_speech_recognizer.dart';
import '../config/ai_chat_data_consent_store.dart';
import '../config/event_button_usage_store.dart';
import '../config/home_input_channel_store.dart';
import '../config/recording_diagnostics_store.dart';
import '../config/speech_engine.dart';
import '../config/speech_engine_store.dart';
import '../providers/voice_asr_ws_provider.dart';
import '../ucg/providers/ucg_providers.dart';
import '../data/event_branding.dart';
import '../bootstrap/cold_start_background_sync.dart';
import '../data/event_catalog_state.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_catalog_usage_sort.dart';
import '../data/event_definition.dart';
import '../data/feed_repository.dart';
import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/history_record_metric.dart';
import '../data/models.dart';
import 'event_catalog_picker_sheet.dart';
import 'home_button_event_grid.dart'
    show HomeButtonEventGrid, buttonGridRowEvents, kHomeButtonInputPanelHeight;
import 'home_event_record_fly_overlay.dart';
import 'home_active_timing_reminder_dialog.dart';
import 'home_history_edit_sheet.dart';
import 'home_history_scroll.dart';
import 'home_history_ws_status_banner.dart';
import 'home_immersive_header.dart';
import 'home_number_event_sheet.dart';
import 'home_history_timeline_tile.dart';
import 'home_input_channel.dart';
import 'home_input_caption.dart';
import 'home_input_mode_dock.dart';
import 'home_reply_bottom_sheet.dart';
import 'home_event_hourly_trend_sheet.dart';
import 'home_today_summary_panel.dart';
import 'home_voice_level_bars.dart';
import 'home_voice_message_strip.dart';
import 'home_voice_recording_stats.dart';
import '../providers/device_no_notifier.dart';
import '../providers/sign_in_channel_provider.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/ai_quota_provider.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/settings_baby.dart';
import '../data/repositories.dart' show readPackageVersion;
import '../data/notify_banner_repository.dart';
import '../providers/toast_bus.dart';
import 'widgets/ai_quota_remaining_hint.dart';
import 'widgets/app_empty_state_gallery.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/managed_keyboard_text_field.dart';
import '../ucg/ui/widgets/ucg_visual_widgets.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_visual_tokens.dart';
import '../theme/theme_bootstrap_cache.dart';
import 'notify_banner_prompt.dart';
import 'version_prompt.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onDockDraggingChanged});

  /// 输入模式 dock 拖动 reposition 时通知上层暂停 PageView 横滑。
  final ValueChanged<bool>? onDockDraggingChanged;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

const _kVoiceInputPanelHeight = 200.0;
const _kVoiceTextInputPanelHeight = 220.0;
const _kVoiceOrbVisualSize = 132.0;
const _kInputPanelAnimationDuration = Duration(milliseconds: 220);
const _kImmersiveHeaderContentSpacing = 10.0;

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  HomeSpeechRecognizer? _recognizer;
  var _voiceReady = false;
  var _listening = false;
  String _partial = '';

  /// 首页输入方式：全平台默认事件按钮；dock 在平台通道集内轮转。
  HomeInputChannel _inputChannel = HomeInputChannel.buttons;

  HomeHistoryNotifier get _history => ref.read(homeHistoryProvider.notifier);
  final Set<String> _stoppingRecordIds = {};
  StreamSubscription<SseHistoryPayload>? _sseSub;
  StreamSubscription<bool>? _wsReadySub;
  StreamSubscription<HistoryWsPhase>? _wsPhaseSub;
  StreamSubscription<bool>? _voiceAsrReadySub;
  var _wsReady = false;
  HistoryWsPhase _historyWsPhase = HistoryWsPhase.disconnected;
  var _historyWsManualReconnecting = false;
  var _gaveUpSnackbarShown = false;
  var _voiceAsrReady = false;
  var _voiceAsrConnecting = false;
  /// 语音球按下期间为 true；松手递增 [_voiceHoldSeq] 以取消进行中的连接/开录。
  var _voiceHoldActive = false;
  var _voiceHoldSeq = 0;
  /// 当前手势是否在语音圆上按下（用于底部区跟踪移出圆取消）。
  var _activeVoicePointer = false;
  var _slideToCancel = false;
  final _voiceOrbKey = GlobalKey();
  static const _voiceOrbRadius = _kVoiceOrbVisualSize / 2;
  static const _voiceOrbHitSlop = 8.0;
  SpeechEngine? _speechEngine;

  final _webController = TextEditingController();
  final _webFocusNode = FocusNode();
  final _webInputAnchorKey = GlobalKey();
  String? _chatReply;

  late final ValueNotifier<double> _voiceLevelNotifier;
  late final VoiceLevelSmoother _voiceLevelSmoother;
  late final ValueNotifier<RecordingDiagnosticsSnapshot> _recordingDiagnosticsNotifier;

  var _showRecordingDiagnostics = false;
  Timer? _diagnosticsTickTimer;
  Stopwatch? _listenStopwatch;
  DateTime? _lastDiagnosticsEmit;
  var _eventCatalogRetryDone = false;

  final _historyScrollKey = GlobalKey<HomeHistoryScrollState>();
  String? _flyTargetRecordId;
  EventDefinition? _flyEvent;
  int _flySession = 0;
  final _recentlyReplacedIds = <String>{};
  final _pendingIdRandom = Random();
  var _activeTimingReminderShowing = false;
  String? _pendingReminderExcludeId;
  Map<String, int>? _eventUsageCounts;
  List<EventDefinition>? _buttonGridOrder;
  var _voiceSendSeq = 0;
  var _voiceSendWatchdogCorr = 0;
  bool get _showRecordingStatsPanel =>
      _showRecordingDiagnostics &&
      _speechEngine == SpeechEngine.cloudAsr &&
      _inputChannel == HomeInputChannel.voice &&
      _listening;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceLevelNotifier = ValueNotifier(0);
    _voiceLevelSmoother = VoiceLevelSmoother(_voiceLevelNotifier);
    _recordingDiagnosticsNotifier =
        ValueNotifier(const RecordingDiagnosticsSnapshot());
    if (ref.read(sessionProvider).isLoggedIn) {
      ref.read(ucgRepositoryProvider);
      unawaited(ref.read(deviceNoNotifierProvider.notifier).refresh());
      unawaited(ref.read(signInChannelProvider.notifier).restoreFromPrefs());
    }
    unawaited(_restoreSavedInputChannel());
    unawaited(_loadEventUsageAndButtonOrder());
    _init();
  }

  String _inputChannelStorageKey(HomeInputChannel channel) {
    return switch (channel) {
      HomeInputChannel.voice => 'voice',
      HomeInputChannel.text => 'text',
      HomeInputChannel.buttons => 'buttons',
    };
  }

  HomeInputChannel? _inputChannelFromStorage(String? raw) {
    return switch (raw) {
      'voice' => HomeInputChannel.voice,
      'text' => HomeInputChannel.text,
      'buttons' => HomeInputChannel.buttons,
      _ => null,
    };
  }

  bool _hasBoundDeviceNo() {
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    return dn != null && dn.isNotEmpty;
  }

  bool _isInputChannelAvailable(HomeInputChannel channel) {
    if (kIsWeb) {
      return switch (channel) {
        HomeInputChannel.buttons || HomeInputChannel.text => true,
        HomeInputChannel.voice => false,
      };
    }
    return switch (channel) {
      HomeInputChannel.voice => _hasBoundDeviceNo(),
      HomeInputChannel.buttons => true,
      HomeInputChannel.text => false,
    };
  }

  Future<void> _restoreSavedInputChannel() async {
    final saved = await HomeInputChannelStore.load();
    if (!mounted) return;
    final channel = _inputChannelFromStorage(saved);
    if (channel == null || !_isInputChannelAvailable(channel)) return;
    if (_inputChannel == channel) return;
    if (channel == HomeInputChannel.voice) {
      await _selectInputChannel(channel, persist: false);
      return;
    }
    setState(() => _inputChannel = channel);
    _scheduleHistoryReanchorAfterInputModeChange();
  }

  List<HomeInputChannel> get _dockCycleChannels => kIsWeb
      ? const [HomeInputChannel.buttons, HomeInputChannel.text]
      : const [HomeInputChannel.buttons, HomeInputChannel.voice];

  double get _bottomInputPanelHeight => switch (_inputChannel) {
        HomeInputChannel.buttons => kHomeButtonInputPanelHeight,
        HomeInputChannel.voice => _kVoiceInputPanelHeight,
        HomeInputChannel.text => _kVoiceTextInputPanelHeight,
      };

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

  /// 用户选择语音输入时：按设置加载系统 STT / 云端 ASR。
  Future<bool> _prepareVoiceInput() async {
    if (kIsWeb) {
      if (mounted) {
        showAppToast('语音识别不可用，请改用文字输入', tone: AppToastTone.error);
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
          showAppToast('语音转写未连接，请检查网络', tone: AppToastTone.error);
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
        showAppToast(failure.message(forWeb: false), tone: AppToastTone.error);
      } else if (!_voiceReady && mounted && _speechEngine == SpeechEngine.cloudAsr) {
        showAppToast('语音转写服务未连接，请稍后再试', tone: AppToastTone.error);
      }
      return _voiceReady;
    } catch (_) {
      if (mounted) {
        showAppToast('语音识别初始化失败，请切换到事件记录模式', tone: AppToastTone.error);
      }
      return false;
    }
  }

  Future<void> _selectInputChannel(HomeInputChannel channel, {bool persist = true}) async {
    if (_inputChannel == channel) return;
    if (channel == HomeInputChannel.voice && !_hasBoundDeviceNo()) {
      return;
    }
    if (channel != HomeInputChannel.voice && _listening) {
      await _onVoiceCancel();
    }
    setState(() => _inputChannel = channel);
    _scheduleHistoryReanchorAfterInputModeChange();
    if (persist) {
      unawaited(HomeInputChannelStore.save(_inputChannelStorageKey(channel)));
    }
    if (channel == HomeInputChannel.voice) {
      _speechEngine ??= await SpeechEngineStore.load();
      await _bindVoiceAsrReadyListener();
      if (_speechEngine == SpeechEngine.cloudAsr) {
        unawaited(_connectVoiceAsrWsIfNeeded());
      }
      await _prepareVoiceInput();
      if (mounted) setState(() {});
    }
  }

  void _scheduleHistoryReanchorAfterInputModeChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animate = !MediaQuery.disableAnimationsOf(context);
      void runReanchor() {
        _historyScrollKey.currentState?.reanchorAfterViewportChange(animate: animate);
      }

      runReanchor();
      if (animate) {
        Future<void>.delayed(_kInputPanelAnimationDuration, () {
          if (!mounted) return;
          runReanchor();
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          runReanchor();
        });
      }
    });
  }

  bool _hasActiveTimingForEvent(EventDefinition event) {
    final items = ref.read(homeHistoryProvider).items;
    for (final record in items) {
      if (!isActiveTimingRecord(record)) continue;
      if (historyEventIdsMatch(record.rawPayload['eventId'], event.id)) {
        return true;
      }
    }
    return false;
  }

  String _newPendingHistoryId() {
    return 'pending:${DateTime.now().microsecondsSinceEpoch}_${_pendingIdRandom.nextInt(0x7fffffff)}';
  }

  bool _hasPendingOptimisticRows() {
    return ref.read(homeHistoryProvider).items.any((e) => isPendingHistoryId(e.id));
  }

  void _markRecentlyReplaced(String serverId) {
    _recentlyReplacedIds.add(serverId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recentlyReplacedIds.remove(serverId);
    });
  }

  void _scheduleFlyForRecord(String recordId, EventDefinition? event) {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() {
      _flySession++;
      _flyTargetRecordId = recordId;
      _flyEvent = event;
    });
    _history.setFlyAnimationFrozen(true);
  }

  Future<void> _submitEventAdd({
    required EventDefinition event,
    required int eventNumber,
    required DateTime startTime,
    required DateTime endTime,
    String remark = '',
  }) async {
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) return;
    final body = buildEventAddBody(
      deviceNo: dn,
      event: event,
      eventNumber: eventNumber,
      startTime: startTime,
      endTime: endTime,
      remark: remark,
    );
    final pendingId = _newPendingHistoryId();
    final optimistic = historyRecordFromAddBody(body, id: pendingId);
    final scroll = _historyScrollKey.currentState;
    if (scroll != null) {
      scroll.scrollToBottom(force: true);
    }
    _history.insertOptimistic(optimistic);
    if (mounted) {
      _scheduleFlyForRecord(pendingId, event);
    }

    final serverId = await ref.read(feedRepositoryProvider).addHistoryEvent(body);
    if (!mounted) return;
    if (serverId != null) {
      _markRecentlyReplaced(serverId);
      _history.replaceRecordId(pendingId, serverId);
      _scheduleActiveTimingReminderAfterAdd(excludeRecordId: serverId);
      unawaited(EventButtonUsageStore.increment(event.id));
    } else {
      _cancelFlyAndRemovePending(pendingId);
    }
  }

  Future<void> _onEventGridTap(EventDefinition event) async {
    final catalog = ref.read(eventCatalogProvider).items;
    if (hasChildren(catalog, event.id)) {
      if (!mounted) return;
      final leaf = await showEventCatalogPickerSheet(
        context,
        catalog: catalog,
        root: event,
        usageCounts: _eventUsageCounts,
        onToast: (msg) => ref.showApiToast(msg),
      );
      if (leaf == null || !mounted) return;
      await _onEventButtonTap(leaf);
      return;
    }
    await _onEventButtonTap(event);
  }

  Future<void> _onEventButtonTap(EventDefinition event) async {
    if (!event.hasValidEventType) return;
    if (!await _ensureRemoteGate()) return;
    if (!_ensureHistoryWsForSend()) return;

    final type = event.parsedEventType!;
    switch (type) {
      case EventCatalogEventType.time:
        if (_hasActiveTimingForEvent(event)) {
          ref.showApiToast('${event.name}已在计时中');
          return;
        }
        final now = DateTime.now();
        await _submitEventAdd(
          event: event,
          eventNumber: 0,
          startTime: now,
          endTime: DateTime.fromMillisecondsSinceEpoch(0),
        );
      case EventCatalogEventType.one:
        final now = DateTime.now();
        await _submitEventAdd(
          event: event,
          eventNumber: 1,
          startTime: now,
          endTime: now,
        );
      case EventCatalogEventType.number:
        if (!mounted) return;
        final result = await showHomeNumberEventSheet(context, event);
        if (result == null || !mounted) return;
        await _submitEventAdd(
          event: event,
          eventNumber: result.eventNumber,
          startTime: result.startTime,
          endTime: result.startTime,
          remark: result.remark,
        );
    }
  }

  Future<void> _init() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      unawaited(_initMobileSpeech());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runHomeDialogBootstrap());
    });
    _scheduleVoiceAsrConnectIfNeeded();
    unawaited(_bootstrapHomeData());
    final feed = ref.read(feedRepositoryProvider);
    _wsReady = feed.isHistoryWebSocketReady;
    _historyWsPhase = feed.historyWsPhase;
    _wsReadySub = feed.historyWsReadyStream.listen((v) {
      if (!mounted) return;
      setState(() {
        _wsReady = v;
        if (v) _gaveUpSnackbarShown = false;
      });
    });
    _wsPhaseSub = feed.historyWsPhaseStream.listen((phase) {
      if (!mounted) return;
      setState(() {
        _historyWsPhase = phase;
        if (phase != HistoryWsPhase.gaveUp) {
          _gaveUpSnackbarShown = false;
        }
      });
      if (phase == HistoryWsPhase.gaveUp) {
        _maybeShowGaveUpSnackbar();
      }
    });
    _sseSub = feed.watchLatest().listen((payload) {
      final removed = payload.removedRecordId;
      if (removed != null) {
        _history.removeRecord(removed);
        return;
      }
      final r = payload.record!;
      final isNew = !ref.read(homeHistoryProvider).items.any((e) => e.id == r.id);
      final flySuppressed = _shouldScheduleWsFly(r.id);
      _history.upsertRecord(r);
      if (isNew && !flySuppressed) {
        _onWsNewHistoryRecord(r);
        _scheduleActiveTimingReminderAfterAdd(excludeRecordId: r.id);
      }
    });
  }

  bool _shouldScheduleWsFly(String recordId) {
    if (_recentlyReplacedIds.contains(recordId)) return true;
    if (_hasPendingOptimisticRows()) return true;
    return false;
  }

  void _onWsNewHistoryRecord(HistoryRecord record) {
    final event = lookupEventForRecord(ref.read(eventCatalogProvider).items, record);
    _scheduleFlyForRecord(record.id, event);
  }

  void _cancelFlyAndRemovePending(String pendingId) {
    _history.setFlyAnimationFrozen(false);
    _history.removeById(pendingId);
    if (!mounted) return;
    setState(() {
      _flyTargetRecordId = null;
      _flyEvent = null;
    });
  }

  void _onFlyOverlayComplete(int session) {
    if (!mounted) return;
    if (session != _flySession) return;
    _history.setFlyAnimationFrozen(false);
    setState(() {
      _flyTargetRecordId = null;
      _flyEvent = null;
    });
    final pendingExclude = _pendingReminderExcludeId;
    if (pendingExclude != null) {
      _pendingReminderExcludeId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_presentActiveTimingReminder(excludeRecordId: pendingExclude));
      });
    }
  }

  List<HistoryRecord> _otherActiveTimingCandidates({required String excludeRecordId}) {
    return ref
        .read(homeHistoryProvider)
        .items
        .where(
          (r) =>
              r.id != excludeRecordId &&
              !isPendingHistoryId(r.id) &&
              isActiveTimingRecord(r),
        )
        .toList();
  }

  void _scheduleActiveTimingReminderAfterAdd({required String excludeRecordId}) {
    if (_otherActiveTimingCandidates(excludeRecordId: excludeRecordId).isEmpty) return;
    if (_activeTimingReminderShowing) return;

    if (_flyTargetRecordId != null) {
      _pendingReminderExcludeId = excludeRecordId;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_presentActiveTimingReminder(excludeRecordId: excludeRecordId));
    });
  }

  Future<void> _presentActiveTimingReminder({required String excludeRecordId}) async {
    if (!mounted) return;
    if (_activeTimingReminderShowing) return;
    final candidates = _otherActiveTimingCandidates(excludeRecordId: excludeRecordId);
    if (candidates.isEmpty) return;

    _activeTimingReminderShowing = true;
    try {
      await showHomeActiveTimingReminderDialog(
        context: context,
        candidates: candidates,
        eventCatalog: ref.read(eventCatalogProvider).items,
        onStop: _stopActiveTimer,
        isRecordActivelyTiming: _isRecordActivelyTiming,
        onToast: (msg) => ref.showApiToast(msg),
      );
    } finally {
      _activeTimingReminderShowing = false;
    }
  }

  Future<void> _initMobileSpeech() async {
    _speechEngine = await SpeechEngineStore.load();
    _showRecordingDiagnostics = await RecordingDiagnosticsStore.load();
    await _bindVoiceAsrReadyListener();
    if (mounted) setState(() {});
  }

  /// 维护公告优先于版本弹窗；未登录用户也会拉取 notify banner。
  Future<void> _runHomeDialogBootstrap() async {
    // try {
    //   await maybeShowNotifyBannerPrompt(
    //     context: context,
    //     repo: const NotifyBannerRepository(),
    //   );
    // } catch (_) {}
    if (!mounted) return;
    await _runPostLoginBootstrap();
  }

  /// 版本检查与宝宝信息：Splash 已做本地门禁后进主页，此处后台补全。
  Future<void> _runPostLoginBootstrap() async {
    if (!ref.read(sessionProvider).isLoggedIn) return;
    try {
      final currentVersion = await readPackageVersion();
      if (!mounted) return;
      await maybeShowVersionPrompt(
        context: context,
        repo: ref.read(versionRepositoryProvider),
        currentVersion: currentVersion,
      );
    } catch (_) {}
    if (!mounted) return;
    try {
      final baby = await ref.read(settingsRepositoryProvider).loadBaby();
      ref.read(babySexProvider.notifier).state = baby.sex;
      await persistCachedBabySex(baby.sex);
    } catch (_) {}
  }

  HistoryRecord _recordWithEndTime(HistoryRecord r, DateTime end) {
    final p = Map<String, Object?>.from(r.rawPayload);
    p['endTime'] = historyDateTimeToUnixSeconds(end);
    return HistoryRecord(
      id: r.id,
      createdAt: r.createdAt,
      eventName: r.eventName,
      action: r.action,
      rawPayload: p,
    );
  }

  bool _isRecordActivelyTiming(String recordId) {
    for (final e in ref.read(homeHistoryProvider).items) {
      if (e.id == recordId) return isActiveTimingRecord(e);
    }
    return false;
  }

  Future<bool> _stopActiveTimer(HistoryRecord record) async {
    if (isPendingHistoryId(record.id)) return false;
    if (_stoppingRecordIds.contains(record.id)) return false;
    setState(() => _stoppingRecordIds.add(record.id));
    final p = record.rawPayload;
    final remark = (p['remark'] as String?) ?? '';
    final end = DateTime.now();
    var ok = await ref.read(feedRepositoryProvider).updateHistoryRecord(
          record.id,
          remark: remark,
          startTime: activeTimingStartAt(record),
          endTime: end,
          fallbackRecord: record,
        );
    if (!mounted) return false;
    if (ok) {
      _history.replaceRecord(_recordWithEndTime(record, end));
    } else if (!_isRecordActivelyTiming(record.id)) {
      // 接口失败但 WS/本地已写入结束时间时，仍视为成功以便关闭提醒框。
      ok = true;
    }
    setState(() => _stoppingRecordIds.remove(record.id));
    return ok;
  }

  Future<void> _loadEventUsageAndButtonOrder() async {
    final counts = await EventButtonUsageStore.loadAll();
    if (!mounted) return;

    var catalog = ref.read(eventCatalogProvider).items;
    if (catalog.isEmpty) {
      await ref.read(eventCatalogProvider.notifier).loadFromDisk();
      catalog = ref.read(eventCatalogProvider).items;
    }

    List<EventDefinition>? order;
    if (catalog.isNotEmpty) {
      final roots = buttonGridRowEvents(catalog);
      order = sortEventsBySubtreeUsage(catalog, roots, counts);
    }

    if (!mounted) return;
    setState(() {
      _eventUsageCounts = counts;
      _buttonGridOrder = order;
    });
  }

  Future<void> _refreshEventCatalogIfReady() async {
    if (!ref.read(sessionProvider).isLoggedIn) return;
    await ref.read(eventCatalogProvider.notifier).refreshFromRemote();
  }

  Future<void> _retryEventCatalogIfEmpty() async {
    if (_eventCatalogRetryDone) return;
    if (ref.read(eventCatalogProvider).items.isNotEmpty) return;
    _eventCatalogRetryDone = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (ref.read(eventCatalogProvider).items.isNotEmpty) return;
    await ref.read(eventCatalogProvider.notifier).bootstrap();
  }

  /// 事件目录 + 历史：Splash 已 hydrate；此处触发后台远端 sync。
  Future<void> _bootstrapHomeData() async {
    await ColdStartBackgroundSync.run(ref);
    if (ref.read(eventCatalogProvider).items.isEmpty) {
      unawaited(_retryEventCatalogIfEmpty());
    }
  }

  Future<bool> _ensureRemoteGate() async {
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    if (!loggedIn) {
      final go = await showGlassConfirmDialog(
            context,
            title: '需要登录',
            message: '请先登录后再操作。',
            confirmLabel: '去登录',
          ) ??
          false;
      if (go && mounted) await context.push('/login');
      return false;
    }
    final dnState = ref.read(deviceNoNotifierProvider);
    if (dnState.isLoading) return true;
    final dn = dnState.asData?.value;
    if (dn == null || dn.isEmpty) {
      final go = await showGlassConfirmDialog(
            context,
            title: '绑定宝宝',
            message: '请先绑定宝宝信息。',
            confirmLabel: '去绑定',
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
      ref.showApiToastError('历史实时连接未就绪，无法发送，请点击下方横幅重连后再试');
    }
    return ok;
  }

  Future<bool> _ensureAiChatDataConsent() async {
    if (await AiChatDataConsentStore.load()) return true;
    if (!mounted) return false;
    final agreed = await showGlassConfirmDialog(
          context,
          title: '使用 AI 对话前请知悉',
          message: '您输入的内容及近期喂养记录将发送至第三方 AI 服务，用于分析与回复。',
          confirmLabel: '同意并继续',
        ) ??
        false;
    if (!agreed) return false;
    await AiChatDataConsentStore.saveAccepted();
    return true;
  }

  void _maybeShowGaveUpSnackbar() {
    if (_gaveUpSnackbarShown) return;
    if (ref.read(sessionProvider).isRefreshInFlight) return;
    _gaveUpSnackbarShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_historyWsPhase != HistoryWsPhase.gaveUp) return;
      if (ref.read(sessionProvider).isRefreshInFlight) return;
      ref.showApiToastError(kHomeHistoryWsGaveUpMessage);
    });
  }

  String _historyWsBannerMessage() {
    return switch (_historyWsPhase) {
      HistoryWsPhase.gaveUp => kHomeHistoryWsGaveUpMessage,
      HistoryWsPhase.ready ||
      HistoryWsPhase.disconnected ||
      HistoryWsPhase.autoReconnecting =>
        kHomeHistoryWsDisconnectMessage,
    };
  }

  Future<void> _reconnectHistoryWs() async {
    if (_historyWsManualReconnecting) return;
    setState(() => _historyWsManualReconnecting = true);
    try {
      await ref
          .read(feedRepositoryProvider)
          .reconnectHistoryWebSocket(resetStrike: true);
    } finally {
      if (mounted) setState(() => _historyWsManualReconnecting = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppLifecycleResumed());
    }
  }

  /// 回前台：先单飞 ensureFreshSession，再并行 WS 重连与 UCG 未读同步。
  Future<void> _onAppLifecycleResumed() async {
    await ref.read(sessionProvider).ensureFreshSession();
    ref.read(feedRepositoryProvider).onAppLifecycleResumed();
    ref.read(ucgRepositoryProvider).onAppLifecycleResumed();
    unawaited(ref.read(ucgUnreadSyncProvider)());
  }

  Future<void> _reloadHistoryIfLoggedIn() async {
    await _history.bootstrap();
  }

  /// 语音模式统一消息条：回复 > partial > 按住且无 partial 时的「聆听中…」。
  String? get _voiceStripText {
    if (_inputChannel != HomeInputChannel.voice) return null;
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
    return _inputChannel == HomeInputChannel.voice &&
        reply != null &&
        reply.isNotEmpty;
  }

  /// 底栏字幕框：仅文字模式展示服务端回复（语音由消息条展示）。
  String? _homeInputCaptionText() {
    if (_inputChannel != HomeInputChannel.text) return null;
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
    final corr = ++_voiceSendSeq;
    if (!_ensureHistoryWsForSend()) return;
    try {
      final reply = await ref.read(feedRepositoryProvider).sendCommand(text);
      _scheduleVoiceWsWatchdog(corr);
      if (!mounted) return;
      ref.invalidate(voiceAiQuotaProvider);
      _applyChatReply(reply);
    } on ApiBusinessException catch (e) {
      if (!mounted) return;
      if (!await handleAiQuotaException(context, e)) {
        ref.showApiToastError(e.message);
      }
    }
  }

  void _scheduleVoiceWsWatchdog(int corr) {
    _voiceSendWatchdogCorr = corr;
    unawaited(Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted || _voiceSendWatchdogCorr != corr) return;
      if (_voiceSendWatchdogCorr == corr) {
        _voiceSendWatchdogCorr = 0;
      }
    }));
  }

  void _releaseVoiceHold() {
    _voiceHoldActive = false;
    _voiceHoldSeq++;
  }

  bool _isVoiceHoldCurrent(int seq) => _voiceHoldActive && seq == _voiceHoldSeq;

  void _resetVoiceLevel() => _voiceLevelSmoother.reset();

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
    if (!await _ensureAiChatDataConsent()) return;
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
    if (!await _ensureAiChatDataConsent()) return;
    try {
      final reply = await ref.read(feedRepositoryProvider).sendCommand(text);
      _webController.clear();
      if (!mounted) return;
      ref.invalidate(voiceAiQuotaProvider);
      _applyChatReply(reply);
    } on ApiBusinessException catch (e) {
      if (!mounted) return;
      if (!await handleAiQuotaException(context, e)) {
        ref.showApiToastError(e.message);
      }
    }
  }

  Future<void> _openHistory(HistoryRecord record) async {
    if (!await _ensureRemoteGate()) return;
    if (!mounted) return;
    await showHomeHistoryEditSheet(
      context,
      record: record,
      eventCatalog: ref.read(eventCatalogProvider).items,
      history: _history,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sseSub?.cancel();
    _wsReadySub?.cancel();
    _wsPhaseSub?.cancel();
    _voiceAsrReadySub?.cancel();
    _webFocusNode.dispose();
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
      await _refreshEventCatalogIfReady();
      await _reloadHistoryIfLoggedIn();
      _scheduleVoiceAsrConnectIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 登录后停留喂养页即初始化 UCG repo 与未读同步，无需先进入广场。
    ref.watch(ucgRepositoryProvider);

    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, loggedIn) {
      if (!loggedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_refreshEventCatalogIfReady());
        _reloadHistoryIfLoggedIn();
        _scheduleVoiceAsrConnectIfNeeded();
      });
    });
    ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
      if (!ref.read(sessionProvider).isLoggedIn) return;
      final nextDn = next.asData?.value;
      if (nextDn == null || nextDn.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_inputChannel != HomeInputChannel.buttons) {
            unawaited(_selectInputChannel(HomeInputChannel.buttons, persist: false));
          }
        });
        return;
      }
      final prevDn = prev?.asData?.value;
      if (prevDn == nextDn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_refreshEventCatalogIfReady());
        _reloadHistoryIfLoggedIn();
        _scheduleVoiceAsrConnectIfNeeded();
      });
    });
    ref.listen<EventCatalogState>(eventCatalogProvider, (prev, next) {
      if (prev != null && prev.items.isEmpty && next.items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_loadEventUsageAndButtonOrder());
        });
      }
      if (next.items.isNotEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_retryEventCatalogIfEmpty());
      });
    });
    final homeHistory = ref.watch(homeHistoryProvider);
    final historyItems = homeHistory.items;
    final historyInitialLoadDone = homeHistory.initialLoadDone;
    final todayTotals = aggregateTodayTotals(historyItems);
    final catalogState = ref.watch(eventCatalogProvider);
    final eventCatalogItems = catalogState.items;
    // 仅当已登录且本地未缓存 deviceNo 时提示绑定；游客见下方登录引导空态。
    final dnAsync = ref.watch(deviceNoNotifierProvider);
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final needsGuestLogin = !loggedIn;
    final needsDeviceBind = loggedIn &&
        dnAsync.maybeWhen(
          data: (dn) => dn == null || dn.isEmpty,
          orElse: () => false,
        );
    final blockHomeInputChrome = needsGuestLogin || needsDeviceBind;
    if (blockHomeInputChrome && _inputChannel != HomeInputChannel.buttons) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_selectInputChannel(HomeInputChannel.buttons, persist: false));
      });
    }
    // 只有当不需要全屏 3D 动画（即不是无历史记录时）才显示 Banner。
    // 在本逻辑中，如果 needsDeviceBind 为 true，我们将显示全屏引导，所以 showBindBanner 设为 false。
    final showBindBanner = needsDeviceBind && historyItems.isNotEmpty;
    final refreshInFlight = ref.watch(sessionProvider.select((s) => s.isRefreshInFlight));
    final showWsRefreshBanner = loggedIn &&
        !needsDeviceBind &&
        !_wsReady &&
        refreshInFlight &&
        _historyWsPhase != HistoryWsPhase.autoReconnecting;
    final showWsDisconnectBanner = loggedIn &&
        !needsDeviceBind &&
        !_wsReady &&
        !refreshInFlight &&
        _historyWsPhase != HistoryWsPhase.autoReconnecting;
    final showWsBanner = showWsRefreshBanner || showWsDisconnectBanner;
    final wsBannerMessage = showWsRefreshBanner
        ? kHomeHistoryWsRefreshRecoveryMessage
        : _historyWsBannerMessage();
    final wsBannerVariant =
        showWsRefreshBanner ? HomeHistoryWsBannerVariant.info : HomeHistoryWsBannerVariant.error;
    final wsBannerReconnecting =
        _historyWsPhase == HistoryWsPhase.autoReconnecting || _historyWsManualReconnecting;
    final wsBannerTapEnabled = !showWsRefreshBanner;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shellBg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: shellBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dockBounds = Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    HomeImmersiveHeader(
                      title: '胖宝',
                      onTrendsTap: () => context.push('/trends'),
                      onPangbaoTap: () => context.push('/pangbao'),
                      onSettingsTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: _kImmersiveHeaderContentSpacing),
                    if (showBindBanner)
                      Material(
                        color: themePrimaryBlend(context, alpha: 0.14),
                        child: InkWell(
                          onTap: _onBindBannerTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.child_care_outlined, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '请绑定宝宝信息',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    HomeTodaySummaryPanel(
                      totals: todayTotals,
                      onChipTap: (total, event) {
                        unawaited(
                          showHomeEventHourlyTrendSheet(
                            context,
                            total: total,
                            event: event,
                            historyItems: historyItems,
                            ref: ref,
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: historyItems.isEmpty
                                ? (needsGuestLogin
                                    ? AppEmptyStateGallery(
                                        animationPath: 'assets/images/ani_baby_welcome.json',
                                        title: '尚未登录',
                                        subtitle: '登录后即可记录与查看宝宝日常',
                                        footnote: '左滑可先逛逛广场，看看其他宝妈宝爸的动态',
                                        actionLabel: '去登录',
                                        onAction: _onBindBannerTap,
                                      )
                                    : (historyInitialLoadDone
                                        ? (needsDeviceBind
                                            ? AppEmptyStateGallery(
                                                animationPath: 'assets/images/ani_baby_welcome.json',
                                                title: '嗨，我是胖宝！',
                                                subtitle: '我想更好地陪伴宝宝成长',
                                                actionLabel: '立即绑定宝宝',
                                                onAction: _onBindBannerTap,
                                              )
                                            : Consumer(
                                                builder: (context, ref, _) {
                                                  final baby = ref.watch(settingsBabyProvider).asData?.value;
                                                  final name = baby?.nickname ?? '宝宝';
                                                  return AppEmptyStateGallery(
                                                    animationPath: 'assets/images/ani_baby_feeding_guide.json',
                                                    title: '还没有为 $name 记录哦',
                                                    subtitle: '试试点击下方按钮，开始记录第一笔吧',
                                                  );
                                                },
                                              ))
                                        : const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )))
                                : HomeHistoryTopFadeMask(
                                    child: HomeHistoryScroll(
                                      key: _historyScrollKey,
                                      itemsAsc: historyItems,
                                      eventCatalog: eventCatalogItems,
                                      flyingRecordId: _flyTargetRecordId,
                                      flyAnimationInProgress: _flyTargetRecordId != null,
                                      onRecordTap: _openHistory,
                                      onStopActiveTimer: _stopActiveTimer,
                                      stoppingRecordIds: _stoppingRecordIds,
                                      hasMore: homeHistory.hasMore,
                                      loadingMore: homeHistory.loadingMore,
                                      onRefresh: () => _history.refreshFromRemote(),
                                      onLoadMore: () => _history.loadMoreHistory(),
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
                    HomeHistoryWsStatusBanner(
                      visible: showWsBanner,
                      message: wsBannerMessage,
                      reconnecting: wsBannerReconnecting,
                      tapEnabled: wsBannerTapEnabled,
                      variant: wsBannerVariant,
                      onReconnect: () => unawaited(_reconnectHistoryWs()),
                    ),
                    _buildInputModuleTopShadow(context),
                    AnimatedContainer(
                      duration: _kInputPanelAnimationDuration,
                      curve: Curves.easeOutCubic,
                      height: _bottomInputPanelHeight,
                      child: _buildBottomInputPanel(context, catalogState),
                    ),
                  ],
                ),
                if (!blockHomeInputChrome)
                  Positioned.fill(
                    child: HomeInputModeDock(
                      bounds: dockBounds,
                      bottomInputPanelHeight: _bottomInputPanelHeight,
                      currentChannel: _inputChannel,
                      dockCycleChannels: _dockCycleChannels,
                      restrictToHorizontalEdges: kIsWeb,
                      onChannelSelected: (channel) => unawaited(_selectInputChannel(channel)),
                      onDraggingChanged: widget.onDockDraggingChanged,
                    ),
                  ),
                if (_flyTargetRecordId != null)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: HomeEventRecordFlyOverlay(
                      key: ValueKey<int>(_flySession),
                      event: _flyEvent,
                      recordId: _flyTargetRecordId!,
                      historyScrollKey: _historyScrollKey,
                      onComplete: () => _onFlyOverlayComplete(_flySession),
                    ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomInputPanel(BuildContext context, EventCatalogState catalogState) {
    final inputAlign = _inputChannel == HomeInputChannel.buttons
        ? Alignment.topCenter
        : Alignment.center;
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: inputAlign,
          child: _buildPrimaryHomeInput(context, catalogState),
        ),
        if (_inputChannel == HomeInputChannel.text)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: AiQuotaRemainingHint(
                feature: AiQuotaRemainingHintFeature.voiceAi,
                padding: EdgeInsets.only(bottom: 4),
              ),
            ),
          ),
        if (_inputChannel == HomeInputChannel.voice)
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
      ],
    );

    if (_inputChannel == HomeInputChannel.voice) {
      return stack;
    }

    if (_inputChannel == HomeInputChannel.buttons) {
      return stack;
    }

    if (!kIsWeb) {
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

  Widget _buildPrimaryHomeInput(BuildContext context, EventCatalogState catalogState) {
    switch (_inputChannel) {
      case HomeInputChannel.voice:
        return _buildVoiceOrb(context);
      case HomeInputChannel.text:
        assert(kIsWeb);
        return _buildTextInput(context);
      case HomeInputChannel.buttons:
        final showCatalogLoading = catalogState.isRefreshing ||
            (!catalogState.remoteLoadAttempted && catalogState.items.isEmpty);
        return HomeButtonEventGrid(
          catalog: catalogState.items,
          rootEvents: _buttonGridOrder,
          isLoading: showCatalogLoading,
          onEventTap: (e) => unawaited(_onEventGridTap(e)),
        );
    }
  }

  Widget _buildTextInput(BuildContext context) {
    final hint = kIsWeb ? '输入后按 Enter 或点发送' : '输入后点发送';
    return Padding(
      key: _webInputAnchorKey,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: UcgPageComposerChrome(
        controller: _webController,
        confirmLabel: '发送',
        onConfirm: _onTextSubmit,
        padding: EdgeInsets.zero,
        applyKeyboardInset: false,
        field: ManagedKeyboardTextField(
          controller: _webController,
          focusNode: _webFocusNode,
          hint: hint,
          scene: 'home.text',
          anchorKey: _webInputAnchorKey,
          textInputAction: TextInputAction.send,
          onConfirm: _onTextSubmit,
          onSubmitted: (_) => _onTextSubmit(),
          decoration: ucgComposerFieldDecoration(context, hint: hint),
        ),
      ),
    );
  }

  Widget _buildInputModuleTopShadow(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final isDark = tokens?.isDarkShell ?? Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 3,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: isDark ? 0.38 : 0.14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOrb(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cloudMode = _speechEngine == SpeechEngine.cloudAsr;
    final cloudDisconnected = cloudMode && !_voiceAsrReady && !_voiceAsrConnecting;
    final color = cloudDisconnected ? scheme.outline : scheme.primary;
    final orbFill = cloudDisconnected
        ? Color.alphaBlend(scheme.outline.withValues(alpha: 0.12), Theme.of(context).scaffoldBackgroundColor)
        : themePrimaryBlend(context, alpha: 0.14);
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

    final orbCore = AnimatedScale(
      scale: _listening ? 1.06 : 1,
      duration: const Duration(milliseconds: 160),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            key: _voiceOrbKey,
            width: _kVoiceOrbVisualSize,
            height: _kVoiceOrbVisualSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orbFill,
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
                      : 'AI 对话',
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
    );

    if (!_listening) {
      return _wrapVoiceOrbWithQuota(orbCore);
    }

    return ListenableBuilder(
      listenable: _voiceLevelNotifier,
      builder: (context, _) {
        final bars = HomeVoiceLevelBars(
          level: _voiceLevelNotifier.value,
          cancelled: _slideToCancel,
          maxBarHeight: 52,
        );
        return _wrapVoiceOrbWithQuota(
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              bars,
              const SizedBox(width: 12),
              orbCore,
              const SizedBox(width: 12),
              bars,
            ],
          ),
        );
      },
    );
  }

  Widget _wrapVoiceOrbWithQuota(Widget orb) {
    return SizedBox(
      height: _kVoiceInputPanelHeight,
      child: Column(
        children: [
          Expanded(child: Center(child: orb)),
          const AiQuotaRemainingHint(
            feature: AiQuotaRemainingHintFeature.voiceAi,
            padding: EdgeInsets.only(bottom: 8),
            glassStyle: true,
          ),
        ],
      ),
    );
  }
}
