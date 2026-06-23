import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import '../theme/ucg_theme.dart';
import 'ucg_compose_screen.dart';
import 'ucg_login_gate.dart';
import 'ucg_profile_screens.dart';
import 'widgets/ucg_feed_moments_widgets.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_mention_composer_field.dart';
import 'widgets/ucg_mention_text.dart';
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
  var _commentsTruncated = false;
  var _authorFollowing = false;
  var _loading = true;
  String? _error;
  final _scrollController = ScrollController();
  final _commentLayerLinks = <String, LayerLink>{};
  final _commentItemKeys = <String, GlobalKey>{};
  OverlayEntry? _commentDeleteOverlay;
  UcgComment? _commentDeleteTarget;
  String? _pendingScrollToCommentId;

  @override
  void initState() {
    super.initState();
    _post = widget.seedPost;
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _removeCommentDeleteOverlay();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _applyCommentsAfterSend(UcgComment added) async {
    if (!mounted) return;
    setState(() {
      final alreadyListed = added.id.isNotEmpty && _comments.any((c) => c.id == added.id);
      if (!alreadyListed) {
        _comments = [..._comments, added];
      }
      final post = _post;
      if (post != null) {
        _post = post.copyWith(commentCount: post.commentCount + 1);
      }
      _pendingScrollToCommentId = added.id.isNotEmpty
          ? added.id
          : (_comments.isNotEmpty ? _comments.last.id : null);
    });
    _scheduleScrollToPendingComment();
  }

  void _scheduleScrollToPendingComment() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToPendingComment();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToPendingComment();
      });
    });
  }

  void _scrollToPendingComment() {
    final id = _pendingScrollToCommentId;
    if (id == null) return;

    final key = _commentItemKeys[id];
    final itemContext = key?.currentContext;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 1.0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      _pendingScrollToCommentId = null;
      return;
    }

    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      if (max.isFinite) {
        _scrollController.jumpTo(max);
      }
    }
  }

  bool _isOwnComment(UcgComment comment) {
    final selfId = ref.read(ucgCurrentUserIdProvider);
    return comment.isMine ||
        (selfId != null && selfId.isNotEmpty && comment.authorId == selfId);
  }

  void _removeCommentDeleteOverlay() {
    final entry = _commentDeleteOverlay;
    _commentDeleteOverlay = null;
    _commentDeleteTarget = null;
    if (entry != null) {
      if (entry.mounted) entry.remove();
      entry.dispose();
    }
  }

  void _showCommentDeleteBar(LayerLink link, UcgComment comment) {
    if (_commentDeleteTarget?.id == comment.id) {
      _removeCommentDeleteOverlay();
      return;
    }
    _removeCommentDeleteOverlay();
    _commentDeleteTarget = comment;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final pillBg = Theme.of(context).extension<AppVisualTokens>()?.pillBackground ??
        fg.withValues(alpha: 0.1);

    _commentDeleteOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeCommentDeleteOverlay,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -6),
              child: Material(
                elevation: 3,
                color: pillBg,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => unawaited(_deleteCommentNow(comment)),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: fg.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: fg.withValues(alpha: 0.75),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_commentDeleteOverlay!);
  }

  Future<void> _deleteCommentNow(UcgComment comment) async {
    _removeCommentDeleteOverlay();
    if (!await requireUcgWxAccount(context, ref)) return;
    try {
      await ref.read(ucgRepositoryProvider).deleteComment(widget.postId, comment.id);
      if (!mounted) return;
      setState(() {
        _comments = _comments.where((c) => c.id != comment.id).toList();
        final post = _post;
        if (post != null) {
          final nextCount = post.commentCount > 0 ? post.commentCount - 1 : 0;
          _post = post.copyWith(commentCount: nextCount);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败')),
        );
      }
    }
  }

  Future<void> _onCommentLongPress(UcgComment comment, LayerLink link) async {
    if (_isOwnComment(comment)) {
      _showCommentDeleteBar(link, comment);
      return;
    }
    _removeCommentDeleteOverlay();
    final selfId = ref.read(ucgCurrentUserIdProvider);
    if (selfId != null &&
        selfId.isNotEmpty &&
        comment.authorId.isNotEmpty &&
        comment.authorId == selfId) {
      return;
    }
    await _openCommentSheet(
      initialText: _mentionPrefix(
        comment.authorNickname,
        authorId: comment.authorId,
      ),
    );
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
      final commentsResult = await repo.fetchComments(widget.postId);
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
        _comments = commentsResult.items;
        _commentsTruncated = commentsResult.truncated;
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
  String _displayCommentText(String text) => UcgMentionText.displayComment(text);

  Future<void> _openCommentSheet({String? initialText}) async {
    _removeCommentDeleteOverlay();
    if (!await requireUcgWxAccount(context, ref)) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: _DetailCommentSheet(
            postId: widget.postId,
            initialText: initialText,
            onCommentAdded: _applyCommentsAfterSend,
          ),
        );
      },
    );
  }

  void _openUserProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UcgUserProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _openEdit() async {
    final post = _post;
    if (post == null) return;
    if (!await requireUcgWxAccount(context, ref)) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UcgComposeScreen(editingPost: post),
      ),
    );
    if (!mounted) return;
    await _refresh();
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

    final backdropUrl = post.imageThumbnailUrls.isNotEmpty
        ? post.imageThumbnailUrls.first
        : post.authorAvatarThumbnailUrl;
    final time = DateFormat('MM-dd HH:mm').format(post.displayAt.toLocal());
    final bio = post.authorBio.trim();

    return Scaffold(
      backgroundColor: shellBg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (backdropUrl != null)
            UcgNetworkImage(url: backdropUrl, fit: BoxFit.cover)
          else
            ColoredBox(color: shellBg),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(color: shellBg.withValues(alpha: 0.7)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                post.authorNickname.isEmpty ? '用户' : post.authorNickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: fg,
                                  fontSize: 15,
                                ),
                              ),
                              if (bio.isNotEmpty)
                                Text(
                                  bio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: fg.withValues(alpha: 0.55),
                                  ),
                                ),
                            ],
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
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (post.text.isNotEmpty)
                          _DetailExpandablePostText(
                            text: post.text,
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.92),
                              height: 1.5,
                              fontSize: 16,
                            ),
                            linkColor: fg.withValues(alpha: 0.45),
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
                              onEditTap: isAuthor ? _openEdit : null,
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
                            CompositedTransformTarget(
                              link: _commentLayerLinks.putIfAbsent(
                                comment.id,
                                LayerLink.new,
                              ),
                              child: KeyedSubtree(
                                key: _commentItemKeys.putIfAbsent(
                                  comment.id,
                                  GlobalKey.new,
                                ),
                                child: GestureDetector(
                                onLongPress: () => unawaited(
                                  _onCommentLongPress(
                                    comment,
                                    _commentLayerLinks[comment.id]!,
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
                              ),
                            ),
                        ],
                        if (_commentsTruncated) ...[
                          const SizedBox(height: 8),
                          Text(
                            '仅显示前 500 条评论',
                            style: TextStyle(
                              fontSize: 12,
                              color: fg.withValues(alpha: 0.45),
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

/// 详情正文：默认最多 5 行，超出显示「展开」（无折叠）。
class _DetailExpandablePostText extends StatefulWidget {
  const _DetailExpandablePostText({
    required this.text,
    required this.style,
    required this.linkColor,
  });

  static const _collapsedMaxLines = 5;

  final String text;
  final TextStyle style;
  final Color linkColor;

  @override
  State<_DetailExpandablePostText> createState() => _DetailExpandablePostTextState();
}

class _DetailExpandablePostTextState extends State<_DetailExpandablePostText> {
  var _expanded = false;

  bool _exceedsCollapsedLines(double width) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: _DetailExpandablePostText._collapsedMaxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: width);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showExpand =
            !_expanded && _exceedsCollapsedLines(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : _DetailExpandablePostText._collapsedMaxLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (showExpand)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '展开',
                    style: TextStyle(fontSize: 13, color: widget.linkColor),
                  ),
                ),
              ),
          ],
        );
      },
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
  final Future<void> Function(UcgComment added)? onCommentAdded;

  @override
  ConsumerState<_DetailCommentSheet> createState() => _DetailCommentSheetState();
}

