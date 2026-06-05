import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'widgets/ucg_visual_widgets.dart';

class UcgChatScreen extends ConsumerStatefulWidget {
  const UcgChatScreen({super.key, required this.conversation});

  final UcgConversation conversation;

  @override
  ConsumerState<UcgChatScreen> createState() => _UcgChatScreenState();
}

class _UcgChatScreenState extends ConsumerState<UcgChatScreen> {
  final _controller = TextEditingController();
  final _messages = <UcgChatMessage>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    ref.read(ucgRepositoryProvider).setWsConnectionDesired(true);
    unawaited(_loadHistory());
    _listenWs();
  }

  void _listenWs() {
    ref.read(ucgRepositoryProvider).incomingMessages.listen((msg) {
      if (msg.conversationId != widget.conversation.id) return;
      if (!mounted) return;
      setState(() => _messages.add(msg));
    });
  }

  Future<void> _loadHistory() async {
    try {
      final list =
          await ref.read(ucgRepositoryProvider).fetchChatHistory(widget.conversation.id);
      if (mounted) setState(() => _messages.addAll(list));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final pending = UcgChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: ref.read(ucgCurrentUserIdProvider) ?? '',
      text: text,
      createdAt: DateTime.now(),
      status: UcgChatMessageStatus.pending,
      isMine: true,
    );
    setState(() => _messages.add(pending));
    try {
      await ref.read(ucgRepositoryProvider).sendTextMessage(
            conversationId: widget.conversation.id,
            peerId: widget.conversation.peerId,
            text: text,
          );
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.id == pending.id);
        if (i >= 0) {
          _messages[i] = UcgChatMessage(
            id: pending.id,
            conversationId: pending.conversationId,
            senderId: pending.senderId,
            text: pending.text,
            createdAt: pending.createdAt,
            status: UcgChatMessageStatus.delivered,
            isMine: true,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.id == pending.id);
        if (i >= 0) {
          _messages[i] = UcgChatMessage(
            id: pending.id,
            conversationId: pending.conversationId,
            senderId: pending.senderId,
            text: pending.text,
            createdAt: pending.createdAt,
            status: UcgChatMessageStatus.failed,
            isMine: true,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final conv = widget.conversation;

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: conv.peerNickname,
            subtitle: '一起聊聊育儿日常',
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: fg.withValues(alpha: 0.75)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _messages.isEmpty
                    ? const UcgEmptyState(
                        icon: Icons.waving_hand_rounded,
                        title: '打个招呼吧',
                        subtitle: '发送第一条消息，开启温馨对话',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Align(
                              alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: _ChatBubble(message: m, primary: primary, fg: fg),
                            ),
                          );
                        },
                      ),
          ),
          UcgGlassInputDock(
            controller: _controller,
            hintText: '发消息…',
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.primary,
    required this.fg,
  });

  final UcgChatMessage message;
  final Color primary;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final statusIcon = switch (m.status) {
      UcgChatMessageStatus.pending => Icons.schedule_rounded,
      UcgChatMessageStatus.failed => Icons.error_outline_rounded,
      UcgChatMessageStatus.delivered => Icons.done_all_rounded,
    };
    final statusColor = m.status == UcgChatMessageStatus.failed
        ? Theme.of(context).colorScheme.error
        : primary.withValues(alpha: 0.65);

    if (m.isMine) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.88),
                    Color.lerp(primary, Colors.white, 0.12)!.withValues(alpha: 0.92),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(color: primary.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        m.text,
                        style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(statusIcon, size: 14, color: statusColor.withValues(alpha: 0.9)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      child: UcgShellGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 18,
        child: Text(m.text, style: TextStyle(color: fg, height: 1.35, fontSize: 15)),
      ),
    );
  }
}
