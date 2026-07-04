import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/ucg_models.dart';
import 'ucg_debate_arguments_block.dart';
import 'ucg_debate_vs_bar.dart';
import 'ucg_feed_fake_glass_panel.dart';
import 'ucg_feed_moments_widgets.dart';
import 'ucg_force_tier_icon.dart';
import 'ucg_network_image.dart';

/// 广场辩论卡片：作者 + 话题正文 + VS 条 + 时间/属地 + 内联论点（不跳转详情）。
class UcgDebateFeedCard extends ConsumerWidget {
  const UcgDebateFeedCard({
    super.key,
    required this.post,
    this.onAvatarTap,
    this.onUserTap,
    this.onVote,
    this.onCommentAdded,
    this.currentUserId,
  });

  final UcgPost post;
  final VoidCallback? onAvatarTap;
  final void Function(String userId)? onUserTap;
  final ValueChanged<String>? onVote;
  final void Function(UcgComment added)? onCommentAdded;
  final String? currentUserId;

  String get _topicText {
    final t = post.text.trim();
    return t;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = ucgFeedFakeGlassTextColor(context);
    final primary = Theme.of(context).colorScheme.primary;
    final time = DateFormat('MM-dd HH:mm').format(post.displayAt.toLocal());
    final meta = ucgPostFeedMetaLine(post, time, currentUserId: currentUserId);
    final bio = post.authorBio.trim();

    return UcgFeedFakeGlassPanel(
      contentPadding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                behavior: HitTestBehavior.opaque,
                child: UcgAvatar(
                  radius: 18,
                  url: post.authorAvatarThumbnailUrl,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  foregroundColor: primary,
                  placeholderIconSize: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorNickname.isEmpty ? '用户' : post.authorNickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: fg,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (post.authorForceValue >= 500) ...[
                          const SizedBox(width: 4),
                          UcgForceTierIcon(
                            forceValue: post.authorForceValue,
                            forceTier: post.authorForceTier,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: fg.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _topicText.isNotEmpty ? _topicText : '（暂无话题文案）',
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 1.45,
              color: _topicText.isNotEmpty ? fg.withValues(alpha: 0.92) : fg.withValues(alpha: 0.45),
            ),
          ),
          UcgPostMediaSection(
            post: post,
            topSpacing: 8,
            openLightboxOnTap: true,
            maxPreviewImages: 3,
          ),
          const SizedBox(height: 12),
          UcgDebateVsBar(
            leftLabel: post.debateLeft,
            rightLabel: post.debateRight,
            leftRatio: post.debateLeftRatio,
            rightRatio: post.debateRightRatio,
            totalVotes: post.leftVoteCount + post.rightVoteCount,
            myVoteSide: post.myVoteSide,
            interactive: onVote != null,
            onVote: onVote,
          ),
          const SizedBox(height: 8),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.42)),
          ),
          if (post.myVoteSide != null && post.myVoteSide!.isNotEmpty)
            UcgDebateArgumentsBlock(
              post: post,
              onUserTap: onUserTap,
              onCommentAdded: onCommentAdded,
            ),
        ],
      ),
    );
  }
}