class _DetailCommentSheetState extends ConsumerState<_DetailCommentSheet> {
  final _composerKey = GlobalKey<UcgMentionComposerFieldWithHighlightState>();
  final _commentPreviewAnchorKey = GlobalKey();
  late final TextEditingController _controller;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = (_composerKey.currentState?.wireText ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final added = await ref.read(ucgRepositoryProvider).addComment(widget.postId, text);
      if (!mounted) return;
      await widget.onCommentAdded?.call(added);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final isReply = widget.initialText != null && widget.initialText!.trim().isNotEmpty;
    final hint = isReply ? '回复…' : '写评论…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isReply ? '回复评论' : '写评论',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
        ),
        const SizedBox(height: 12),
        UcgPageComposerChrome(
          controller: _controller,
          enabled: !_sending,
          busy: _sending,
          confirmLabel: '发送',
          onConfirm: _sending ? null : () => unawaited(_send()),
          padding: EdgeInsets.zero,
          field: UcgMentionComposerFieldWithHighlight(
            key: _composerKey,
            controller: _controller,
            initialWireText: widget.initialText,
            selfWxId: ref.watch(ucgCurrentUserIdProvider),
            autofocus: true,
            enabled: !_sending,
            hint: hint,
            scene: 'ucg.post.comment',
            anchorKey: _commentPreviewAnchorKey,
            onConfirm: _sending ? null : () => unawaited(_send()),
            style: TextStyle(color: fg),
            textInputAction: TextInputAction.newline,
            decoration: ucgComposerFieldDecoration(context, hint: hint),
          ),
        ),
      ],
    );
  }
}
