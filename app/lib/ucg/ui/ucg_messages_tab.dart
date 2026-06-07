import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../theme/ucg_theme.dart';
import '../data/ucg_models.dart';
import '../../session/token_expiry.dart';
import '../providers/ucg_providers.dart';
import 'ucg_chat_screen.dart';
import 'ucg_login_gate.dart';
import 'ucg_post_detail_screen.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

class UcgMessagesTab extends ConsumerStatefulWidget {
  const UcgMessagesTab({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  ConsumerState<UcgMessagesTab> createState() => _UcgMessagesTabState();
}

class _UcgMessagesTabState extends ConsumerState<UcgMessagesTab> {
  StreamSubscription<void>? _notifSub;

  @override
  void initState() {
    super.initState();
    final wxId = ref.read(ucgCurrentUserIdProvider);
    if (isUcgWxAccountBound(wxId)) {
      final repo = ref.read(ucgRepositoryProvider);
      repo.setWsConnectionDesired(true);
      _notifSub = repo.notificationEvents.listen((_) {
        bumpUcgNotificationsRefresh(ref);
      });
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _deleteConv(UcgConversation c) async {
    await ref.read(ucgRepositoryProvider).deleteConversation(c.id);
    bumpUcgConversationsRefresh(ref);
  }

  String _peerDisplayName(UcgConversation c) {
    final nick = c.peerNickname.trim();
    if (nick.isNotEmpty) return nick;
    if (c.peerId.isNotEmpty) return '用户 ${c.peerId}';
    return '用户';
  }

  Future<void> _pinConv(UcgConversation c, bool pinned) async {
    await ref.read(ucgRepositoryProvider).pinConversation(c.id, pinned: pinned);
    bumpUcgConversationsRefresh(ref);
  }

  void _syncUnreadBadge(List<UcgConversation> items, int interactionUnread) {
    final chatUnread = items.fold<int>(0, (s, c) => s + c.unreadCount);
    ref.read(ucgUnreadCountProvider.notifier).state = chatUnread + interactionUnread;
  }

  Future<void> _openNotification(UcgCommentNotification n) async {
    if (!n.read) {
      await ref.read(ucgRepositoryProvider).markNotificationsRead(ids: [n.id]);
      bumpUcgNotificationsRefresh(ref);
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UcgPostDetailScreen(postId: n.postId),
      ),
    );
  }

  String _notificationTitle(UcgCommentNotification n) {
    final nick = n.actorNickname.trim().isEmpty ? '用户' : n.actorNickname.trim();
    return switch (n.type) {
      'mention_in_comment' => '$nick 在评论中提到了你',
      _ => '$nick 评论了你的动态',
    };
  }

  String _displayNotificationPreview(String preview) {
    return preview.replaceAll(RegExp(r'@([^\s@]+?)#\d+'), r'@$1');
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
    final conversationsAsync = ref.watch(ucgConversationsProvider);
    final notificationsAsync = ref.watch(ucgCommentNotificationsProvider);

    ref.listen<AsyncValue<List<UcgConversation>>>(ucgConversationsProvider, (prev, next) {
      final interactionUnread = ref.read(ucgCommentNotificationsProvider).valueOrNull?.unreadCount ?? 0;
      next.whenData((items) => _syncUnreadBadge(items, interactionUnread));
    });
    ref.listen<AsyncValue<UcgPagedCommentNotifications>>(ucgCommentNotificationsProvider, (prev, next) {
      final interactionUnread = next.valueOrNull?.unreadCount ?? 0;
      conversationsAsync.whenData((items) => _syncUnreadBadge(items, interactionUnread));
    });

    return UcgTabPage(
      title: '消息',
      subtitle: '与宝妈宝爸私信聊天',
      leading: ucgBackLeading(context, widget.onBackToFeeding),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => UcgEmptyState(
          icon: Icons.cloud_off_rounded,
          title: '加载失败',
          subtitle: '请稍后重试',
          action: TextButton(
            onPressed: () {
              bumpUcgConversationsRefresh(ref);
              bumpUcgNotificationsRefresh(ref);
            },
            child: const Text('重试'),
          ),
        ),
        data: (conversations) {
          final notifications = notificationsAsync.valueOrNull?.items ?? const <UcgCommentNotification>[];
          final interactionUnread = notificationsAsync.valueOrNull?.unreadCount ?? 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncUnreadBadge(conversations, interactionUnread);
          });

          if (conversations.isEmpty && notifications.isEmpty) {
            return const UcgEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: '暂无消息',
              subtitle: '互动与私信都会出现在这里',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              bumpUcgConversationsRefresh(ref);
              bumpUcgNotificationsRefresh(ref);
              await Future.wait([
                ref.read(ucgConversationsProvider.future),
                ref.read(ucgCommentNotificationsProvider.future),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (notifications.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        '互动消息',
                        style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 15),
                      ),
                      if (interactionUnread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$interactionUnread',
                            style: TextStyle(
                              color: UcgTheme.onPrimary(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final n in notifications)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: UcgShellGlassCard(
                        onTap: () => unawaited(_openNotification(n)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            UcgAvatar(
                              radius: 20,
                              url: n.actorAvatarUrl,
                              backgroundColor: primary.withValues(alpha: 0.1),
                              foregroundColor: primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _notificationTitle(n),
                                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                                  ),
                                  if (n.preview.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _displayNotificationPreview(n.preview),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: fg.withValues(alpha: 0.58), fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!n.read)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              fmt.format(n.createdAt.toLocal()),
                              style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.45)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (conversations.isNotEmpty)
                    Text(
                      '私信',
                      style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 15),
                    ),
                  if (conversations.isNotEmpty) const SizedBox(height: 8),
                ],
                for (var i = 0; i < conversations.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _ConversationTile(
                    conversation: conversations[i],
                    fg: fg,
                    primary: primary,
                    fmt: fmt,
                    peerDisplayName: _peerDisplayName(conversations[i]),
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => UcgChatScreen(conversation: conversations[i]),
                        ),
                      );
                    },
                    onPin: (pinned) => _pinConv(conversations[i], pinned),
                    onDelete: () => _deleteConv(conversations[i]),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.fg,
    required this.primary,
    required this.fmt,
    required this.peerDisplayName,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  final UcgConversation conversation;
  final Color fg;
  final Color primary;
  final DateFormat fmt;
  final String peerDisplayName;
  final VoidCallback onTap;
  final Future<void> Function(bool pinned) onPin;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
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
          await onPin(!c.pinned);
          return false;
        }
        await onDelete();
        return true;
      },
      child: UcgShellGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: UcgAvatar(
                radius: 22,
                url: c.peerAvatarThumbnailUrl,
                backgroundColor: primary.withValues(alpha: 0.1),
                foregroundColor: primary,
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
                          peerDisplayName,
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
                  style: TextStyle(
                    color: UcgTheme.onPrimary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
