import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_post_detail_screen.dart';
import 'widgets/ucg_mention_text.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

/// 互动消息 Inbox：分页列表、全部已读、行点击进详情。
class UcgInteractionInboxScreen extends ConsumerStatefulWidget {
  const UcgInteractionInboxScreen({super.key});

  @override
  ConsumerState<UcgInteractionInboxScreen> createState() => _UcgInteractionInboxScreenState();
}

class _UcgInteractionInboxScreenState extends ConsumerState<UcgInteractionInboxScreen> {
  final _scrollController = ScrollController();
  var _items = <UcgCommentNotification>[];
  var _page = 1;
  var _hasMore = true;
  var _loading = true;
  var _loadingMore = false;
  var _unreadCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadFirst());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final page = await ref.read(ucgRepositoryProvider).fetchCommentNotifications(page: 1);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _page = page.page;
        _hasMore = page.hasMore;
        _unreadCount = page.unreadCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败';
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final page = await ref.read(ucgRepositoryProvider).fetchCommentNotifications(page: nextPage);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _page = page.page;
        _hasMore = page.hasMore;
        _unreadCount = page.unreadCount;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _markAllRead() async {
    await ref.read(ucgRepositoryProvider).markNotificationsRead(all: true);
    bumpUcgNotificationsRefresh(ref);
    unawaited(ref.read(ucgUnreadSyncProvider)());
    if (!mounted) return;
    setState(() {
      _unreadCount = 0;
      _items = [
        for (final n in _items) UcgCommentNotification(
          id: n.id,
          type: n.type,
          postId: n.postId,
          commentId: n.commentId,
          actorId: n.actorId,
          actorNickname: n.actorNickname,
          actorAvatarUrl: n.actorAvatarUrl,
          preview: n.preview,
          postThumbUrl: n.postThumbUrl,
          postMediaKind: n.postMediaKind,
          read: true,
          createdAt: n.createdAt,
        ),
      ];
    });
  }

  Future<void> _openNotification(UcgCommentNotification n) async {
    if (!n.read) {
      await ref.read(ucgRepositoryProvider).markNotificationsRead(ids: [n.id]);
      bumpUcgNotificationsRefresh(ref);
      unawaited(ref.read(ucgUnreadSyncProvider)());
      if (mounted) {
        setState(() {
          _unreadCount = (_unreadCount - 1).clamp(0, 999999);
          final i = _items.indexWhere((x) => x.id == n.id);
          if (i >= 0) {
            final old = _items[i];
            _items[i] = UcgCommentNotification(
              id: old.id,
              type: old.type,
              postId: old.postId,
              commentId: old.commentId,
              actorId: old.actorId,
              actorNickname: old.actorNickname,
              actorAvatarUrl: old.actorAvatarUrl,
              preview: old.preview,
              postThumbUrl: old.postThumbUrl,
              postMediaKind: old.postMediaKind,
              read: true,
              createdAt: old.createdAt,
            );
          }
        });
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => UcgPostDetailScreen(postId: n.postId)),
    );
  }

  String _titleFor(UcgCommentNotification n) {
    final nick = n.actorNickname.trim().isEmpty ? '用户' : n.actorNickname.trim();
    return switch (n.type) {
      'mention_in_comment' => '$nick 在评论中提到了你',
      _ => '$nick 评论了你的动态',
    };
  }

  String _displayPreview(String preview) => UcgMentionText.displayComment(preview);

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final fmt = DateFormat('MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('互动消息'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () => unawaited(_markAllRead()),
              child: const Text('全部已读'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? UcgEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: _error!,
                  subtitle: '请稍后重试',
                  action: TextButton(onPressed: () => unawaited(_loadFirst()), child: const Text('重试')),
                )
              : _items.isEmpty
                  ? const UcgEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: '暂无互动消息',
                      subtitle: '评论与 @ 提及会出现在这里',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFirst,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          final n = _items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: UcgSurfaceCard(
                              onTap: () => unawaited(_openNotification(n)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          _titleFor(n),
                                          style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                                        ),
                                        if (n.preview.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _displayPreview(n.preview),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: fg.withValues(alpha: 0.58),
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          fmt.format(n.createdAt.toLocal()),
                                          style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.45)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _PostThumb(url: n.postThumbUrl, mediaKind: n.postMediaKind),
                                  if (!n.read) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _PostThumb extends StatelessWidget {
  const _PostThumb({required this.url, required this.mediaKind});

  final String url;
  final int mediaKind;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    const size = 52.0;
    if (url.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          mediaKind == 2 ? Icons.videocam_outlined : Icons.image_outlined,
          size: 22,
          color: fg.withValues(alpha: 0.35),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: UcgNetworkImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
