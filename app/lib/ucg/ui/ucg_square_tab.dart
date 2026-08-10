import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_color.dart';
import '../data/ucg_location.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_login_gate.dart';
import 'ucg_post_detail_screen.dart';
import 'ucg_profile_screens.dart';
import 'widgets/ucg_debate_feed_card.dart';
import 'widgets/ucg_location_settings_hint.dart';
import 'widgets/ucg_masonry_feed_card.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

enum _SquareFeedMode { recommended, following }

enum _SquareLoadPhase { idle, locating, fetchingFeed }

/// 广场 Feed 加载阶段提示（定位 / 拉列表）。
class _SquareLoadStatusPanel extends StatelessWidget {
  const _SquareLoadStatusPanel({
    required this.phase,
    required this.mode,
    this.compact = false,
  });

  final _SquareLoadPhase phase;
  final _SquareFeedMode mode;
  final bool compact;

  String get _title => switch (phase) {
        _SquareLoadPhase.locating => '正在获取位置…',
        _SquareLoadPhase.fetchingFeed => mode == _SquareFeedMode.recommended
            ? '正在加载推荐…'
            : '正在加载关注…',
        _SquareLoadPhase.idle => '',
      };

  @override
  Widget build(BuildContext context) {
    if (phase == _SquareLoadPhase.idle) return const SizedBox.shrink();

    final fg = AppColor.textPrimary(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (phase == _SquareLoadPhase.locating)
          Icon(
            Icons.location_searching_rounded,
            size: compact ? 20 : 36,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
          )
        else
          SizedBox(
            width: compact ? 20 : 24,
            height: compact ? 20 : 24,
            child: CircularProgressIndicator(
              strokeWidth: compact ? 2 : 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        SizedBox(height: compact ? 6 : 16),
        Text(
          _title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w500,
            color: fg.withValues(alpha: 0.85),
          ),
        ),
        if (!compact && phase == _SquareLoadPhase.locating) ...[
          const SizedBox(height: 6),
          Text(
            '用于展示动态与你的距离',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: fg.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Center(child: content),
      );
    }
    return Center(child: content);
  }
}

/// 关注 Tab 统一发现空态（游客与已登录空列表共用，无 action 按钮）。
class UcgFollowingDiscoveryEmpty extends StatelessWidget {
  const UcgFollowingDiscoveryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcgEmptyState(
      icon: Icons.people_outline_rounded,
      title: '还没有关注的人',
      subtitle: '去推荐看看，点击动态中的头像进入主页，关注你感兴趣的人',
    );
  }
}

class UcgSquareTab extends ConsumerStatefulWidget {
  const UcgSquareTab({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  ConsumerState<UcgSquareTab> createState() => _UcgSquareTabState();
}

class _UcgSquareTabState extends ConsumerState<UcgSquareTab> {
  _SquareFeedMode _mode = _SquareFeedMode.recommended;
  final _items = <UcgPost>[];
  String? _nextCursor;
  var _hasMore = true;
  var _loading = false;
  var _pullRefreshing = false;
  var _loadPhase = _SquareLoadPhase.idle;
  var _initialLoaded = false;
  var _emptyAutoRetryUsed = false;
  String? _error;
  double? _followingLat;
  double? _followingLng;
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
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    // 内容未超出视口时不触发分页，避免 maxScrollExtent≈0 时反复 loadMore。
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(_load(refresh: false));
    }
  }

