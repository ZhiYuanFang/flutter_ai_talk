import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../../session/token_expiry.dart';
import '../providers/ucg_providers.dart';
import 'ucg_chat_screen.dart';
import 'ucg_login_gate.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

class UcgMessagesTab extends ConsumerStatefulWidget {
  const UcgMessagesTab({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  ConsumerState<UcgMessagesTab> createState() => _UcgMessagesTabState();
}

class _UcgMessagesTabState extends ConsumerState<UcgMessagesTab> {
  var _items = <UcgConversation>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    final wxId = ref.read(ucgCurrentUserIdProvider);
    if (isUcgWxAccountBound(wxId)) {
      ref.read(ucgRepositoryProvider).setWsConnectionDesired(true);
    }
  }

  Future<void> _load() async {
    if (!ref.read(sessionProvider).isLoggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list = await ref.read(ucgRepositoryProvider).fetchConversations();
      if (mounted) {
        setState(() => _items = list);
        final unread = list.fold<int>(0, (s, c) => s + c.unreadCount);
        ref.read(ucgUnreadCountProvider.notifier).state = unread;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteConv(UcgConversation c) async {
    await ref.read(ucgRepositoryProvider).deleteConversation(c.id);
    if (mounted) setState(() => _items.removeWhere((e) => e.id == c.id));
  }

  Future<void> _pinConv(UcgConversation c, bool pinned) async {
    await ref.read(ucgRepositoryProvider).pinConversation(c.id, pinned: pinned);
    if (mounted) {
      setState(() {
        final i = _items.indexWhere((e) => e.id == c.id);
        if (i >= 0) _items[i] = c.copyWith(pinned: pinned);
        _items.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          final at = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(sessionProvider.select((s) => s.isLoggedIn))) {
      return UcgTabPage(
        title: '消息',
        subtitle: '与宝妈宝爸私信聊天',
        leading: ucgBackLeading(context, widget.onBackToFeeding),
        body: const UcgLoginPrompt(message: '登录后查看消息'),
      );
    }
    if (!isUcgWxAccountBound(ref.watch(ucgCurrentUserIdProvider))) {
      return UcgTabPage(
        title: '消息',
        subtitle: '与宝妈宝爸私信聊天',
        leading: ucgBackLeading(context, widget.onBackToFeeding),
        body: const UcgWxBindPrompt(),
      );
    }

    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final fmt = DateFormat('MM-dd HH:mm');

    return UcgTabPage(
      title: '消息',
      subtitle: '与宝妈宝爸私信聊天',
      leading: ucgBackLeading(context, widget.onBackToFeeding),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? const UcgEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: '暂无会话',
                  subtitle: '开始和朋友们聊天吧',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = _items[i];
                    return Dismissible(
                      key: ValueKey(c.id),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.push_pin_outlined, color: primary),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      ),
                      confirmDismiss: (dir) async {
                        if (dir == DismissDirection.startToEnd) {
                          await _pinConv(c, !c.pinned);
                          return false;
                        }
                        await _deleteConv(c);
                        return true;
                      },
                      child: UcgShellGlassCard(
                        onTap: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(builder: (_) => UcgChatScreen(conversation: c)),
                          );
                          unawaited(_load());
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primary.withValues(alpha: 0.25)),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: primary.withValues(alpha: 0.1),
                                backgroundImage: c.peerAvatarUrl != null
                                    ? ucgNetworkImageProvider(c.peerAvatarUrl!)
                                    : null,
                                child: c.peerAvatarUrl == null
                                    ? Icon(Icons.person_rounded, color: primary)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c.peerNickname,
                                          style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                                        ),
                                      ),
                                      if (c.lastMessageAt != null)
                                        Text(
                                          fmt.format(c.lastMessageAt!.toLocal()),
                                          style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.45)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.lastMessagePreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: fg.withValues(alpha: 0.58), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (c.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${c.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
