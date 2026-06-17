import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/ai_quota_errors.dart';
import '../config/env.dart';
import '../config/pangbao_ai_consent_store.dart';
import '../providers/ai_quota_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';
import '../ucg/ui/widgets/ucg_visual_widgets.dart';
import '../ui/widgets/app_glass_overlay.dart';
import '../ui/widgets/clinic_answer_body.dart';
import 'home_history_scroll_to_bottom_button.dart';
import '../ui/widgets/keyboard_dismiss_scope.dart';
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
}

class _PangbaoAiScreenState extends ConsumerState<PangbaoAiScreen> with WidgetsBindingObserver {
  static const _followBottomThreshold = 48.0;

  final _items = <_ChatItem>[];
  final _input = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scroll = ScrollController();
  ClinicWsClient? _client;
  StreamSubscription<Map<String, dynamic>>? _frameSub;
  var _consented = false;
  String? _activeTurnId;
  _ChatItem? _activeAssistant;
  var _followLatest = true;
  var _showScrollToBottomButton = false;
  var _autoScrolling = false;

  bool get _streaming => _activeTurnId != null && _activeAssistant != null;

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
            message: '您的问题及近 7 天喂养聚合摘要将发送至 DeepSeek；回答过程可能展示 AI 思考过程。',
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
  }

  void _setupWs({required bool desired}) {
    final session = ref.read(sessionProvider);
    _client ??= ClinicWsClient(
      wsUrl: AppEnv.wsClinicUrlEffective,
      accessTokenGetter: () => session.accessToken,
      deviceNoGetter: () => ref.read(deviceNoNotifierProvider).asData?.value,
    );
    _frameSub ??= _client!.frames.listen(_onFrame);
    _client!.setConnectionDesired(desired);
  }

  void _onFrame(Map<String, dynamic> frame) {
    final type = (frame['type'] as String? ?? '').toLowerCase();
    if (type == 'error') {
      final code = ClinicWsClient.businessCodeFromFrame(frame);
      if (code != null && mounted) {
        unawaited(handleAiQuotaBusinessCode(context, code));
      }
      setState(() {
        _clearActiveStreaming(removeAssistant: true);
      });
      return;
    }
    if (type == 'session_sync') {
      if (_activeAssistant != null) return;
      final turns = ClinicWsClient.parseSessionSyncTurns(frame);
      setState(() {
        _items
          ..clear()
          ..addAll(_itemsFromSessionTurns(turns));
        _followLatest = true;
        _showScrollToBottomButton = false;
      });
      _scrollToBottom(animate: false, force: true);
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

  List<_ChatItem> _itemsFromSessionTurns(List<ClinicSessionTurn> turns) {
    final out = <_ChatItem>[];
    for (final turn in turns) {
      out.add(_ChatItem.user(turn.question));
      final assistant = _ChatItem.assistant();
      assistant.thinking = null;
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
      _client?.setConnectionDesired(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_onScroll);
    _frameSub?.cancel();
    _client?.dispose();
    _input.dispose();
    _inputFocusNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quota = ref.watch(voiceAiQuotaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('胖宝诊疗')),
      body: Column(
        children: [
          quota.when(
            data: (s) {
              if (s == null) return const SizedBox.shrink();
              final snap = s.clinicAi;
              if (snap.limit <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '本月胖宝诊疗剩余 ${snap.remaining} 次',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: Stack(
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
            ),
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
                      enabled: _consented,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _consented ? (_) => unawaited(_send()) : null,
                      decoration: ucgComposerFieldDecoration(
                        context,
                        hint: _consented ? '问问胖宝诊疗…' : '请先同意告知',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_streaming)
                  IconButton.filled(
                    onPressed: _consented ? _stopStreaming : null,
                    icon: const Icon(Icons.stop),
                    tooltip: '停止',
                  )
                else
                  IconButton.filled(
                    onPressed: _consented ? _send : null,
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
            streaming: item == _activeAssistant && (item.answer ?? '').isEmpty,
            onTap: () => setState(() => item.thinkingExpanded = !item.thinkingExpanded),
          ),
        if ((item.answer ?? '').isNotEmpty)
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
        if ((item.answer ?? '').isNotEmpty)
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
