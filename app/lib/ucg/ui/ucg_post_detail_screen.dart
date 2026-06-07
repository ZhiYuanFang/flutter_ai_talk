import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_visual_tokens.dart';
import '../../ui/home_history_edit_glass_panel.dart';
import '../../ui/widgets/app_glass_overlay.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import '../theme/ucg_theme.dart';
import 'ucg_login_gate.dart';
import 'ucg_profile_screens.dart';
import 'widgets/ucg_feed_moments_widgets.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

/// 沉浸式帖子详情：模糊背景、全量点赞/评论、长按 @ 回复。
class UcgPostDetailScreen extends ConsumerStatefulWidget {
  const UcgPostDetailScreen({
    super.key,
    required this.postId,
    this.seedPost,
  });

  final String postId;
  final UcgPost? seedPost;

  @override
  ConsumerState<UcgPostDetailScreen> createState() => _UcgPostDetailScreenState();
}

class _UcgPostDetailScreenState extends ConsumerState<UcgPostDetailScreen> {
  UcgPost? _post;
  List<UcgLiker> _likers = const [];
  List<UcgComment> _comments = const [];
  var _authorFollowing = false;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.seedPost;
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = _post == null;
      _error = null;
    });
    try {
      final repo = ref.read(ucgRepositoryProvider);
      final post = await repo.fetchPost(widget.postId);
      final likers = await repo.fetchPostLikes(widget.postId);
      final comments = await repo.fetchComments(widget.postId);
      var following = false;
      final selfId = ref.read(ucgCurrentUserIdProvider);
      if (selfId != null &&
          selfId.isNotEmpty &&
          post.authorId.isNotEmpty &&
          post.authorId != selfId) {
        final profile = await repo.fetchProfile(post.authorId);
        following = profile?.isFollowing ?? false;
      }
      if (!mounted) return;
      setState(() {
        _post = post;
        _likers = likers;
        _comments = comments;
        _authorFollowing = following;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null) return;
    if (!await requireUcgWxAccount(context, ref)) return;
    final repo = ref.read(ucgRepositoryProvider);
    final liked = post.likedByMe;
    try {
      if (liked) {
        await repo.unlikePost(post.id);
      } else {
        await repo.likePost(post.id);
      }
      final likers = await repo.fetchPostLikes(post.id);
      if (!mounted) return;
      setState(() {
        _post = post.copyWith(
          likedByMe: !liked,
          likeCount: post.likeCount + (liked ? -1 : 1),
        );
        _likers = likers;
      });
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final post = _post;
    if (post == null || post.authorId.isEmpty) return;
    if (!await requireUcgWxAccount(context, ref)) return;
    final repo = ref.read(ucgRepositoryProvider);
    try {
      if (_authorFollowing) {
        await repo.unfollowUser(post.authorId);
      } else {
        await repo.followUser(post.authorId);
      }
      if (!mounted) return;
      setState(() => _authorFollowing = !_authorFollowing);
    } catch (_) {}
  }

  String _mentionPrefix(String nickname, {String? authorId}) {
    final nick = nickname.trim().isEmpty ? '用户' : nickname.trim();
    final id = authorId?.trim() ?? '';
    if (id.isNotEmpty) {
      return '@$nick#$id ';
    }
    return '@$nick ';
  }

  /// 评论展示时隐藏 @昵称#wxId 中的 wxId 后缀。
  String _displayCommentText(String text) {
    return text.replaceAll(RegExp(r'@([^\s@]+?)#\d+'), r'@$1');
  }

  Future<void> _openCommentSheet({String? initialText}) async {
    if (!await requireUcgWxAccount(context, ref)) return;
    if (!mounted) return;
    await showGlassAdaptiveBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.42,
      scrollable: false,
      respectKeyboardInset: true,
      bodyBuilder: (ctx) => _DetailCommentSheet(
        postId: widget.postId,
        initialText: initialText,
        onCommentAdded: () async {
          final comments = await ref.read(ucgRepositoryProvider).fetchComments(widget.postId);
          if (!mounted) return;
          setState(() {
            _comments = comments;
            final post = _post;
            if (post != null) {
              _post = post.copyWith(commentCount: comments.length);
            }
          });
        },
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

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除动态'),
        content: const Text('删除后不可恢复，确定删除这条动态吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(ucgRepositoryProvider).deletePost(widget.postId);
      ref.read(ucgPostsChangedProvider.notifier).state++;
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('已删除')));
      navigator.pop();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('删除失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = ref.watch(ucgCurrentUserIdProvider);
    final post = _post;
    final shellBg = UcgTheme.tokens(context)?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final isAuthor = selfId != null && post != null && post.authorId == selfId;

    if (_loading && post == null) {
      return Scaffold(
        backgroundColor: shellBg,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (post == null) {
      return Scaffold(
        backgroundColor: shellBg,
        body: Center(
          child: UcgEmptyState(
            icon: Icons.cloud_off_rounded,
            title: '加载失败',
            subtitle: _error ?? '帖子不存在',
            action: TextButton(onPressed: _refresh, child: const Text('重试')),
          ),
        ),
      );
    }

    final backdropUrl = post.imageUrls.isNotEmpty
        ? post.imageUrls.first
        : post.authorAvatarUrl;
    final time = DateFormat('MM-dd HH:mm').format(post.createdAt.toLocal());
    final bio = post.authorBio.trim();

    return Scaffold(
      backgroundColor: shellBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (backdropUrl != null)
            UcgNetworkImage(url: backdropUrl, fit: BoxFit.cover)
          else
            ColoredBox(color: shellBg),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(color: shellBg.withValues(alpha: 0.9)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      GestureDetector(
                        onTap: () => _openUserProfile(post.authorId),
                        child: UcgAvatar(
                          radius: 18,
                          url: post.authorAvatarThumbnailUrl,
                          backgroundColor: primary.withValues(alpha: 0.12),
                          foregroundColor: primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openUserProfile(post.authorId),
                          child: Text(
                            post.authorNickname.isEmpty ? '用户' : post.authorNickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, color: fg, fontSize: 15),
                          ),
                        ),
                      ),
                      if (selfId != null && post.authorId != selfId)
                        _FollowPill(
                          following: _authorFollowing,
                          onTap: _toggleFollow,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (bio.isNotEmpty)
                          Text(
                            bio,
                            style: TextStyle(color: fg.withValues(alpha: 0.75), height: 1.45, fontSize: 14),
                          ),
                        if (bio.isNotEmpty) const SizedBox(height: 12),
                        if (post.text.isNotEmpty)
                          Text(
                            post.text,
                            style: TextStyle(color: fg.withValues(alpha: 0.92), height: 1.5, fontSize: 16),
                          ),
                        UcgPostMediaSection(
                          post: post,
                          openLightboxOnTap: true,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              post.ipLocationDisplay.isNotEmpty
                                  ? '$time · ${post.ipLocationDisplay}'
                                  : time,
                              style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.42)),
                            ),
                            const Spacer(),
                            UcgMomentsActionMenu(
                              likedByMe: post.likedByMe,
                              onLikeTap: _toggleLike,
                              onCommentTap: () => unawaited(_openCommentSheet()),
                              onDeleteTap: isAuthor ? _confirmDelete : null,
                            ),
                          ],
                        ),
                        if (_likers.isNotEmpty || post.likedByMe) ...[
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _toggleLike,
                                child: Icon(
                                  post.likedByMe
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 22,
                                  color: post.likedByMe ? primary : fg.withValues(alpha: 0.45),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (final liker in _likers)
                                      GestureDetector(
                                        onTap: liker.wxId.isEmpty
                                            ? null
                                            : () => _openUserProfile(liker.wxId),
                                        behavior: HitTestBehavior.opaque,
                                        child: UcgAvatar(
                                          radius: 14,
                                          url: liker.avatarThumbnailUrl ?? liker.avatarUrl,
                                          backgroundColor: primary.withValues(alpha: 0.1),
                                          foregroundColor: primary,
                                          placeholderIconSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_comments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          for (final comment in _comments)
                            GestureDetector(
                              onLongPress: () => unawaited(
                                _openCommentSheet(
                                  initialText: _mentionPrefix(
                                    comment.authorNickname,
                                    authorId: comment.authorId,
                                  ),
                                ),
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      color: fg.withValues(alpha: 0.88),
                                      height: 1.4,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: GestureDetector(
                                          onTap: comment.authorId.isEmpty
                                              ? null
                                              : () => _openUserProfile(comment.authorId),
                                          behavior: HitTestBehavior.opaque,
                                          child: Text(
                                            comment.authorNickname.isEmpty
                                                ? '用户'
                                                : comment.authorNickname,
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: '：'),
                                      TextSpan(text: _displayCommentText(comment.text)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowPill extends StatelessWidget {
  const _FollowPill({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: following ? Colors.transparent : primary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: following ? primary.withValues(alpha: 0.5) : primary),
        ),
        child: Text(
          following ? '已关注' : '关注',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: following ? primary : UcgTheme.onPrimary(context),
          ),
        ),
      ),
    );
  }
}

class _DetailCommentSheet extends ConsumerStatefulWidget {
  const _DetailCommentSheet({
    required this.postId,
    this.initialText,
    this.onCommentAdded,
  });

  final String postId;
  final String? initialText;
  final VoidCallback? onCommentAdded;

  @override
  ConsumerState<_DetailCommentSheet> createState() => _DetailCommentSheetState();
}

class _DetailCommentSheetState extends ConsumerState<_DetailCommentSheet> {
  late final TextEditingController _controller;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(ucgRepositoryProvider).addComment(widget.postId, text);
      if (!mounted) return;
      widget.onCommentAdded?.call();
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final scheme = Theme.of(context).colorScheme;
    final isReply = widget.initialText != null && widget.initialText!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isReply ? '回复评论' : '写评论',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: glassText),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_sending,
                style: TextStyle(color: glassText),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => unawaited(_send()),
                decoration: historyEditGlassInputDecoration(
                  context,
                  labelText: isReply ? '回复…' : '写评论…',
                ),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : () => unawaited(_send()),
              icon: _sending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                    )
                  : Icon(Icons.send_rounded, color: scheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}