  Future<void> _load({required bool refresh, bool fromPullRefresh = false}) async {
    if (_loading) return;
    if (_mode == _SquareFeedMode.following && !ref.read(sessionProvider).isLoggedIn) return;
    final pullRefresh = fromPullRefresh && _initialLoaded;
    setState(() {
      _loading = true;
      _pullRefreshing = pullRefresh;
      if (pullRefresh) {
        _loadPhase = _SquareLoadPhase.idle;
      } else {
        _loadPhase = refresh ? _SquareLoadPhase.locating : _SquareLoadPhase.fetchingFeed;
      }
      _error = null;
      if (refresh) {
        _nextCursor = null;
        _hasMore = true;
        if (fromPullRefresh) {
          _emptyAutoRetryUsed = false;
        }
      }
    });
    try {
      final repo = ref.read(ucgRepositoryProvider);
      final sw = Stopwatch()..start();
      if (_mode == _SquareFeedMode.recommended) {
        ({double lat, double lng})? coords;
        if (refresh) {
          coords = await ensureUcgLocationForDistance(context, ref);
          if (!mounted) return;
          if (!_pullRefreshing) {
            setState(() => _loadPhase = _SquareLoadPhase.fetchingFeed);
          }
        }
        final result = await repo.fetchRecommendedFeed(
          cursor: refresh ? null : _nextCursor,
          lat: coords?.lat,
          lng: coords?.lng,
        );
        sw.stop();
        if (!mounted) return;
        setState(() {
          if (refresh) _items.clear();
          _items.addAll(result.items);
          _nextCursor = result.nextCursor;
          _hasMore = result.hasMore;
          _initialLoaded = true;
        });
        if (refresh &&
            result.items.isEmpty &&
            !result.hasMore &&
            sw.elapsed.inSeconds < 3 &&
            !_emptyAutoRetryUsed) {
          _emptyAutoRetryUsed = true;
          unawaited(
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (mounted) unawaited(_load(refresh: true));
            }),
          );
        }
      } else {
        final page = refresh ? 1 : (_items.length ~/ kUcgPageSize) + 1;
        if (refresh) {
          final coords = await ensureUcgLocationForDistance(context, ref);
          if (!mounted) return;
          if (!_pullRefreshing) {
            setState(() => _loadPhase = _SquareLoadPhase.fetchingFeed);
          }
          _followingLat = coords?.lat;
          _followingLng = coords?.lng;
        }
        final result = await repo.fetchFollowingFeed(
          page: page,
          lat: _followingLat,
          lng: _followingLng,
        );
        if (!mounted) return;
        setState(() {
          if (refresh) _items.clear();
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _initialLoaded = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadPhase = _SquareLoadPhase.idle;
          _pullRefreshing = false;
        });
      }
    }
  }

  Future<void> _onModeChanged(_SquareFeedMode mode) async {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    await _load(refresh: true);
  }

  void _openDetail(UcgPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UcgPostDetailScreen(postId: post.id, seedPost: post),
      ),
    );
  }

  void _openUserProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UcgUserProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _toggleLikeOnPost(UcgPost post) async {
    if (post.isDebate) return;
    if (!await requireUcgWxAccount(context, ref)) return;
    final idx = _items.indexWhere((p) => p.id == post.id);
    if (idx < 0) return;
    final liked = post.likedByMe;
    final optimistic = post.copyWith(
      likedByMe: !liked,
      likeCount: (post.likeCount + (liked ? -1 : 1)).clamp(0, 1 << 30),
    );
    setState(() => _items[idx] = optimistic);
    try {
      final repo = ref.read(ucgRepositoryProvider);
      if (liked) {
        await repo.unlikePost(post.id, post: post);
      } else {
        await repo.likePost(post.id, post: post);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _items[idx] = post);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请稍后重试')),
      );
    }
  }

  Future<void> _voteOnPost(UcgPost post, String side) async {
    if (!await requireUcgWxAccount(context, ref)) return;
    try {
      await ref.read(ucgRepositoryProvider).votePost(post.id, side: side);
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((p) => p.id == post.id);
        if (idx < 0) return;
        var left = post.leftVoteCount;
        var right = post.rightVoteCount;
        final prev = post.myVoteSide;
        if (prev == 'left') left = (left - 1).clamp(0, 1 << 30);
        if (prev == 'right') right = (right - 1).clamp(0, 1 << 30);
        if (side == 'left') {
          left += 1;
        } else {
          right += 1;
        }
        _items[idx] = post.copyWith(
          myVoteSide: side,
          leftVoteCount: left,
          rightVoteCount: right,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投票失败，请稍后重试')),
      );
    }
  }

  void _onPostCommentAdded(String postId, UcgComment added) {
    setState(() {
      final idx = _items.indexWhere((p) => p.id == postId);
      if (idx < 0) return;
      final post = _items[idx];
      _items[idx] = post.copyWith(commentCount: post.commentCount + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(ucgPostsChangedProvider, (previous, next) {
      if (next > 0 && previous != next) {
        unawaited(_load(refresh: true));
      }
    });

    final fg = AppColor.textPrimary(context);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UcgLocationSettingsHint(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(refresh: true, fromPullRefresh: true),
              child: _buildBody(fg, loggedIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _followingEmptyList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        UcgFollowingDiscoveryEmpty(),
      ],
    );
  }

  Widget _buildBody(Color fg, bool loggedIn) {
    if (_mode == _SquareFeedMode.following && !loggedIn) {
      return _followingEmptyList();
    }
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
    if (!_initialLoaded && _loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: _SquareLoadStatusPanel(phase: _loadPhase, mode: _mode),
          ),
        ],
      );
    }
    if (_initialLoaded && _items.isEmpty) {
      if (_mode == _SquareFeedMode.following) {
        return _followingEmptyList();
      }
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
    final selfId = ref.watch(ucgCurrentUserIdProvider);
    final showLoadFooter =
        _loading && !_pullRefreshing && _loadPhase == _SquareLoadPhase.fetchingFeed;
    final itemCount = _items.length + (showLoadFooter ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading && !_pullRefreshing && _loadPhase != _SquareLoadPhase.idle)
          _SquareLoadStatusPanel(phase: _loadPhase, mode: _mode, compact: true),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _SquareLoadStatusPanel(
                            phase: _loadPhase,
                            mode: _mode,
                            compact: true,
                          ),
                        );
                      }
                      final post = _items[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < _items.length - 1 ? 10 : 0),
                        child: post.isDebate
                            ? UcgDebateFeedCard(
                                post: post,
                                currentUserId: selfId,
                                onAvatarTap: () => _openUserProfile(post.authorId),
                                onUserTap: _openUserProfile,
                                onVote: (side) => unawaited(_voteOnPost(post, side)),
                                onCommentAdded: (added) async =>
                                    _onPostCommentAdded(post.id, added),
                              )
                            : UcgMasonryFeedCard(
                                post: post,
                                currentUserId: selfId,
                                onTap: () => _openDetail(post),
                                onAvatarTap: () => _openUserProfile(post.authorId),
                                onLikeTap: () => unawaited(_toggleLikeOnPost(post)),
                              ),
                      );
                    },
                    childCount: itemCount,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
    final fg = AppColor.textPrimary(context);
    final time = DateFormat('MM-dd HH:mm').format(post.displayAt.toLocal());
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
    return UcgSurfaceCard(child: content);
  }
}
