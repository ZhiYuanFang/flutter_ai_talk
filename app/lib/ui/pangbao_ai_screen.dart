import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/ai_quota_codes.dart';
import '../api/ai_quota_errors.dart';
import '../api/clinic_ws_error.dart';
import '../api/app_debug_log.dart';
import '../config/env.dart';
import '../config/pangbao_ai_consent_store.dart';
import '../config/pangbao_clinic_session_store.dart';
import '../data/feed_repository.dart';
import '../providers/ai_quota_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
import '../session/session_controller.dart';
import '../ui/widgets/app_empty_state_gallery.dart';
import '../ui/widgets/app_glass_overlay.dart';
import '../ui/widgets/clinic_answer_body.dart';
import 'home_history_scroll_to_bottom_button.dart';
import 'home_history_ws_status_banner.dart';
import '../ui/widgets/keyboard_dismiss_scope.dart';
import '../ucg/ui/widgets/ucg_visual_widgets.dart';
import '../voice/clinic_ws_client.dart';

/// 胖宝诊疗：文本问答 + 流式 thinking/answer + 免责声明；支持流式中断/改问。
class PangbaoAiScreen extends ConsumerStatefulWidget {
  const PangbaoAiScreen({super.key});

  @override
  ConsumerState<PangbaoAiScreen> createState() => _PangbaoAiScreenState();
}

class _ChatItem {
  _ChatItem.user(this.question)
      : isUser = true,
        answer = null,
        thinking = null;

  _ChatItem.assistant()
      : isUser = false,
        question = null,
        thinking = '',
        answer = '';

  final bool isUser;
  final String? question;
  String? thinking;
  String? answer;
  var thinkingExpanded = false;
  var isError = false;
  String? errorMessage;
}

class _PangbaoAiScreenState extends ConsumerState<PangbaoAiScreen> with WidgetsBindingObserver {
  static const _followBottomThreshold = 48.0;

  final _items = <_ChatItem>[];
  final _input = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scroll = ScrollController();
  ClinicWsClient? _client;
  StreamSubscription<Map<String, dynamic>>? _frameSub;
  StreamSubscription<bool>? _clinicWsReadySub;
  StreamSubscription<HistoryWsPhase>? _clinicWsPhaseSub;
  var _consented = false;
  var _clinicWsReady = false;
  HistoryWsPhase _clinicWsPhase = HistoryWsPhase.disconnected;
  var _clinicWsManualReconnecting = false;
  var _gaveUpSnackbarShown = false;
  String? _activeTurnId;
  _ChatItem? _activeAssistant;
  var _followLatest = true;
  var _showScrollToBottomButton = false;
  var _autoScrolling = false;
  String? _sessionDeviceNo;

