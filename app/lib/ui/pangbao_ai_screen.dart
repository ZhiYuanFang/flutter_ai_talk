import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/ai_quota_codes.dart';
import '../api/ai_quota_errors.dart';
import '../api/clinic_ws_error.dart';
import '../api/app_debug_log.dart';
import '../asr/home_speech_factory.dart';
import '../asr/home_speech_recognizer.dart';
import '../config/companion_greeting_store.dart';
import '../config/companion_input_mode_store.dart';
import '../config/pangbao_ai_consent_store.dart';
import '../config/pangbao_clinic_session_store.dart';
import '../config/speech_engine.dart';
import '../config/speech_engine_store.dart';
import '../data/feed_repository.dart';
import '../home_widget/widget_tip_cache.dart';
import '../providers/clinic_ws_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/home_pager.dart';
import '../providers/session_provider.dart';
import '../providers/tip_provider.dart';
import '../providers/toast_bus.dart';
import '../providers/voice_asr_ws_provider.dart';
import '../session/session_controller.dart';
import '../theme/companion_soft_chat_colors.dart';
import '../ui/widgets/app_empty_state_gallery.dart';
import '../ui/widgets/app_glass_overlay.dart';
import '../ui/widgets/app_toast.dart';
import '../ui/widgets/clinic_answer_body.dart';
import '../ui/widgets/companion_soft_panel.dart';
import 'home_history_scroll_to_bottom_button.dart';
import 'home_history_ws_status_banner.dart';
import 'home_voice_message_strip.dart';
import 'startup_branding.dart';
import '../ui/widgets/keyboard_dismiss_scope.dart';
import '../voice/clinic_ws_client.dart';

/// 智能陪伴：文本问答 + 流式 thinking/answer + 非医疗弱提示；支持流式中断/改问。
///
/// [embeddedInHomePager] 为 true 时嵌入主页 PageView，使用壳级 Clinic WS，离开页不 dispose WS。
class PangbaoAiScreen extends ConsumerStatefulWidget {
  const PangbaoAiScreen({super.key, this.embeddedInHomePager = false});

  /// 是否嵌入 `/home` 三页壳（陪伴页）。
  final bool embeddedInHomePager;

  @override
  ConsumerState<PangbaoAiScreen> createState() => _PangbaoAiScreenState();
}

class _ChatItem {
  _ChatItem.user(this.question, {this.at})
      : isUser = true,
        isDivider = false,
        isTipSource = false,
        answer = null,
        thinking = null;

  _ChatItem.assistant({this.isTipSource = false, this.at})
      : isUser = false,
        isDivider = false,
        question = null,
        thinking = '',
        answer = '';

  /// 纯线截断分隔（无字）。
  _ChatItem.divider()
      : isUser = false,
        isDivider = true,
        isTipSource = false,
        question = null,
        thinking = null,
        answer = null,
        at = null;

  final bool isUser;
  final bool isDivider;
  final bool isTipSource;
  final String? question;
  String? thinking;
  String? answer;

  /// 本地展示用消息时间；无则不上时间小字
  DateTime? at;

  /// clinic answer_done 下发的回答 ID；非空且未反馈时可点赞/踩
  String? answerId;
  var thinkingExpanded = false;
  var isError = false;
  String? errorMessage;

  /// 用户反馈：null=未反馈，1=thumbs up，-1=thumbs down（提交后不可改）
  int? feedback;
  var feedbackSubmitting = false;
}

/// 同日 HH:mm；跨日 M月d日 HH:mm；跨年带 yyyy年。
String formatCompanionMessageTime(DateTime at, {DateTime? now}) {
  final local = at.toLocal();
  final n = (now ?? DateTime.now()).toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final tod = '$hh:$mm';
  if (local.year == n.year && local.month == n.month && local.day == n.day) {
    return tod;
  }
  if (local.year == n.year) {
    return '${local.month}月${local.day}日 $tod';
  }
  return '${local.year}年${local.month}月${local.day}日 $tod';
}

