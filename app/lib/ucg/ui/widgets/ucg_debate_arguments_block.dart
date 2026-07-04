import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ucg_models.dart';
import '../../providers/ucg_providers.dart';
import '../ucg_login_gate.dart';
import 'ucg_feed_moments_widgets.dart'
    show kUcgEngagementMaxLines, kUcgEngagementLineHeight;
import 'ucg_feed_fake_glass_panel.dart';
import 'ucg_mention_text.dart';
import 'ucg_network_image.dart';
import 'ucg_post_comment_sheet.dart';

/// 广场辩论卡内联论点：投票后才 mount；lazy fetch v1 评论。
class UcgDebateArgumentsBlock extends ConsumerStatefulWidget {
  const UcgDebateArgumentsBlock({
    super.key,
    required this.post,
    this.onUserTap,
    this.onCommentAdded,
  });

  final UcgPost post;
  final void Function(String userId)? onUserTap;
  final void Function(UcgComment added)? onCommentAdded;

  @override
  ConsumerState<UcgDebateArgumentsBlock> createState() =>
      _UcgDebateArgumentsBlockState();
}

class _UcgDebateArgumentsBlockState
    extends ConsumerState<UcgDebateArgumentsBlock> {
  var _loadingComments = false;
  var _commentsLoaded = false;
  var _comments = <UcgComment>[];
  var _expanded = false;
  var _loadCommentsFailed = false;

  bool get _hasVoted =>
      widget.post.myVoteSide != null && widget.post.myVoteSide!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasVoted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => unawaited(_loadComments()));
    }
  }

  @override
  void didUpdateWidget(covariant UcgDebateArgumentsBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _comments = [];
      _commentsLoaded = false;
      _loadCommentsFailed = false;
      _expanded = false;
      if (_hasVoted) {
        unawaited(_loadComments());
      }
      return;
    }
    final hadVote = oldWidget.post.myVoteSide != null &&
        oldWidget.post.myVoteSide!.isNotEmpty;
    if (!hadVote && _hasVoted) {
      unawaited(_loadComments());
    } else if (_hasVoted &&
        widget.post.commentCount > oldWidget.post.commentCount &&
        !_commentsLoaded) {
      unawaited(_loadComments());
    } else if (_hasVoted &&
        widget.post.commentCount > oldWidget.post.commentCount &&
        _commentsLoaded &&
        widget.post.commentCount > _comments.length) {
      unawaited(_loadComments(force: true));
    }
  }

  Future<void> _loadComments({bool force = false}) async {
    if (!_hasVoted || _loadingComments || (_commentsLoaded && !force)) return;
    setState(() {
      _loadingComments = true;
      if (force) _commentsLoaded = false;
    });
    try {
      final result =
          await ref.read(ucgRepositoryProvider).fetchComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = result.items;
        _commentsLoaded = true;
        _loadCommentsFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadCommentsFailed = true);
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _openComposer(
      {String? initialText, String? hint, String? title}) async {
    if (!await requireUcgWxAccount(context, ref)) return;
    if (!_hasVoted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先投票后再发表论点')),
      );
      return;
    }
    if (!mounted) return;
    await showUcgPostCommentSheet(
      context,
      ref,
      postId: widget.post.id,
      initialText: initialText,
      title: title,
      hint: hint,
      isDebate: widget.post.isDebate,
      myVoteSide: widget.post.myVoteSide,
      onCommentAdded: (added) async {
        if (!mounted) return;
        setState(() {
          final alreadyListed =
              added.id.isNotEmpty && _comments.any((c) => c.id == added.id);
          if (!alreadyListed) {
            _comments = [..._comments, added];
            _commentsLoaded = true;
          }
        });
        widget.onCommentAdded?.call(added);
      },
    );
  }

  Future<void> _replyTo(UcgComment comment) {
    return _openComposer(
      initialText: UcgMentionText.replyWirePrefix(
        comment.authorNickname,
        authorId: comment.authorId,
      ),
      title: '回复论点',
      hint: '回复…',
    );
  }

  bool get _hasComments => widget.post.commentCount > 0 || _comments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasVoted) return const SizedBox.shrink();

    final fg = ucgFeedFakeGlassTextColor(context);
    final primary = Theme.of(context).colorScheme.primary;
    final pillBg = ucgFeedFakeGlassArgumentPillColor(context);

    Widget? commentsBlock;
    if (_loadingComments && !_commentsLoaded) {
      commentsBlock = SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
            strokeWidth: 1.5, color: fg.withValues(alpha: 0.4)),
      );
    } else if (_loadCommentsFailed && _hasComments) {
      commentsBlock = GestureDetector(
        onTap: () => unawaited(_loadComments()),
        child: Text(
          '论点加载失败，点击重试',
          style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
        ),
      );
    } else if (_comments.isNotEmpty) {
      final needsCollapse = _comments.length > kUcgEngagementMaxLines;
      final visible = !needsCollapse || _expanded
          ? _comments
          : _comments.take(kUcgEngagementMaxLines).toList();
      commentsBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _ArgumentRow(
              comment: visible[i],
              fg: fg,
              primary: primary,
              onUserTap: widget.onUserTap,
              onReply: () => unawaited(_replyTo(visible[i])),
            ),
          ],
        ],
      );
    } else if (_hasComments && _commentsLoaded) {
      commentsBlock = Text(
        '${widget.post.commentCount} 条论点',
        style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.55)),
      );
    }

    final hiddenCount = _comments.length > kUcgEngagementMaxLines
        ? _comments.length - kUcgEngagementMaxLines
        : 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius:
            BorderRadius.circular(UcgDebateVisualTokens.argumentPillRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (commentsBlock != null) commentsBlock,
          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () {
                  if (!_expanded &&
                      widget.post.commentCount > _comments.length) {
                    unawaited(_loadComments(force: true).then((_) {
                      if (mounted) setState(() => _expanded = true);
                    }));
                    return;
                  }
                  setState(() => _expanded = !_expanded);
                },
                child: Text(
                  _expanded ? '' : '展开 $hiddenCount 条论点',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
                top: commentsBlock != null || hiddenCount > 0 ? 6 : 0),
            child: GestureDetector(
              onTap: () => unawaited(_openComposer(
                title: '发表论点',
                hint: '说说你的观点…',
              )),
              behavior: HitTestBehavior.opaque,
              child: Text(
                '发表论点',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArgumentRow extends StatelessWidget {
  const _ArgumentRow({
    required this.comment,
    required this.fg,
    required this.primary,
    this.onUserTap,
    required this.onReply,
  });

  final UcgComment comment;
  final Color fg;
  final Color primary;
  final void Function(String userId)? onUserTap;
  final VoidCallback onReply;

  static const _avatarSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final author =
        comment.authorNickname.isEmpty ? '用户' : comment.authorNickname;
    final displayText = UcgMentionText.displayComment(comment.text);
    final labelPrefix = comment.voteSideLabel?.trim();
    final bodyStyle = TextStyle(
        fontSize: 13,
        height: kUcgEngagementLineHeight,
        color: fg.withValues(alpha: 0.82));
    final authorStyle = TextStyle(
      fontSize: 13,
      height: kUcgEngagementLineHeight,
      color: primary.withValues(alpha: 0.92),
      fontWeight: FontWeight.w600,
    );

    Widget avatar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: comment.authorAvatarThumbnailUrl != null &&
                comment.authorAvatarThumbnailUrl!.isNotEmpty
            ? UcgNetworkImage(
                url: comment.authorAvatarThumbnailUrl!, fit: BoxFit.cover)
            : ColoredBox(
                color: primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, size: 12, color: primary),
              ),
      ),
    );
    if (onUserTap != null && comment.authorId.isNotEmpty) {
      avatar = GestureDetector(
        onTap: () => onUserTap!(comment.authorId),
        behavior: HitTestBehavior.opaque,
        child: avatar,
      );
    }

    return GestureDetector(
      onLongPress: onReply,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (labelPrefix != null && labelPrefix.isNotEmpty)
                      TextSpan(text: '【$labelPrefix】', style: bodyStyle),
                    TextSpan(text: author, style: authorStyle),
                    TextSpan(text: '：$displayText', style: bodyStyle),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
