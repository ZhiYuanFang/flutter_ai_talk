import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_login_gate.dart';
import 'ucg_post_detail_screen.dart';
import 'ucg_profile_screens.dart';
import 'widgets/ucg_masonry_feed_card.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

enum _SquareFeedMode { recommended, following }

class UcgSquareTab extends ConsumerStatefulWidget {
  const UcgSquareTab({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  ConsumerState<UcgSquareTab> createState() => _UcgSquareTabState();
}

class _UcgSquareTabState extends ConsumerState<UcgSquareTab> {
  _SquareFeedMode _mode = _SquareFeedMode.recommended;
  final _items = <UcgPost>[];
  var _page = 1;
  var _hasMore = true;
  var _loading = false;
  var _initialLoaded = false;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      unawaited(_load(refresh: false));
    }
  }

  Future<void> _load({required bool refresh}) async {
    if (_loading) return;
    if (_mode == _SquareFeedMode.following && !ref.read(sessionProvider).isLoggedIn) return;
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _page = 1;
        _hasMore = true;
      }
    });
    try {
      final repo = ref.read(ucgRepositoryProvider);
      final result = _mode == _SquareFeedMode.recommended
          ? await repo.fetchRecommendedFeed(page: _page)
          : await repo.fetchFollowingFeed(page: _page);
      if (!mounted) return;
      setState(() {
        if (refresh) _items.clear();
        _items.addAll(result.items);
        _page = result.page + 1;
        _hasMore = result.hasMore;
        _initialLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onModeChanged(_SquareFeedMode mode) async {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    await _load(refresh: true);
  }

  void _openUserProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UcgUserProfileScreen(userId: userId),
      ),
    );
  }

  void _openDetail(UcgPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UcgPostDetailScreen(postId: post.id, seedPost: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(ucgPostsChangedProvider, (previous, next) {
      if (next > 0 && previous != next) {
        unawaited(_load(refresh: true));
      }
    });

    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));

    return UcgTabPage(
      title: '',
      showTitle: false,
      leading: ucgBackLeading(context, widget.onBackToFeeding),
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InlineFeedTab(
            label: '推荐',
            selected: _mode == _SquareFeedMode.recommended,
            primary: primary,
            fg: fg,
            onTap: () => unawaited(_onModeChanged(_SquareFeedMode.recommended)),
          ),
          const SizedBox(width: 16),
          _InlineFeedTab(
            label: '关注',
            selected: _mode == _SquareFeedMode.following,
            primary: primary,
            fg: fg,
            onTap: () {
              if (!loggedIn) {
                setState(() => _mode = _SquareFeedMode.following);
                return;
              }
              unawaited(_onModeChanged(_SquareFeedMode.following));
            },
          ),
        ],
      ),
      body: _mode == _SquareFeedMode.following && !loggedIn
          ? const UcgLoginPrompt(message: '登录后查看关注动态')
          : RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: _buildBody(fg),
            ),
    );
  }

  Widget _buildBody(Color fg) {
    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          UcgEmptyState(
            icon: Icons.cloud_off_rounded,
            title: '加载失败',
            subtitle: '请检查网络后重试',
            action: TextButton(onPressed: () => _load(refresh: true), child: const Text('重试')),
          ),
        ],
      );
    }
    if (_initialLoaded && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          UcgEmptyState(
            icon: Icons.auto_awesome_rounded,
            title: '暂无动态',
            subtitle: '稍后再来看看，或发布第一条动态吧',
          ),
        ],
      );
    }
    return MasonryGridView.count(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: _items.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final post = _items[index];
        return UcgMasonryFeedCard(
          post: post,
          onTap: () => _openDetail(post),
          onAvatarTap: () => _openUserProfile(post.authorId),
        );
      },
    );
  }
}

class _InlineFeedTab extends StatelessWidget {
  const _InlineFeedTab({
    required this.label,
    required this.selected,
    required this.primary,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : fg.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// 保留供详情页等复用的 Moments 卡片（广场已改用 [UcgMasonryFeedCard]）。
class UcgFeedCard extends StatelessWidget {
  const UcgFeedCard({
    super.key,
    required this.post,
    this.onAvatarTap,
    this.onUserTap,
    this.onLikeTap,
    this.onLikeLongPress,
    this.onCommentTap,
    this.onReplyToComment,
    this.showAuditBadge = false,
    this.wrapInShellCard = true,
  });

  final UcgPost post;
  final VoidCallback? onAvatarTap;
  final void Function(String userId)? onUserTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onLikeLongPress;
  final VoidCallback? onCommentTap;
  final void Function(UcgComment comment)? onReplyToComment;
  final bool showAuditBadge;
  final bool wrapInShellCard;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final time = DateFormat('MM-dd HH:mm').format(post.createdAt.toLocal());
    final ipLoc = post.ipLocationDisplay;
    final bio = post.authorBio.trim();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: UcgAvatar(
                  radius: 20,
                  url: post.authorAvatarThumbnailUrl,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  foregroundColor: primary,
                  placeholderIconSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorNickname.isEmpty ? '用户' : post.authorNickname,
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg, fontSize: 15),
                  ),
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.55), height: 1.3),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (post.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            post.text,
            style: TextStyle(color: fg.withValues(alpha: 0.88), height: 1.45, fontSize: 15),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          ipLoc.isNotEmpty ? '$time · $ipLoc' : time,
          style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.42)),
        ),
      ],
    );

    if (!wrapInShellCard) return content;
    return UcgShellGlassCard(child: content);
  }
}