class _PangbaoAiScreenState extends ConsumerState<PangbaoAiScreen>
    with WidgetsBindingObserver {
  static const _followBottomThreshold = 48.0;

  /// 上滑取消阈值（logical px），对齐喂养出界取消量级
  static const _slideCancelDy = 72.0;

  final _items = <_ChatItem>[];
  final _input = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scroll = ScrollController();
  ClinicWsClient? _client;
  StreamSubscription<Map<String, dynamic>>? _frameSub;
  StreamSubscription<bool>? _clinicWsReadySub;
  StreamSubscription<HistoryWsPhase>? _clinicWsPhaseSub;
  var _consented = false;
  HistoryWsPhase _clinicWsPhase = HistoryWsPhase.disconnected;
  var _clinicWsManualReconnecting = false;

  /// 输入模式：Web 强制文字
  var _inputMode = CompanionInputMode.text;
  HomeSpeechRecognizer? _recognizer;
  SpeechEngine? _speechEngine;
  var _voiceReady = false;
  var _voiceAsrReady = false;
  var _voiceAsrConnecting = false;
  StreamSubscription<bool>? _voiceAsrReadySub;
  var _listening = false;
  var _slideToCancel = false;
  var _voiceHoldActive = false;
  var _voiceHoldSeq = 0;
  var _activeVoicePointer = false;
  String _partial = '';
  double? _holdStartGlobalY;
  var _gaveUpSnackbarShown = false;
  String? _activeTurnId;
  _ChatItem? _activeAssistant;
  var _followLatest = true;
  var _showScrollToBottomButton = false;
  var _autoScrolling = false;
  String? _sessionDeviceNo;

  /// 本轮提问原文（send 时固化，供 Stop 回填）
  String? _activeQuestionText;

  /// 仅用户点 Stop 后写入；匹配 turn_cancelled.cancelled 才回填
  _StopRestorePending? _pendingStopRestore;

  /// 助手长按「复制」悬浮层（C′b）；与 SelectionArea 解耦
  OverlayEntry? _assistantCopyOverlay;

  bool get _streaming => _activeTurnId != null && _activeAssistant != null;

  /// 进行中：助手已入列（含空等待、尚无 turnId）
  bool get _turnInProgress => _activeAssistant != null;

  bool _needsDeviceBind(AsyncValue<String?> dnAsync) {
    return dnAsync.maybeWhen(
      data: (dn) => dn == null || dn.isEmpty,
      orElse: () => false,
    );
  }

  Widget _buildEmptyGallery(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    if (!loggedIn) {
      return AppEmptyStateGallery(
        animationPath: 'assets/images/ani_baby_welcome.json',
        title: '尚未登录',
        subtitle: '登录并绑定宝宝后，就能和胖宝聊聊解闷啦',
        actionLabel: '去登录',
        onAction: () => unawaited(context.push('/login')),
      );
    }
    final dnAsync = ref.watch(deviceNoNotifierProvider);
    if (_needsDeviceBind(dnAsync)) {
      return AppEmptyStateGallery(
        animationPath: 'assets/images/ani_baby_welcome.json',
        title: '嗨，我是胖宝！',
        subtitle: '绑定宝宝信息后，我就能更好地陪伴你啦',
        actionLabel: '立即绑定宝宝',
        onAction: () => unawaited(context.push('/settings/bind-baby')),
      );
    }
    return const AppEmptyStateGallery(
      animationPath: 'assets/images/ani_baby_feeding_guide.json',
      title: '来找我聊聊吧',
      subtitle: '我会结合喂养记录陪你解闷；对话会保存在本地。',
      fallbackIcon: Icons.favorite_outline,
    );
  }

  Widget _buildConversationArea(BuildContext context) {
    if (_items.isEmpty) {
      return _buildEmptyGallery(context, ref);
    }
    // 方案 M：不在列表外包 SelectionArea（与 ListView 抢松手手势会清选区）
    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (n) {
            if (n.depth != 0 || _autoScrolling) return false;
            if (n.direction == ScrollDirection.reverse && _followLatest) {
              setState(() {
                _followLatest = false;
                _showScrollToBottomButton = _items.isNotEmpty;
              });
            }
            return false;
          },
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (context, i) => _buildItem(_items[i]),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: IgnorePointer(
            ignoring: !_showScrollToBottomButton,
            child: AnimatedOpacity(
              opacity: _showScrollToBottomButton ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: Center(
                child: HomeHistoryScrollToBottomButton(
                    onPressed: _onScrollToBottomTap),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _initConsentAndWs();
  }

  Future<void> _initConsentAndWs() async {
    _consented = await PangbaoAiConsentStore.load();
    if (!_consented && mounted) {
      final ok = await showGlassConfirmDialog(
            context,
            title: '使用智能陪伴前请知悉',
            message:
                '您的问题及喂养聚合摘要将发送至 AI 陪伴服务；回答过程可能展示 AI 思考过程。内容仅为陪伴参考，非医疗建议。',
            confirmLabel: '同意并继续',
          ) ??
          false;
      if (!ok) {
        // 嵌入主页时取消同意不 pop 路由；独立路由仍返回上一页
        if (mounted && !widget.embeddedInHomePager) context.pop();
        return;
      }
      await PangbaoAiConsentStore.saveAccepted();
      _consented = true;
    }
    if (!mounted) return;
    await _restoreInputMode();
    if (!mounted) return;
    _setupWs(desired: true);
    await _hydrateFromLocalCacheIfEmpty();
    if (!mounted) return;
    // 首次进入：与 signal 可能并发，tip/问候门闩幂等可安全重复调用
    await _onCompanionEntryActions();
    if (!mounted) return;
    // 无论是否注入 tip，进页都落到最新一条
    _scrollToLatestMessage();
  }

  /// 等布局后滚到列表底部（进页 / hydrate 用）
  void _scrollToLatestMessage() {
    if (_items.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom(animate: false, force: true);
      // 再等一帧：ListView 灌入后 maxScrollExtent 可能刚更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToBottom(animate: false, force: true);
      });
    });
  }

  /// 恢复陪伴输入模式；Web 始终文字。
  Future<void> _restoreInputMode() async {
    if (kIsWeb) {
      setState(() => _inputMode = CompanionInputMode.text);
      return;
    }
    final saved = await CompanionInputModeStore.load();
    if (!mounted || saved == null) return;
    setState(() => _inputMode = saved);
    if (saved == CompanionInputMode.voice) {
      unawaited(_prepareVoiceInput());
    }
  }

  Future<void> _setInputMode(CompanionInputMode mode) async {
    if (mode == _inputMode) return;
    if (kIsWeb && mode == CompanionInputMode.voice) return;
    if (mode == CompanionInputMode.voice) {
      final loggedIn = ref.read(sessionProvider).isLoggedIn;
      final dn = ref.read(deviceNoNotifierProvider).asData?.value;
      if (!loggedIn || dn == null || dn.isEmpty) {
        if (mounted) {
          showAppToast(
            !loggedIn ? '请先登录后再使用语音' : '请先绑定宝宝后再使用语音',
            tone: AppToastTone.error,
          );
        }
        return;
      }
    }
    if (mode != CompanionInputMode.voice && _listening) {
      await _onVoiceCancel();
    }
    setState(() => _inputMode = mode);
    unawaited(CompanionInputModeStore.save(mode));
    if (mode == CompanionInputMode.voice) {
      await _prepareVoiceInput();
      if (mounted) setState(() {});
    } else {
      _inputFocusNode.requestFocus();
    }
  }

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

  /// 与喂养同源 ASR：系统 STT / 云端 ASR。
  Future<bool> _prepareVoiceInput() async {
    if (kIsWeb) {
      if (mounted) {
        showAppToast('语音识别不可用，请改用文字输入', tone: AppToastTone.error);
      }
      return false;
    }
    try {
      final engine = await SpeechEngineStore.load();
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
        if (_speechEngine != SpeechEngine.cloudAsr || _voiceAsrReady)
          return true;
      }

      _recognizer ??= await createHomeSpeechRecognizer(ref);
      final ok = await _recognizer!.prepare();
      _voiceReady =
          ok && (_speechEngine != SpeechEngine.cloudAsr || _voiceAsrReady);
      if (!ok && mounted) {
        final failure = _recognizer!.lastPrepareFailure ??
            HomeSpeechPrepareFailure.engineError;
        showAppToast(failure.message(forWeb: false), tone: AppToastTone.error);
      } else if (!_voiceReady &&
          mounted &&
          _speechEngine == SpeechEngine.cloudAsr) {
        showAppToast('语音转写服务未连接，请稍后再试', tone: AppToastTone.error);
      }
      return _voiceReady;
    } catch (_) {
      if (mounted) {
        showAppToast('语音识别初始化失败，请改用文字输入', tone: AppToastTone.error);
      }
      return false;
    }
  }

  void _setPagerScrollBlocked(bool blocked) {
    if (!widget.embeddedInHomePager) return;
    ref.read(homePagerScrollBlockedProvider.notifier).state = blocked;
  }

  void _releaseVoiceHold() {
    _voiceHoldActive = false;
    _voiceHoldSeq++;
  }

  bool _isVoiceHoldCurrent(int seq) => _voiceHoldActive && seq == _voiceHoldSeq;

  /// 按住期间浮动转写文案；松手后随 listening/partial 清空而隐藏。
  String? get _companionVoiceStripText {
    if (!_listening) return null;
    final partial = _partial.trim();
    if (partial.isNotEmpty) return partial;
    return '聆听中…';
  }

  void _setupWs({required bool desired}) {
    // 统一使用壳级 Clinic WS Provider（深链 /pangbao 已重定向至主页陪伴层）
    _client = ref.read(clinicWsClientProvider);
    _frameSub ??= _client!.frames.listen(_onFrame);
    _bindClinicWsStatusSubscriptions();
    _client!.setConnectionDesired(desired);
  }

  /// 进入陪伴：注入首页 tip / 小组件 tip（若有）或当天首次发「我来啦」。
  Future<void> _onCompanionEntryActions() async {
    if (!_consented) return;
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (!loggedIn || dn == null || dn.isEmpty) return;

    final tip = ref.read(tipProvider);
    var injectedTip = false;
    if (tip.canInjectToCompanion) {
      final text = tip.injectText;
      setState(() {
        // 首页 tip 注入
        final assistant = _ChatItem.assistant(
          isTipSource: true,
          at: DateTime.now(),
        );
        assistant.answer = text;
        _items.add(assistant);
      });
      ref.read(tipProvider.notifier).markConsumedForCompanion();
      injectedTip = true;
      unawaited(_persistSessionStore());
      _scrollToBottom(force: true);
      AppDebugLog.pangbaoClinic('entry inject home tip len=${text.length}');
    }

    if (injectedTip) {
      // 首页 tip 优先：同次不注小组件 tip，不标记 widget injected
      await CompanionGreetingStore.markGreetedToday();
      return;
    }

    // B3：无首页 tip 时尝试注入当日未消费的小组件 tip
    final widgetText = await peekWidgetTipInjectText();
    if (widgetText != null && widgetText.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        final assistant = _ChatItem.assistant(
          isTipSource: true,
          at: DateTime.now(),
        );
        assistant.answer = widgetText;
        _items.add(assistant);
      });
      await markWidgetTipInjectedToday();
      unawaited(_persistSessionStore());
      _scrollToBottom(force: true);
      AppDebugLog.pangbaoClinic(
        'entry inject widget tip len=${widgetText.length}',
      );
      await CompanionGreetingStore.markGreetedToday();
      return;
    }
    AppDebugLog.pangbaoClinic(
      'entry skip widget tip injected=${await isWidgetTipInjectedToday()}',
    );

    final greeted = await CompanionGreetingStore.hasGreetedToday();
    if (greeted || !mounted) return;
    await CompanionGreetingStore.markGreetedToday();
    _input.text = '我来啦';
    await _send();
  }

  /// 右上角清理：玻璃确认后清空本地陪伴记录。
  Future<void> _confirmClearCompanionHistory() async {
    final ok = await showGlassConfirmDialog(
          context,
          title: '清理陪伴记录',
          message: '将清除本机保存的陪伴对话，且不可恢复。确定继续？',
          confirmLabel: '清理',
        ) ??
        false;
    if (!ok || !mounted) return;
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn != null && dn.isNotEmpty) {
      await PangbaoClinicSessionStore.clear(dn);
    }
    setState(() {
      _items.clear();
      _activeTurnId = null;
      _activeAssistant = null;
      _followLatest = true;
      _showScrollToBottomButton = false;
    });
    // 清记录后允许首页仍展示的 tip 再次注入；不清除 widget_tip_injected_day
    ref.read(tipProvider.notifier).resetCompanionConsumption();
    AppDebugLog.pangbaoClinic(
      'clear history keep widget injected=${await isWidgetTipInjectedToday()}',
    );
  }

  void _bindClinicWsStatusSubscriptions() {
    final client = _client;
    if (client == null) return;
    if (_clinicWsReadySub == null && _clinicWsPhaseSub == null) {
      _clinicWsPhase = client.clinicWsPhase;
    }
    _clinicWsReadySub ??= client.clinicWsReadyStream.listen((v) {
      if (!mounted || !v) return;
      setState(() => _gaveUpSnackbarShown = false);
    });
    _clinicWsPhaseSub ??= client.clinicWsPhaseStream.listen((phase) {
      if (!mounted) return;
      setState(() {
        _clinicWsPhase = phase;
        if (phase != HistoryWsPhase.gaveUp) {
          _gaveUpSnackbarShown = false;
        }
      });
      if (phase == HistoryWsPhase.gaveUp) {
        _maybeShowClinicGaveUpSnackbar();
      }
    });
  }

  void _maybeShowClinicGaveUpSnackbar() {
    if (_gaveUpSnackbarShown) return;
    if (ref.read(sessionProvider).isRefreshInFlight) return;
    _gaveUpSnackbarShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_clinicWsPhase != HistoryWsPhase.gaveUp) return;
      if (ref.read(sessionProvider).isRefreshInFlight) return;
      ref.showApiToastError(kHomeHistoryWsGaveUpMessage);
    });
  }

  Future<void> _reconnectClinicWsFromBanner() async {
    if (_clinicWsManualReconnecting) return;
    setState(() => _clinicWsManualReconnecting = true);
    try {
      if (_client == null) {
        _setupWs(desired: true);
      }
      await _client?.reconnect(resetStrike: true);
    } finally {
      if (mounted) setState(() => _clinicWsManualReconnecting = false);
    }
  }

  void _reconnectClinicWs({bool resetStrike = false}) {
    if (_client == null) {
      _setupWs(desired: true);
      return;
    }
    unawaited(_client!.reconnect(resetStrike: resetStrike));
  }

  Future<void> _hydrateFromLocalCacheIfEmpty() async {
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) return;
    _sessionDeviceNo ??= dn;
    if (_items.isNotEmpty) return;
    final snapshot = await PangbaoClinicSessionStore.loadSnapshot(dn);
    if (!mounted || snapshot.isEmpty || _items.isNotEmpty) return;
    final completedQ = snapshot.completed.map((t) => t.question.trim()).toSet();
    final failed = snapshot.failed
        .where((f) => !completedQ.contains(f.question.trim()))
        .toList();
    AppDebugLog.pangbaoClinic(
      'hydrate deviceNo=$dn completed=${snapshot.completed.length} failed=${failed.length}',
    );
    setState(() {
      _items.addAll(_itemsFromCachedTurns(snapshot.completed));
      _items.addAll(_itemsFromFailedTurns(failed));
      _followLatest = true;
    });
    // hydrate 后滚到最新（进页默认停在最新一条）
    _scrollToLatestMessage();
  }

  Future<void> _onDeviceNoChanged(String deviceNo) async {
    if (deviceNo.isEmpty) return;
    final prev = _sessionDeviceNo;
    if (prev == deviceNo) return;
    _sessionDeviceNo = deviceNo;
    if (prev == null) {
      await _hydrateFromLocalCacheIfEmpty();
      _reconnectClinicWs();
      return;
    }
    if (_activeAssistant != null) return;
    setState(() {
      _items.clear();
      _followLatest = true;
      _showScrollToBottomButton = false;
    });
    await _hydrateFromLocalCacheIfEmpty();
  }

  Future<void> _persistSessionStore() async {
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) return;
    await PangbaoClinicSessionStore.saveSnapshot(
      dn,
      PangbaoClinicSessionSnapshot(
        completed: _completedTurnsFromItems(),
        failed: _failedTurnsFromItems(),
      ),
    );
  }

  List<PangbaoClinicFailedTurn> _failedTurnsFromItems() {
    final completedQ = <String>{};
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isUser) continue;
      if (i + 1 >= _items.length || _items[i + 1].isUser) continue;
      final assistant = _items[i + 1];
      if (assistant.isError) continue;
      final q = _items[i].question?.trim() ?? '';
      if (q.isNotEmpty) completedQ.add(q);
    }

    final out = <PangbaoClinicFailedTurn>[];
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isUser) continue;
      if (i + 1 >= _items.length || _items[i + 1].isUser) continue;
      final question = _items[i].question?.trim() ?? '';
      final assistant = _items[i + 1];
      if (!assistant.isError) continue;
      final msg = assistant.errorMessage?.trim() ?? '';
      if (question.isEmpty || msg.isEmpty) continue;
      if (completedQ.contains(question)) continue;
      if (out.any((t) => t.question.trim() == question)) continue;
      final thinkingRaw = assistant.thinking?.trim();
      out.add(
        PangbaoClinicFailedTurn(
          question: question,
          errorMessage: msg,
          thinking: thinkingRaw != null && thinkingRaw.isNotEmpty
              ? thinkingRaw
              : null,
        ),
      );
    }
    return out;
  }

  List<PangbaoClinicTurn> _completedTurnsFromItems() {
    final out = <PangbaoClinicTurn>[];
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      // 截断横线
      if (item.isDivider) {
        out.add(PangbaoClinicTurn.divider());
        continue;
      }
      // tip 源助手气泡（无 user 问句）
      if (!item.isUser && item.isTipSource && !item.isError) {
        final answer = item.answer?.trim() ?? '';
        if (answer.isEmpty) continue;
        final thinkingRaw = item.thinking?.trim();
        out.add(
          PangbaoClinicTurn.tip(
            answer: answer,
            thinking: thinkingRaw != null && thinkingRaw.isNotEmpty
                ? thinkingRaw
                : null,
            at: item.at,
          ),
        );
        continue;
      }
      if (!item.isUser) continue;
      if (i + 1 >= _items.length ||
          _items[i + 1].isUser ||
          _items[i + 1].isDivider) {
        continue;
      }
      final assistant = _items[i + 1];
      if (assistant.isError || assistant.isTipSource) continue;
      final question = item.question?.trim() ?? '';
      final answer = assistant.answer?.trim() ?? '';
      if (question.isEmpty || answer.isEmpty) continue;
      final thinkingRaw = assistant.thinking?.trim();
      // QA 存提问时刻（优先用户气泡 at）
      out.add(
        PangbaoClinicTurn(
          question: question,
          answer: answer,
          thinking: thinkingRaw != null && thinkingRaw.isNotEmpty
              ? thinkingRaw
              : null,
          at: item.at ?? assistant.at,
        ),
      );
    }
    return out;
  }

  void _applyInlineErrorToActiveAssistant(ParsedClinicWsError parsed) {
    if (_activeAssistant == null) return;
    _activeAssistant!.isError = true;
    _activeAssistant!.errorMessage = parsed.userMessage;
    _activeAssistant!.answer = '';
    _activeTurnId = null;
    _activeAssistant = null;
  }

  String _debugClinicErrorMsg(String message) {
    if (message.length <= 48) return message;
    return '${message.substring(0, 45)}...';
  }

  void _onFrame(Map<String, dynamic> frame) {
    final type = (frame['type'] as String? ?? '').toLowerCase();
    if (type == 'error') {
      final parsed = parseClinicWsUserMessage(frame);
      AppDebugLog.pangbaoClinic(
        'ws error kind=${parsed.kind.name} code=${parsed.businessCode} msg=${_debugClinicErrorMsg(parsed.userMessage)}',
      );
      // 客户端先行去额度：仅 40301 走登录引导，40302 不再弹额度框
      if (parsed.businessCode == kAiCodeNotLoggedIn && mounted) {
        unawaited(handleAiQuotaBusinessCode(context, parsed.businessCode!));
      }
      setState(() {
        _applyInlineErrorToActiveAssistant(parsed);
      });
      unawaited(_persistSessionStore());
      _scrollToBottom();
      return;
    }
    if (type == 'session_sync') {
      // 展示仅为前端：忽略服务端 turns，不改本地/_items
      final raw = frame['turns'];
      final n = raw is List ? raw.length : 0;
      AppDebugLog.pangbaoClinic(
          'session_sync ignored turns=$n items=${_items.length}');
      return;
    }
    if (type == 'turn_cancelled') {
      final turnId = frame['turnId'] as String? ?? '';
      final reason = frame['reason'] as String? ?? '';
      if (turnId.isEmpty) return;
      final pending = _pendingStopRestore;
      // 仅用户 Stop 武装的 pending + cancelled 才回填
      final shouldRestore = reason == 'cancelled' &&
          pending != null &&
          pending.turnId == turnId;
      if (shouldRestore) {
        final restoreText = pending.text;
        setState(() {
          _removeActiveTurnUserAndAssistant();
          _pendingStopRestore = null;
          _activeQuestionText = null;
          _input.text = restoreText;
          _input.selection =
              TextSelection.collapsed(offset: restoreText.length);
        });
        if (_inputMode != CompanionInputMode.text) {
          unawaited(_setInputMode(CompanionInputMode.text));
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _inputFocusNode.requestFocus();
          });
        }
        if (mounted) showAppToast('已停止');
        return;
      }
      setState(() {
        if (turnId == _activeTurnId) {
          _clearActiveStreaming(removeAssistant: true);
        } else {
          _removePartialAssistantForTurn(turnId);
        }
        // 过期 pending：迟到 cancelled/superseded 勿再恢复
        if (pending != null && pending.turnId == turnId) {
          _pendingStopRestore = null;
        }
        if (reason == 'superseded') {
          _pendingStopRestore = null;
        }
      });
      // 统一居中 toast（与「已复制」同路径）
      if (reason == 'cancelled' && mounted) showAppToast('已停止');
      return;
    }
    if (_activeAssistant == null || _activeTurnId == null) return;
    final frameTurnId = frame['turnId'] as String? ?? '';
    if (frameTurnId.isNotEmpty && frameTurnId != _activeTurnId) return;
    setState(() {
      switch (type) {
        case 'thinking_delta':
          _activeAssistant!.thinking = (_activeAssistant!.thinking ?? '') +
              (frame['delta'] as String? ?? '');
          break;
        case 'answer_delta':
          if ((_activeAssistant!.answer ?? '').isEmpty) {
            _activeAssistant!.thinkingExpanded = false;
          }
          _activeAssistant!.answer = (_activeAssistant!.answer ?? '') +
              (frame['delta'] as String? ?? '');
          break;
        case 'answer_done':
          _activeAssistant!.thinkingExpanded = false;
          _activeAssistant!.thinking =
              frame['thinking'] as String? ?? _activeAssistant!.thinking;
          _activeAssistant!.answer =
              frame['answer'] as String? ?? _activeAssistant!.answer;
          _activeAssistant!.answerId = frame['answerId'] as String? ?? '';
          _activeTurnId = null;
          _activeAssistant = null;
          unawaited(_persistSessionStore());
          break;
      }
    });
    _scrollToBottom();
  }

  void _clearActiveStreaming({required bool removeAssistant}) {
    if (removeAssistant && _activeAssistant != null) {
      final idx = _items.indexOf(_activeAssistant!);
      if (idx >= 0) _items.removeAt(idx);
    }
    _activeTurnId = null;
    _activeAssistant = null;
    _activeQuestionText = null;
  }

  /// Stop 恢复：删本轮用户气泡 + 助手气泡，清空 active
  void _removeActiveTurnUserAndAssistant() {
    if (_activeAssistant != null) {
      final aIdx = _items.indexOf(_activeAssistant!);
      if (aIdx > 0 && _items[aIdx - 1].isUser) {
        _items.removeAt(aIdx - 1);
      }
      final idx = _items.indexOf(_activeAssistant!);
      if (idx >= 0) _items.removeAt(idx);
    }
    _activeTurnId = null;
    _activeAssistant = null;
  }

  /// 从 active 助手前一条用户气泡取问题原文
  String? _questionTextBesideActiveAssistant() {
    if (_activeAssistant == null) return null;
    final idx = _items.indexOf(_activeAssistant!);
    if (idx <= 0) return null;
    final prev = _items[idx - 1];
    if (!prev.isUser) return null;
    final q = (prev.question ?? '').trim();
    return q.isEmpty ? null : q;
  }

  void _removePartialAssistantForTurn(String turnId) {
    if (turnId != _activeTurnId && _activeAssistant != null) {
      final idx = _items.indexOf(_activeAssistant!);
      if (idx >= 0 &&
          (_activeAssistant!.answer ?? '').isEmpty &&
          (_activeAssistant!.thinking ?? '').isNotEmpty) {
        _items.removeAt(idx);
      }
    }
  }

  List<_ChatItem> _itemsFromFailedTurns(List<PangbaoClinicFailedTurn> turns) {
    final out = <_ChatItem>[];
    for (final turn in turns) {
      out.add(_ChatItem.user(turn.question));
      final assistant = _ChatItem.assistant();
      assistant.thinking = turn.thinking;
      assistant.isError = true;
      assistant.errorMessage = turn.errorMessage;
      out.add(assistant);
    }
    return out;
  }

  List<_ChatItem> _itemsFromCachedTurns(List<PangbaoClinicTurn> turns) {
    final out = <_ChatItem>[];
    for (final turn in turns) {
      if (turn.kind == PangbaoClinicEntryKind.divider) {
        out.add(_ChatItem.divider());
        continue;
      }
      if (turn.kind == PangbaoClinicEntryKind.tip) {
        final assistant = _ChatItem.assistant(
          isTipSource: true,
          at: turn.at,
        );
        assistant.thinking = turn.thinking;
        assistant.answer = turn.answer;
        out.add(assistant);
        continue;
      }
      // hydrate：用户与助手共用 turn.at
      out.add(_ChatItem.user(turn.question, at: turn.at));
      final assistant = _ChatItem.assistant(at: turn.at);
      assistant.thinking = turn.thinking;
      assistant.answer = turn.answer;
      out.add(assistant);
    }
    return out;
  }

  void _onScroll() {
    // 列表滚动时关掉复制气泡，避免悬空
    _dismissAssistantCopyOverlay();
    if (_autoScrolling || !_scroll.hasClients) return;
    final pos = _scroll.position;
    if (!pos.maxScrollExtent.isFinite) return;
    final nearBottom =
        pos.maxScrollExtent - pos.pixels <= _followBottomThreshold;
    if (_followLatest == nearBottom) return;
    setState(() {
      _followLatest = nearBottom;
      _showScrollToBottomButton = !nearBottom && _items.isNotEmpty;
    });
  }

  /// 关闭助手「复制」Overlay
  void _dismissAssistantCopyOverlay() {
    _assistantCopyOverlay?.remove();
    _assistantCopyOverlay = null;
  }

  /// 在气泡卡片上方居中弹出「复制」；默认复制整段 answer
  void _showAssistantCopyOverlay({
    required BuildContext bubbleContext,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !mounted) return;
    // 用气泡 RenderBox 顶边居中，不跟手指
    final box = bubbleContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;

    _dismissAssistantCopyOverlay();
    final media = MediaQuery.sizeOf(context);
    final padTop = MediaQuery.paddingOf(context).top;
    const btnW = 72.0;
    const btnH = 36.0;
    var left = origin.dx + size.width / 2 - btnW / 2;
    var top = origin.dy - btnH - 8;
    left = left.clamp(8.0, media.width - btnW - 8);
    top = top.clamp(padTop + 8, media.height - btnH - 8);

    _assistantCopyOverlay = OverlayEntry(
      builder: (ctx) {
        final scheme = Theme.of(context).colorScheme;
        return Stack(
          children: [
            // 点空白关闭
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissAssistantCopyOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: scheme.surfaceContainerHigh,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: trimmed));
                    _dismissAssistantCopyOverlay();
                    if (mounted) showAppToast('已复制');
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '复制',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_assistantCopyOverlay!);
  }

  void _scrollToBottom({bool animate = true, bool force = false}) {
    if (!force && !_followLatest) return;

    final useJump = force || _streaming || !animate;

    void tryScroll() {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      final target = pos.maxScrollExtent;
      if (!target.isFinite) return;

      _autoScrolling = true;
      if ((pos.pixels - target).abs() <= 1) {
        _autoScrolling = false;
        if (force) {
          if (_followLatest != true || _showScrollToBottomButton) {
            setState(() {
              _followLatest = true;
              _showScrollToBottomButton = false;
            });
          } else {
            _followLatest = true;
            _showScrollToBottomButton = false;
          }
        }
        return;
      }

      if (useJump) {
        _scroll.jumpTo(target);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _autoScrolling = false;
        });
      } else {
        _scroll
            .animateTo(
              target,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
            )
            .whenComplete(() => _autoScrolling = false);
      }

      if (force) {
        _followLatest = true;
        _showScrollToBottomButton = false;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryScroll();
      WidgetsBinding.instance.addPostFrameCallback((_) => tryScroll());
    });
  }

  void _onScrollToBottomTap() {
    setState(() {
      _followLatest = true;
      _showScrollToBottomButton = false;
    });
    _scrollToBottom(animate: true, force: true);
  }

  Future<void> _send({String? overrideText}) async {
    if (!_consented) return;
    final text = (overrideText ?? _input.text).trim();
    if (text.isEmpty) return;
    if (overrideText == null) {
      _input.clear();
    }
    // 新发送清除旧 stop-restore，防迟到 cancelled 误回填
    _pendingStopRestore = null;
    setState(() {
      if (_activeAssistant != null) {
        final idx = _items.indexOf(_activeAssistant!);
        if (idx >= 0) _items.removeAt(idx);
      }
      final now = DateTime.now();
      _items.add(_ChatItem.user(text, at: now));
      _activeAssistant = _ChatItem.assistant(at: now);
      _items.add(_activeAssistant!);
      _activeQuestionText = text;
      _followLatest = true;
      _showScrollToBottomButton = false;
    });
    _scrollToBottom(force: true);
    final turnId = await _client?.sendQuestion(text);
    if (turnId != null) {
      setState(() {
        _activeTurnId = turnId;
        // 固化本轮问题，供 Stop 武装 pending
        _activeQuestionText = text;
      });
    }
  }

  Future<void> _onVoicePointerDown() async {
    final seq = ++_voiceHoldSeq;
    _voiceHoldActive = true;
    _setPagerScrollBlocked(true);

    if (!_consented) {
      _releaseVoiceHold();
      _setPagerScrollBlocked(false);
      return;
    }
    if (!ref.read(sessionProvider).isLoggedIn) {
      _releaseVoiceHold();
      _setPagerScrollBlocked(false);
      if (mounted) {
        final go = await showGlassConfirmDialog(
              context,
              title: '需要登录',
              message: '请先登录后再使用语音。',
              confirmLabel: '去登录',
            ) ??
            false;
        if (go && mounted) await context.push('/login');
      }
      return;
    }
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) {
      _releaseVoiceHold();
      _setPagerScrollBlocked(false);
      if (mounted) {
        final go = await showGlassConfirmDialog(
              context,
              title: '绑定宝宝',
              message: '请先绑定宝宝信息后再使用语音。',
              confirmLabel: '去绑定',
            ) ??
            false;
        if (go && mounted) await context.push('/settings/bind-baby');
      }
      return;
    }
    if (!_isVoiceHoldCurrent(seq) || !mounted) return;
    if (!await _prepareVoiceInput()) {
      _releaseVoiceHold();
      _setPagerScrollBlocked(false);
      return;
    }
    if (!_isVoiceHoldCurrent(seq) || !mounted || _recognizer == null) return;

    setState(() {
      _listening = true;
      _partial = '';
      _slideToCancel = false;
    });
    await _recognizer!.startSession(
      (partial) {
        if (!mounted || !_isVoiceHoldCurrent(seq)) return;
        setState(() => _partial = partial);
      },
    );
    if (!_isVoiceHoldCurrent(seq) && mounted && _listening) {
      await _recognizer?.cancelSession();
      if (!mounted) return;
      setState(() {
        _listening = false;
        _partial = '';
      });
      _setPagerScrollBlocked(false);
    }
  }

  void _onHoldPointerDown(PointerDownEvent event) {
    if (_inputMode != CompanionInputMode.voice || kIsWeb) return;
    // 进行中禁止开始语音采集
    if (_turnInProgress) return;
    _activeVoicePointer = true;
    _holdStartGlobalY = event.position.dy;
    setState(() => _slideToCancel = false);
    unawaited(_onVoicePointerDown());
  }

  void _onHoldPointerMove(PointerMoveEvent event) {
    if (!_activeVoicePointer || _holdStartGlobalY == null) return;
    // 上滑超过阈值 → 取消态（与喂养出界取消同量级）
    final cancel = (_holdStartGlobalY! - event.position.dy) >= _slideCancelDy;
    if (_slideToCancel != cancel) {
      setState(() => _slideToCancel = cancel);
    }
  }

  void _onHoldPointerUp(PointerUpEvent event) {
    if (!_activeVoicePointer) return;
    _activeVoicePointer = false;
    _holdStartGlobalY = null;
    final cancel = _slideToCancel;
    _releaseVoiceHold();
    setState(() => _slideToCancel = false);
    if (cancel) {
      unawaited(_onVoiceCancel(skipReleaseHold: true));
    } else {
      unawaited(_onVoiceEnd());
    }
  }

  void _onHoldPointerCancel(PointerCancelEvent event) {
    if (!_activeVoicePointer) return;
    _activeVoicePointer = false;
    _holdStartGlobalY = null;
    setState(() => _slideToCancel = false);
    unawaited(_onVoiceCancel());
  }

  Future<void> _onVoiceEnd() async {
    // 门闩/prepare 中途松手：未真正开录，不发送
    if (!_listening) {
      if (_recognizer != null) {
        await _recognizer!.cancelSession();
      }
      if (mounted) {
        setState(() => _partial = '');
      }
      _setPagerScrollBlocked(false);
      return;
    }
    if (_recognizer == null) {
      _setPagerScrollBlocked(false);
      return;
    }
    final fromEngine = await _recognizer!.endSession();
    final text = (fromEngine.isNotEmpty ? fromEngine : _partial).trim();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _partial = '';
    });
    _setPagerScrollBlocked(false);
    // 进行中禁语音新发（避免 supersede 旁路）
    if (_turnInProgress) return;
    if (text.isEmpty) return;
    await _send(overrideText: text);
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
    _setPagerScrollBlocked(false);
  }

  Future<void> _stopStreaming() async {
    final turnId = _activeTurnId ?? _client?.activeTurnId;
    if (turnId == null || turnId.isEmpty) return;
    // Stop 前武装 pending：仅此路径触发回填
    final text = (_activeQuestionText?.trim().isNotEmpty == true
            ? _activeQuestionText!.trim()
            : _questionTextBesideActiveAssistant()) ??
        '';
    if (text.isNotEmpty) {
      _pendingStopRestore =
          _StopRestorePending(turnId: turnId, text: text);
    } else {
      // 无本地文案仍 cancel，但不得伪造回填（不写 pending）
      _pendingStopRestore = null;
    }
    await _client?.sendCancel(turnId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _client?.setConnectionDesired(false);
    } else if (state == AppLifecycleState.resumed && _consented) {
      _client?.onAppLifecycleResumed();
      _client?.setConnectionDesired(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dismissAssistantCopyOverlay();
    _scroll.removeListener(_onScroll);
    _frameSub?.cancel();
    _clinicWsReadySub?.cancel();
    _clinicWsPhaseSub?.cancel();
    _voiceAsrReadySub?.cancel();
    _recognizer?.dispose();
    _setPagerScrollBlocked(false);
    // Clinic WS 由壳级 provider 持有，页面不得 dispose
    _input.dispose();
    _inputFocusNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn),
        (prev, loggedIn) {
      if (loggedIn && _consented) {
        _setupWs(desired: true);
      }
    });
    ref.listen<String?>(sessionProvider.select((s) => s.accessToken),
        (prev, next) {
      if (!SessionController.isAccessTokenRotation(prev, next)) return;
      if (_consented && ref.read(sessionProvider).isLoggedIn) {
        _reconnectClinicWs();
      }
    });
    ref.listen<bool>(sessionProvider.select((s) => s.isRefreshInFlight),
        (prev, inFlight) {
      if (prev != true || inFlight || !_consented) return;
      if (!ref.read(sessionProvider).isLoggedIn) return;
      _reconnectClinicWs();
    });
    ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
      final dn = next.asData?.value;
      if (dn == null || dn.isEmpty) return;
      unawaited(_onDeviceNoChanged(dn));
    });
    // KeepAlive 再次进入陪伴页：tip 注入 /「我来啦」+ 滚到最新
    ref.listen<int>(companionEnterSignalProvider, (prev, next) {
      if (prev == null || next <= prev) return;
      unawaited(() async {
        await _onCompanionEntryActions();
        if (mounted) _scrollToLatestMessage();
      }());
    });

    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final dnAsync = ref.watch(deviceNoNotifierProvider);
    final canUseInput = _consented && loggedIn && !_needsDeviceBind(dnAsync);
    // 进行中可编辑，但禁 Send / 语音新发
    final canSend = canUseInput && !_turnInProgress;
    final canVoiceHold = canUseInput && !_turnInProgress;
    final needsDeviceBind = loggedIn && _needsDeviceBind(dnAsync);
    final refreshInFlight =
        ref.watch(sessionProvider.select((s) => s.isRefreshInFlight));
    // 与主页对齐：仅 gaveUp 时展示连接失败横幅。
    final showWsBanner = _consented &&
        loggedIn &&
        !needsDeviceBind &&
        _clinicWsPhase == HistoryWsPhase.gaveUp &&
        !refreshInFlight;
    final inputHint = !_consented
        ? '请先同意告知'
        : !loggedIn
            ? '请先登录'
            : _needsDeviceBind(dnAsync)
                ? '请先绑定宝宝'
                : '跟胖宝说点什么…';
    final scheme = Theme.of(context).colorScheme;
    // 柔和拟态软聊页底（随主题 seed）
    final soft = CompanionSoftChatColors.of(context);

    return Scaffold(
      backgroundColor: soft.pageBg,
      appBar: AppBar(
        // 居中圆形品牌标，无「胖宝树洞」文案；无障碍仍保留语义
        title: Semantics(
          label: '胖宝树洞',
          child: const StartupBrandingIcon(size: 36),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: widget.embeddedInHomePager
        //     ? IconButton(
        //         icon: const Icon(Icons.chevron_right),
        //         tooltip: '返回喂养',
        //         onPressed: () =>
        //             ref.read(homePagerRequestProvider.notifier).requestPage(HomePagerPage.feeding),
        //       )
        //     : null,
        actions: [
          IconButton(
            // 随主题色变色
            icon: Icon(Icons.cached, color: scheme.primary),
            tooltip: '清理陪伴记录',
            onPressed: () => unawaited(_confirmClearCompanionHistory()),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: scheme.primary),
            tooltip: '返回喂养',
            onPressed: () => ref
                .read(homePagerRequestProvider.notifier)
                .requestPage(HomePagerPage.feeding),
          ),
        ],
      ),
      body: Column(
        children: [
          HomeHistoryWsStatusBanner(
            visible: showWsBanner,
            message: kHomeHistoryWsGaveUpMessage,
            reconnecting: _clinicWsManualReconnecting,
            tapEnabled: true,
            variant: HomeHistoryWsBannerVariant.error,
            onReconnect: () => unawaited(_reconnectClinicWsFromBanner()),
          ),
          Expanded(
            child: _buildConversationArea(context),
          ),
          if (_companionVoiceStripText != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: HomeVoiceMessageStrip(text: _companionVoiceStripText!),
            ),
            // Padding(
            //   padding: const EdgeInsets.only(bottom: 4),
            //   child: Text(
            //     _slideToCancel ? '松开取消' : '松开发送',
            //     textAlign: TextAlign.center,
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: _slideToCancel
            //           ? scheme.error
            //           : scheme.onSurface.withValues(alpha: 0.55),
            //     ),
            //   ),
            // ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, 12 + MediaQuery.paddingOf(context).bottom),
            // 柔和拟态输入区：主题 tint + 极轻阴影（方案 B，去白卡片外框感）
            child: CompanionSoftPanel(
              fill: soft.inputBar,
              shadows: soft.inputShadows,
              contentPadding: const EdgeInsets.fromLTRB(0,0,0,0),
              borderRadius: 24,
              // 语音：Stack 通栏底色+居中文案，切换钮叠左（不挤压背景）
              // 文字：Row 切换 + 输入框 + 发送R
              child: _inputMode == CompanionInputMode.voice && !kIsWeb
                  ? SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown:
                                  canVoiceHold ? _onHoldPointerDown : null,
                              onPointerMove:
                                  canVoiceHold ? _onHoldPointerMove : null,
                              onPointerUp:
                                  canVoiceHold ? _onHoldPointerUp : null,
                              onPointerCancel:
                                  canVoiceHold ? _onHoldPointerCancel : null,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _listening
                                      ? (_slideToCancel
                                          ? scheme.errorContainer
                                              .withValues(alpha: 0.55)
                                          : scheme.primaryContainer
                                              .withValues(alpha: 0.45))
                                      : soft.userBubble.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  !canUseInput
                                      ? inputHint
                                      : (_turnInProgress
                                          ? '回答中，请先停止'
                                          : (_listening
                                              ? (_slideToCancel
                                                  ? '松开取消'
                                                  : '松开发送')
                                              : '按住 说话')),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _listening && _slideToCancel
                                        ? scheme.error
                                        : soft.onBubble.withValues(
                                            alpha: canVoiceHold ? 0.85 : 0.45,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 叠在左侧：优先吃掉点击，避免与按住冲突
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: '切换到文字',
                              onPressed: !_consented
                                  ? null
                                  : () => unawaited(
                                        _setInputMode(CompanionInputMode.text),
                                      ),
                              icon: const Icon(Icons.keyboard_alt_outlined),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        if (!kIsWeb)
                          IconButton(
                            tooltip: '切换到按住说话',
                            onPressed: !_consented
                                ? null
                                : () => unawaited(
                                      _setInputMode(CompanionInputMode.voice),
                                    ),
                            icon: const Icon(Icons.mic_none_rounded),
                          ),
                        Expanded(
                          child: KeyboardDismissExclude(
                            child: TextField(
                              controller: _input,
                              focusNode: _inputFocusNode,
                              // 进行中仍可编辑草稿；Send 另禁
                              enabled: canUseInput,
                              textInputAction: TextInputAction.send,
                              onSubmitted: canSend
                                  ? (_) => unawaited(_send())
                                  : null,
                              style: TextStyle(color: soft.onBubble),
                              decoration: InputDecoration(
                                hintText: inputHint,
                                hintStyle: TextStyle(
                                  color: soft.onBubble.withValues(alpha: 0.45),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 输入栏始终 Send；进行中灰色禁用（Stop 在助手壳）
                        IconButton.filled(
                          onPressed:
                              canSend ? () => unawaited(_send()) : null,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageTimeLabel(DateTime? at) {
    if (at == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        formatCompanionMessageTime(at),
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildItem(_ChatItem item) {
    // 本地遗留截断线：纯线无字（无时间）
    if (item.isDivider) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.55),
        ),
      );
    }
    if (item.isUser) {
      // SelectableText 自管选区；柔和拟态用户气泡
      final q = item.question ?? '';
      final soft = CompanionSoftChatColors.of(context);
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _messageTimeLabel(item.at),
              CompanionSoftPanel(
                fill: soft.userBubble,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                borderRadius: 18,
                child: SelectableText(
                  q,
                  style: TextStyle(color: soft.onBubble, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final soft = CompanionSoftChatColors.of(context);
    final isActive = identical(item, _activeAssistant);
    final answerEmpty = (item.answer ?? '').trim().isEmpty;
    // 进行中：空等待也画思考壳；历史仅非空 thinking 且无 answer
    final showThinkingShell = !item.isError &&
        answerEmpty &&
        (isActive || (item.thinking ?? '').isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _messageTimeLabel(item.at),
        if (showThinkingShell)
          _ThinkingBlock(
            item: item,
            streaming: isActive,
            showStop: isActive,
            onStop: () => unawaited(_stopStreaming()),
            onTap: () =>
                setState(() => item.thinkingExpanded = !item.thinkingExpanded),
          ),
        if (item.isError && (item.errorMessage ?? '').isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if ((item.answer ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            // 长按复制：按气泡顶边居中；柔和拟态助手气泡（无头像）
            child: Builder(
              builder: (bubbleContext) {
                return GestureDetector(
                  onLongPressStart: isActive
                      ? null
                      : (_) {
                          _showAssistantCopyOverlay(
                            bubbleContext: bubbleContext,
                            text: item.answer ?? '',
                          );
                        },
                  child: CompanionSoftPanel(
                    fill: soft.assistantBubble,
                    contentPadding: const EdgeInsets.all(14),
                    borderRadius: 18,
                    // Stop 进布局流：正文下方右对齐，不叠挡、无固定底洞
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClinicAnswerBody(
                          text: item.answer ?? '',
                          streaming: isActive && _streaming,
                          selectable: false,
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _BubbleStopButton(
                              onPressed: () => unawaited(_stopStreaming()),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (!item.isError && (item.answer ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '非医疗建议',
              style: TextStyle(
                fontSize: 8,
                color: soft.onBubble.withValues(alpha: 0.45),
              ),
            ),
          ),
      ],
    );
  }
}

class _StopRestorePending {
  const _StopRestorePending({required this.turnId, required this.text});

  final String turnId;
  final String text;
}

/// 气泡右下角停止按钮
class _BubbleStopButton extends StatelessWidget {
  const _BubbleStopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: const Icon(Icons.stop, size: 20),
      tooltip: '停止',
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ThinkingBlock extends StatelessWidget {
  const _ThinkingBlock({
    required this.item,
    required this.onTap,
    this.streaming = false,
    this.showStop = false,
    this.onStop,
  });

  final _ChatItem item;
  final VoidCallback onTap;
  final bool streaming;
  final bool showStop;
  final VoidCallback? onStop;

  static const _lineHeight = 18.0;
  static const _maxLines = 5;

  static double get _foldHeight => _lineHeight * _maxLines;

  TextStyle _bodyStyle(ColorScheme scheme) {
    return TextStyle(
      fontSize: 12,
      height: _lineHeight / 12,
      color: scheme.onSurface.withValues(alpha: 0.65),
    );
  }

  bool _hasVisualOverflow(String text, double maxWidth, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.size.height > _foldHeight + 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final raw = item.thinking ?? '';
    // 空等待：仅标题；有内容时流式加光标
    final displayText = streaming
        ? (raw.isEmpty ? '' : '$raw▍')
        : raw;
    final folded = !streaming && !item.thinkingExpanded;
    final scheme = Theme.of(context).colorScheme;
    final style = _bodyStyle(scheme);

    return GestureDetector(
      onTap: folded || !streaming ? onTap : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textWidth = constraints.maxWidth;
            final overflow = folded &&
                displayText.isNotEmpty &&
                _hasVisualOverflow(displayText, textWidth, style);

            Widget body;
            if (streaming) {
              body = displayText.isEmpty
                  ? const SizedBox(height: 4)
                  : Text(displayText, style: style);
            } else if (folded) {
              body = SizedBox(
                height: _foldHeight,
                width: double.infinity,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(displayText, style: style),
                  ),
                ),
              );
              if (overflow) {
                body = Stack(
                  children: [
                    body,
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 20,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scheme.surface.withValues(alpha: 0.95),
                                scheme.surface.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            } else {
              body = SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Text(displayText, style: style),
              );
            }

            // Stop 在正文下方右对齐（布局流），不挡字
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  streaming ? '思考中…' : '思考过程',
                  style: TextStyle(fontSize: 11, color: scheme.primary),
                ),
                const SizedBox(height: 4),
                body,
                if (overflow)
                  Text('点击展开',
                      style:
                          TextStyle(fontSize: 10, color: scheme.primary)),
                if (showStop && onStop != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _BubbleStopButton(onPressed: onStop!),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
