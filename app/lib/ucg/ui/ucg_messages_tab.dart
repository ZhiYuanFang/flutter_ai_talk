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
import 'ucg_interaction_inbox_screen.dart';
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
  final _scrollController = ScrollController();
  var _conversations = <UcgConversation>[];
  var _convPage = 1;
  var _convHasMore = true;
  var _convInitialLoading = true;
  var _convLoadingMore = false;
  var _lastInteractionUnread = 0;
  String? _convError;
  StreamSubscription<UcgChatMessage>? _wsMsgSub;
  StreamSubscription<void>? _wsNotifSub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadConversationsFirst(initial: true));
    _bindWsListeners();
  }

  void _bindWsListeners() {
    final repo = ref.read(ucgRepositoryProvider);
    _wsMsgSub = repo.incomingMessages.listen((_) {
      if (!mounted) return;
      unawaited(_loadConversationsFirst());
    });
    _wsNotifSub = repo.notificationEvents.listen((_) {
      if (!mounted) return;
      bumpUcgNotificationsRefresh(ref);
      unawaited(ref.refresh(ucgCommentNotificationsProvider.future));
    });
  }

  @override
  void dispose() {
    _wsMsgSub?.cancel();
    _wsNotifSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_convHasMore || _convLoadingMore || _convInitialLoading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadConversationsMore());
    }
  }

  static bool _conversationContentEqual(UcgConversation a, UcgConversation b) {
    return a.id == b.id &&
        a.peerId == b.peerId &&
        a.peerNickname == b.peerNickname &&
        a.peerAvatarKey == b.peerAvatarKey &&
        a.peerAvatarCdnUrl == b.peerAvatarCdnUrl &&
        a.peerAvatarThumbnailCdnUrl == b.peerAvatarThumbnailCdnUrl &&
        a.lastMessagePreview == b.lastMessagePreview &&
        a.lastMessageAt == b.lastMessageAt &&
        a.unreadCount == b.unreadCount &&
        a.pinned == b.pinned;
  }

  List<UcgConversation> _mergeConversations(
    List<UcgConversation> current,
    List<UcgConversation> remote,
  ) {
    final byId = {for (final c in current) c.id: c};
    final merged = <UcgConversation>[];
    for (final remoteItem in remote) {
      final existing = byId[remoteItem.id];
      if (existing != null && _conversationContentEqual(existing, remoteItem)) {
        merged.add(existing);
      } else {
        merged.add(remoteItem);
      }
    }
    return merged;
  }

  Future<void> _loadConversationsFirst({bool initial = false}) async {
    if (initial) {
      setState(() {
        _convInitialLoading = true;
        _convError = null;
        _convPage = 1;
      });
    }
    try {
      final page = await ref.read(ucgRepositoryProvider).fetchConversations(page: 1);
      final enriched = await ref.read(ucgRepositoryProvider).enrichConversationsWithPeerProfiles(page.items);
      if (!mounted) return;
      setState(() {
        _conversations = initial || _conversations.isEmpty
            ? enriched
            : _mergeConversations(_conversations, enriched);
        _convPage = page.page;
        _convHasMore = page.hasMore;
        _convInitialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _convInitialLoading = false;
        if (initial || _conversations.isEmpty) {
          _convError = '加载失败';
        }
      });
    }
  }

  Future<void> _loadConversationsMore() async {
    if (!_convHasMore || _convLoadingMore) return;
    setState(() => _convLoadingMore = true);
    try {
      final nextPage = _convPage + 1;
      final page = await ref.read(ucgRepositoryProvider).fetchConversations(page: nextPage);
      final enriched = await ref.read(ucgRepositoryProvider).enrichConversationsWithPeerProfiles(page.items);
      if (!mounted) return;
      setState(() {
        _conversations = [..._conversations, ...enriched];
        _convPage = page.page;
        _convHasMore = page.hasMore;
        _convLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _convLoadingMore = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadConversationsFirst(),
      ref.refresh(ucgCommentNotificationsProvider.future),
    ]);
    await ref.read(ucgUnreadSyncProvider)();
  }

  Future<void> _deleteConv(UcgConversation c) async {
    await ref.read(ucgRepositoryProvider).deleteConversation(c.id);
    setState(() => _conversations = _conversations.where((x) => x.id != c.id).toList());
    unawaited(ref.read(ucgUnreadSyncProvider)());
  }

  String _peerDisplayName(UcgConversation c) {
    final nick = c.peerNickname.trim();
    if (nick.isNotEmpty) return nick;
    if (c.peerId.isNotEmpty) return '用户 ${c.peerId}';
    return '用户';
  }

  Future<void> _pinConv(UcgConversation c, bool pinned) async {
    await ref.read(ucgRepositoryProvider).pinConversation(c.id, pinned: pinned);
    await _loadConversationsFirst();
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
    ref.listen<AsyncValue<UcgPagedCommentNotifications>>(ucgCommentNotificationsProvider, (_, next) {
      final count = next.valueOrNull?.unreadCount;
      if (count != null) {
        _lastInteractionUnread = count;
      }
    });
    final notificationsAsync = ref.watch(ucgCommentNotificationsProvider);
    final interactionUnread =
        notificationsAsync.valueOrNull?.unreadCount ?? _lastInteractionUnread;

    return UcgTabPage(
      title: '消息',
      subtitle: '与宝妈宝爸私信聊天',
      leading: ucgBackLeading(context, widget.onBackToFeeding),
      body: _convInitialLoading && _conversations.isEmpty
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _convError != null && _conversations.isEmpty
              ? UcgEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: _convError!,
                  subtitle: '请稍后重试',
                  action: TextButton(onPressed: () => unawaited(_refreshAll()), child: const Text('重试')),
                )
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _InteractionSystemRow(
                        unreadCount: interactionUnread,
                        fg: fg,
                        primary: primary,
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(builder: (_) => const UcgInteractionInboxScreen()),
                          );
                        },
                      ),
                      if (_conversations.isEmpty && !_convInitialLoading) ...[
                        const SizedBox(height: 24),
                        UcgEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: '暂无私信',
                          subtitle: interactionUnread > 0 ? '互动消息在上方入口查看' : '与宝妈宝爸私信聊天',
                        ),
                      ],
                      for (var i = 0; i < _conversations.length; i++) ...[
                        if (i == 0) const SizedBox(height: 10),
                        if (i > 0) const SizedBox(height: 10),
                        _ConversationTile(
                          key: ValueKey(_conversations[i].id),
                          conversation: _conversations[i],
                          fg: fg,
                          primary: primary,
                          fmt: fmt,
                          peerDisplayName: _peerDisplayName(_conversations[i]),
                          onTap: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => UcgChatScreen(conversation: _conversations[i]),
                              ),
                            );
                            bumpUcgConversationsRefresh(ref);
                            await _loadConversationsFirst();
                          },
                          onPin: (pinned) => _pinConv(_conversations[i], pinned),
                          onDelete: () => _deleteConv(_conversations[i]),
                        ),
                      ],
                      if (_convLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _InteractionSystemRow extends StatelessWidget {
  const _InteractionSystemRow({
    required this.unreadCount,
    required this.fg,
    required this.primary,
    required this.onTap,
  });

  final int unreadCount;
  final Color fg;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return UcgSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_outlined, color: primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '互动消息',
                  style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                ),
                const SizedBox(height: 4),
                Text(
                  '评论与 @ 提及',
                  style: TextStyle(color: fg.withValues(alpha: 0.58), fontSize: 13),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: TextStyle(
                  color: UcgTheme.onPrimary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    super.key,
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
      child: UcgSurfaceCard(
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