  bool get _streaming => _activeTurnId != null && _activeAssistant != null;

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
        subtitle: '登录并绑定宝宝后，可基于喂养记录向 AI 提问',
        actionLabel: '去登录',
        onAction: () => unawaited(context.push('/login')),
      );
    }
    final dnAsync = ref.watch(deviceNoNotifierProvider);
    if (_needsDeviceBind(dnAsync)) {
      return AppEmptyStateGallery(
        animationPath: 'assets/images/ani_baby_welcome.json',
        title: '嗨，我是胖宝！',
        subtitle: '绑定宝宝信息后，我才能结合喂养记录回答你的问题',
        actionLabel: '立即绑定宝宝',
        onAction: () => unawaited(context.push('/settings/bind-baby')),
      );
    }
    return const AppEmptyStateGallery(
      animationPath: 'assets/images/ani_baby_feeding_guide.json',
      title: '开始提问',
      subtitle: '我会结合近 7 天喂养记录作答；问答记录仅保留12个小时。',
      fallbackIcon: Icons.medical_services_outlined,
    );
  }

  Widget _buildConversationArea(BuildContext context) {
    if (_items.isEmpty) {
      return _buildEmptyGallery(context, ref);
    }
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
                child: HomeHistoryScrollToBottomButton(onPressed: _onScrollToBottomTap),
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
            title: '使用胖宝诊疗前请知悉',
            message: '您的问题及近 7 天喂养聚合摘要将发送至 AI 诊疗；回答过程可能展示 AI 思考过程。',
            confirmLabel: '同意并继续',
          ) ??
          false;
      if (!ok) {
        if (mounted) context.pop();
        return;
      }
      await PangbaoAiConsentStore.saveAccepted();
      _consented = true;
    }
    if (!mounted) return;
    _setupWs(desired: true);
    unawaited(_hydrateFromLocalCacheIfEmpty());
  }

  void _setupWs({required bool desired}) {
    _client ??= ClinicWsClient(
      wsUrl: AppEnv.wsClinicUrlEffective,
      ref: ref,
      deviceNoGetter: () => ref.read(deviceNoNotifierProvider).asData?.value,
    );
    _frameSub ??= _client!.frames.listen(_onFrame);
    _bindClinicWsStatusSubscriptions();
    _client!.setConnectionDesired(desired);
  }

  void _bindClinicWsStatusSubscriptions() {
    final client = _client;
    if (client == null) return;
    if (_clinicWsReadySub == null && _clinicWsPhaseSub == null) {
      _clinicWsReady = client.isClinicWebSocketReady;
      _clinicWsPhase = client.clinicWsPhase;
    }
    _clinicWsReadySub ??= client.clinicWsReadyStream.listen((v) {
      if (!mounted) return;
      setState(() {
        _clinicWsReady = v;
        if (v) _gaveUpSnackbarShown = false;
      });
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

  String _clinicWsBannerMessage() {
    return switch (_clinicWsPhase) {
      HistoryWsPhase.gaveUp => kHomeHistoryWsGaveUpMessage,
      HistoryWsPhase.ready ||
      HistoryWsPhase.disconnected ||
      HistoryWsPhase.autoReconnecting =>
        kHomeHistoryWsDisconnectMessage,
    };
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
    final failed = snapshot.failed.where((f) => !completedQ.contains(f.question.trim())).toList();
    AppDebugLog.pangbaoClinic(
      'hydrate deviceNo=$dn completed=${snapshot.completed.length} failed=${failed.length}',
    );
    setState(() {
      _items.addAll(_itemsFromCachedTurns(snapshot.completed));
      _items.addAll(_itemsFromFailedTurns(failed));
    });
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
          thinking: thinkingRaw != null && thinkingRaw.isNotEmpty ? thinkingRaw : null,
        ),
      );
    }
    return out;
  }

  List<PangbaoClinicTurn> _completedTurnsFromItems() {
    final out = <PangbaoClinicTurn>[];
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isUser) continue;
      if (i + 1 >= _items.length || _items[i + 1].isUser) continue;
      final assistant = _items[i + 1];
      if (assistant.isError) continue;
      final question = _items[i].question?.trim() ?? '';
      final answer = _items[i + 1].answer?.trim() ?? '';
      if (question.isEmpty || answer.isEmpty) continue;
      final thinkingRaw = _items[i + 1].thinking?.trim();
      out.add(
        PangbaoClinicTurn(
          question: question,
          answer: answer,
          thinking: thinkingRaw != null && thinkingRaw.isNotEmpty ? thinkingRaw : null,
        ),
      );
    }
    return out;
  }

  Map<String, String> _thinkingByQuestionFromItems() {
    final out = <String, String>{};
    for (var i = 0; i < _items.length - 1; i++) {
      if (!_items[i].isUser || _items[i + 1].isUser) continue;
      final q = _items[i].question?.trim() ?? '';
      final t = _items[i + 1].thinking?.trim();
      if (q.isNotEmpty && t != null && t.isNotEmpty) {
        out[q] = t;
      }
    }
    return out;
  }

  Future<Map<String, String>> _thinkingByQuestionIncludingCache() async {
    final out = _thinkingByQuestionFromItems();
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) return out;
    final snapshot = await PangbaoClinicSessionStore.loadSnapshot(dn);
    for (final turn in snapshot.completed) {
      final q = turn.question.trim();
      final t = turn.thinking?.trim();
      if (q.isNotEmpty && t != null && t.isNotEmpty && !out.containsKey(q)) {
        out[q] = t;
      }
    }
    for (final turn in snapshot.failed) {
      final q = turn.question.trim();
      final t = turn.thinking?.trim();
      if (q.isNotEmpty && t != null && t.isNotEmpty && !out.containsKey(q)) {
        out[q] = t;
      }
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
      if (parsed.businessCode != null && isAiQuotaBusinessCode(parsed.businessCode!) && mounted) {
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
      if (_activeAssistant != null) return;
      final turns = ClinicWsClient.parseSessionSyncTurns(frame);
      unawaited(_applySessionSync(turns));
      return;
    }
    if (type == 'turn_cancelled') {
      final turnId = frame['turnId'] as String? ?? '';
      final reason = frame['reason'] as String? ?? '';
      if (turnId.isEmpty) return;
      setState(() {
        if (turnId == _activeTurnId) {
          _clearActiveStreaming(removeAssistant: true);
        } else {
          _removePartialAssistantForTurn(turnId);
        }
      });
      if (reason == 'cancelled' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已停止'), duration: Duration(seconds: 2)),
        );
      }
      return;
    }
    if (_activeAssistant == null || _activeTurnId == null) return;
    final frameTurnId = frame['turnId'] as String? ?? '';
    if (frameTurnId.isNotEmpty && frameTurnId != _activeTurnId) return;
    setState(() {
      switch (type) {
        case 'thinking_delta':
          _activeAssistant!.thinking = (_activeAssistant!.thinking ?? '') + (frame['delta'] as String? ?? '');
          break;
        case 'answer_delta':
          if ((_activeAssistant!.answer ?? '').isEmpty) {
            _activeAssistant!.thinkingExpanded = false;
          }
          _activeAssistant!.answer = (_activeAssistant!.answer ?? '') + (frame['delta'] as String? ?? '');
          break;
        case 'answer_done':
          _activeAssistant!.thinkingExpanded = false;
          _activeAssistant!.thinking = frame['thinking'] as String? ?? _activeAssistant!.thinking;
          _activeAssistant!.answer = frame['answer'] as String? ?? _activeAssistant!.answer;
          _activeTurnId = null;
          _activeAssistant = null;
          ref.invalidate(voiceAiQuotaProvider);
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

  Future<void> _applySessionSync(List<ClinicSessionTurn> turns) async {
    if (turns.isEmpty) {
      if (_items.isNotEmpty) {
        AppDebugLog.pangbaoClinic('session_sync empty kept items=${_items.length}');
        return;
      }
      await _hydrateFromLocalCacheIfEmpty();
      return;
    }
    final thinkingByQuestion = await _thinkingByQuestionIncludingCache();
    final dn = ref.read(deviceNoNotifierProvider).asData?.value;
    final serverQ = turns.map((t) => t.question.trim()).toSet();
    final failedFromMemory = _failedTurnsFromItems();
    final failedFromStore = dn != null && dn.isNotEmpty
        ? (await PangbaoClinicSessionStore.loadSnapshot(dn)).failed
        : const <PangbaoClinicFailedTurn>[];
    final failedToAppend = <PangbaoClinicFailedTurn>[];
    for (final f in [...failedFromMemory, ...failedFromStore]) {
      final q = f.question.trim();
      if (q.isEmpty || serverQ.contains(q)) continue;
      if (failedToAppend.any((x) => x.question.trim() == q)) continue;
      failedToAppend.add(f);
    }
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(_itemsFromSessionTurns(turns, thinkingByQuestion: thinkingByQuestion))
        ..addAll(_itemsFromFailedTurns(failedToAppend));
      _followLatest = true;
      _showScrollToBottomButton = false;
    });
    AppDebugLog.pangbaoClinic(
      'session_sync merged turns=${turns.length} failedKept=${failedToAppend.length}',
    );
    unawaited(_persistSessionStore());
    _scrollToBottom(animate: false, force: true);
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
      out.add(_ChatItem.user(turn.question));
      final assistant = _ChatItem.assistant();
      assistant.thinking = turn.thinking;
      assistant.answer = turn.answer;
      out.add(assistant);
    }
    return out;
  }

  List<_ChatItem> _itemsFromSessionTurns(
    List<ClinicSessionTurn> turns, {
    Map<String, String>? thinkingByQuestion,
  }) {
    final out = <_ChatItem>[];
    for (final turn in turns) {
      out.add(_ChatItem.user(turn.question));
      final assistant = _ChatItem.assistant();
      final q = turn.question.trim();
      assistant.thinking = thinkingByQuestion?[q];
      assistant.answer = turn.answer;
      out.add(assistant);
    }
    return out;
  }

  void _onScroll() {
    if (_autoScrolling || !_scroll.hasClients) return;
    final pos = _scroll.position;
    if (!pos.maxScrollExtent.isFinite) return;
    final nearBottom = pos.maxScrollExtent - pos.pixels <= _followBottomThreshold;
    if (_followLatest == nearBottom) return;
    setState(() {
      _followLatest = nearBottom;
      _showScrollToBottomButton = !nearBottom && _items.isNotEmpty;
    });
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

  Future<void> _send() async {
    if (!_consented) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    setState(() {
      if (_activeAssistant != null) {
        final idx = _items.indexOf(_activeAssistant!);
        if (idx >= 0) _items.removeAt(idx);
      }
      _items.add(_ChatItem.user(text));
      _activeAssistant = _ChatItem.assistant();
      _items.add(_activeAssistant!);
      _followLatest = true;
      _showScrollToBottomButton = false;
    });
    _scrollToBottom(force: true);
    final turnId = await _client?.sendQuestion(text);
    if (turnId != null) {
      setState(() => _activeTurnId = turnId);
    }
  }

  Future<void> _stopStreaming() async {
    final turnId = _activeTurnId ?? _client?.activeTurnId;
    if (turnId == null || turnId.isEmpty) return;
    await _client?.sendCancel(turnId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _client?.setConnectionDesired(false);
    } else if (state == AppLifecycleState.resumed && _consented) {
      _client?.onAppLifecycleResumed();
      _client?.setConnectionDesired(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_onScroll);
    _frameSub?.cancel();
    _clinicWsReadySub?.cancel();
    _clinicWsPhaseSub?.cancel();
    _client?.dispose();
    _input.dispose();
    _inputFocusNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, loggedIn) {
      if (loggedIn && _consented) {
        _setupWs(desired: true);
      }
    });
    ref.listen<String?>(sessionProvider.select((s) => s.accessToken), (prev, next) {
      if (!SessionController.isAccessTokenRotation(prev, next)) return;
      if (_consented && ref.read(sessionProvider).isLoggedIn) {
        _reconnectClinicWs();
      }
    });
    ref.listen<bool>(sessionProvider.select((s) => s.isRefreshInFlight), (prev, inFlight) {
      if (prev != true || inFlight || !_consented) return;
      if (!ref.read(sessionProvider).isLoggedIn) return;
      _reconnectClinicWs();
    });
    ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (prev, next) {
      final dn = next.asData?.value;
      if (dn == null || dn.isEmpty) return;
      unawaited(_onDeviceNoChanged(dn));
    });

    final quota = ref.watch(voiceAiQuotaProvider);
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final dnAsync = ref.watch(deviceNoNotifierProvider);
    final canUseInput = _consented && loggedIn && !_needsDeviceBind(dnAsync);
    final needsDeviceBind = loggedIn && _needsDeviceBind(dnAsync);
    final refreshInFlight = ref.watch(sessionProvider.select((s) => s.isRefreshInFlight));
    final showWsRefreshBanner = _consented &&
        loggedIn &&
        !needsDeviceBind &&
        !_clinicWsReady &&
        refreshInFlight &&
        _clinicWsPhase != HistoryWsPhase.autoReconnecting;
    final showWsDisconnectBanner = _consented &&
        loggedIn &&
        !needsDeviceBind &&
        !_clinicWsReady &&
        !refreshInFlight &&
        _clinicWsPhase != HistoryWsPhase.autoReconnecting;
    final showWsBanner = showWsRefreshBanner || showWsDisconnectBanner;
    final wsBannerMessage = showWsRefreshBanner
        ? kHomeHistoryWsRefreshRecoveryMessage
        : _clinicWsBannerMessage();
    final wsBannerVariant =
        showWsRefreshBanner ? HomeHistoryWsBannerVariant.info : HomeHistoryWsBannerVariant.error;
    final wsBannerReconnecting =
        _clinicWsPhase == HistoryWsPhase.autoReconnecting || _clinicWsManualReconnecting;
    final wsBannerTapEnabled = !showWsRefreshBanner;
    final inputHint = !_consented
        ? '请先同意告知'
        : !loggedIn
            ? '请先登录'
            : _needsDeviceBind(dnAsync)
                ? '请先绑定宝宝'
                : '问问胖宝诊疗…';

    return Scaffold(
      appBar: AppBar(title: const Text('胖宝诊疗')),
      body: Column(
        children: [
          quota.when(
            data: (s) {
              if (s == null) return const SizedBox.shrink();
              final snap = s.clinicAi;
              if (snap.limit <= 0) return const SizedBox.shrink();
              final label = snap.degraded
                  ? '本月胖宝诊疗额度已用完，已降速'
                  : '本月胖宝诊疗剩余 ${snap.remaining} 次';
              final colorScheme = Theme.of(context).colorScheme;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: snap.degraded ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: snap.degraded ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          HomeHistoryWsStatusBanner(
            visible: showWsBanner,
            message: wsBannerMessage,
            reconnecting: wsBannerReconnecting,
            tapEnabled: wsBannerTapEnabled,
            variant: wsBannerVariant,
            onReconnect: () => unawaited(_reconnectClinicWsFromBanner()),
          ),
          Expanded(
            child: _buildConversationArea(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.paddingOf(context).bottom),
            child: Row(
              children: [
                Expanded(
                  child: KeyboardDismissExclude(
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocusNode,
                      enabled: canUseInput,
                      textInputAction: TextInputAction.send,
                      onSubmitted: canUseInput ? (_) => unawaited(_send()) : null,
                      decoration: ucgComposerFieldDecoration(
                        context,
                        hint: inputHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_streaming)
                  IconButton.filled(
                    onPressed: canUseInput ? _stopStreaming : null,
                    icon: const Icon(Icons.stop),
                    tooltip: '停止',
                  )
                else
                  IconButton.filled(
                    onPressed: canUseInput ? _send : null,
                    icon: const Icon(Icons.send),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_ChatItem item) {
    if (item.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: _consented
              ? () {
                  final q = item.question ?? '';
                  if (q.isEmpty) return;
                  _input.text = q;
                  _input.selection = TextSelection.collapsed(offset: q.length);
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(item.question ?? ''),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((item.thinking ?? '').isNotEmpty)
          _ThinkingBlock(
            item: item,
            streaming: item == _activeAssistant &&
                (item.answer ?? '').isEmpty &&
                !item.isError,
            onTap: () => setState(() => item.thinkingExpanded = !item.thinkingExpanded),
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClinicAnswerBody(
              text: item.answer ?? '',
              streaming: item == _activeAssistant && _streaming,
            ),
          ),
        if (!item.isError && (item.answer ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '本回答仅供参考，不能替代医生诊断',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
          ),
      ],
    );
  }
}

class _ThinkingBlock extends StatelessWidget {
  const _ThinkingBlock({
    required this.item,
    required this.onTap,
    this.streaming = false,
  });

  final _ChatItem item;
  final VoidCallback onTap;
  final bool streaming;

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
    final displayText = streaming ? '$raw▍' : raw;
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
            final overflow = folded && _hasVisualOverflow(displayText, textWidth, style);

            Widget body;
            if (streaming) {
              body = Text(displayText, style: style);
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streaming ? '思考中…' : '思考过程',
                  style: TextStyle(fontSize: 11, color: scheme.primary),
                ),
                const SizedBox(height: 4),
                body,
                if (overflow)
                  Text('点击展开', style: TextStyle(fontSize: 10, color: scheme.primary)),
              ],
            );
          },
        ),
      ),
    );
  }
}
