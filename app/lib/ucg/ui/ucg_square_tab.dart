import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../../ui/home_history_edit_glass_panel.dart';
import '../../ui/widgets/app_glass_overlay.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_login_gate.dart';
import 'ucg_profile_screens.dart';
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 120) {
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

  Future<void> _toggleLike(UcgPost post) async {
    if (!await requireUcgLogin(context, ref)) return;
    final repo = ref.read(ucgRepositoryProvider);
    final liked = post.likedByMe;
    try {
      if (liked) {
        await repo.unlikePost(post.id);
      } else {
        await repo.likePost(post.id);
      }
      if (!mounted) return;
      setState(() {
        final i = _items.indexWhere((e) => e.id == post.id);
        if (i >= 0) {
          _items[i] = post.copyWith(
            likedByMe: !liked,
            likeCount: post.likeCount + (liked ? -1 : 1),
          );
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));

    return UcgTabPage(
      title: '广场',
      subtitle: '看看大家的育儿日常',
      leading: ucgBackLeading(context, widget.onBackToFeeding),
      headerBottom: Center(
        child: UcgSegmentedPills<_SquareFeedMode>(
          segments: const [_SquareFeedMode.recommended, _SquareFeedMode.following],
          selected: _mode,
          labelBuilder: (m) => m == _SquareFeedMode.recommended ? '推荐' : '关注',
          onSelected: (m) {
            if (m == _SquareFeedMode.following && !loggedIn) {
              setState(() => _mode = m);
              return;
            }
            unawaited(_onModeChanged(m));
          },
        ),
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
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _items.length + (_loading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final post = _items[index];
        return UcgFeedCard(
          post: post,
          onLikeTap: () => _toggleLike(post),
          onLikeLongPress: post.likedByMe ? () => _toggleLike(post) : null,
          onAvatarTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UcgUserProfileScreen(userId: post.authorId),
              ),
            );
          },
          onCommentTap: () async {
            if (!await requireUcgLogin(context, ref)) return;
            if (!context.mounted) return;
            await showGlassAdaptiveBottomSheet<void>(
              context: context,
              maxHeightFraction: 0.72,
              bodyBuilder: (ctx) => _CommentsSheetBody(postId: post.id),
            );
          },
        );
      },
    );
  }
}

class UcgFeedCard extends StatelessWidget {
  const UcgFeedCard({
    super.key,
    required this.post,
    this.onAvatarTap,
    this.onLikeTap,
    this.onLikeLongPress,
    this.onCommentTap,
    this.showStatusBanner = false,
  });

  final UcgPost post;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onLikeLongPress;
  final VoidCallback? onCommentTap;
  final bool showStatusBanner;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final time = DateFormat('MM-dd HH:mm').format(post.createdAt.toLocal());

    return UcgShellGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStatusBanner) _statusBanner(context, post),
          Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: primary.withValues(alpha: 0.12),
                    backgroundImage:
                        post.authorAvatarUrl != null ? NetworkImage(post.authorAvatarUrl!) : null,
                    child: post.authorAvatarUrl == null
                        ? Icon(Icons.person_rounded, size: 20, color: primary)
                        : null,
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
                    Text(time, style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.48))),
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
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MediaGrid(urls: post.imageUrls),
          ],
          if (post.videoUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary.withValues(alpha: 0.12), primary.withValues(alpha: 0.04)],
                    ),
                  ),
                  child: Center(child: Icon(Icons.play_circle_filled_rounded, color: primary, size: 48)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              UcgInteractionChip(
                icon: post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: '${post.likeCount}',
                active: post.likedByMe,
                onTap: onLikeTap,
                onLongPress: onLikeLongPress,
              ),
              const SizedBox(width: 10),
              UcgInteractionChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.commentCount}',
                onTap: onCommentTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(BuildContext context, UcgPost post) {
    final fg = Theme.of(context).colorScheme.error;
    final label = switch (post.status) {
      UcgPostStatus.pendingAudit => '审核中',
      UcgPostStatus.rejected => '违规已下架${post.rejectReason != null ? '：${post.rejectReason}' : ''}',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final count = urls.length.clamp(1, 9);
    final cross = count == 1 ? 1 : (count <= 4 ? 2 : 3);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: count,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(urls[i], fit: BoxFit.cover),
      ),
    );
  }
}

class _CommentsSheetBody extends ConsumerStatefulWidget {
  const _CommentsSheetBody({required this.postId});

  final String postId;

  @override
  ConsumerState<_CommentsSheetBody> createState() => _CommentsSheetBodyState();
}

class _CommentsSheetBodyState extends ConsumerState<_CommentsSheetBody> {
  final _controller = TextEditingController();
  var _loading = true;
  var _comments = <UcgComment>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(ucgRepositoryProvider).fetchComments(widget.postId);
      if (mounted) setState(() => _comments = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final c = await ref.read(ucgRepositoryProvider).addComment(widget.postId, text);
    _controller.clear();
    if (mounted) setState(() => _comments = [..._comments, c]);
  }

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '评论',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: glassText),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary))
              : _comments.isEmpty
                  ? Center(child: Text('还没有评论', style: TextStyle(color: glassLabel)))
                  : ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.authorNickname, style: TextStyle(color: glassText, fontWeight: FontWeight.w600)),
                          subtitle: Text(c.text, style: TextStyle(color: glassLabel)),
                          trailing: c.isMine
                              ? IconButton(
                                  icon: Icon(Icons.delete_outline, color: glassLabel),
                                  onPressed: () async {
                                    await ref.read(ucgRepositoryProvider).deleteComment(widget.postId, c.id);
                                    if (mounted) setState(() => _comments.removeAt(i));
                                  },
                                )
                              : null,
                        );
                      },
                    ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: glassText),
                decoration: historyEditGlassInputDecoration(context, labelText: '写评论…'),
              ),
            ),
            IconButton(onPressed: _send, icon: Icon(Icons.send_rounded, color: scheme.primary)),
          ],
        ),
      ],
    );
  }
}
