import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/ucg_models.dart';
import '../../theme/ucg_theme.dart';
import 'ucg_feed_moments_widgets.dart';
import 'ucg_network_image.dart';
import 'ucg_visual_widgets.dart';

/// 广场动态卡片（纵向 Feed 全宽）：头像、文案、最多 3 图预览、meta、点赞。
class UcgMasonryFeedCard extends StatelessWidget {
  const UcgMasonryFeedCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onAvatarTap,
    this.onLikeTap,
    this.currentUserId,
  });

  final UcgPost post;
  final VoidCallback onTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLikeTap;
  /// 当前登录 wxId；用于隐藏本人帖距离。
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final fg = UcgTheme.onRecordsCard(context);
    final primary = Theme.of(context).colorScheme.primary;
    final time = DateFormat('MM-dd HH:mm').format(post.displayAt.toLocal());
    final meta = ucgPostFeedMetaLine(post, time, currentUserId: currentUserId);
    final metaStyle = TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.42));
    final bio = post.authorBio.trim();

    return UcgSurfaceCard(
      padding: const EdgeInsets.all(10),
      borderRadius: 12,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                behavior: HitTestBehavior.opaque,
                child: UcgAvatar(
                  radius: 14,
                  url: post.authorAvatarThumbnailUrl,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  foregroundColor: primary,
                  placeholderIconSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorNickname.isEmpty ? '用户' : post.authorNickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: fg,
                        fontSize: 13,
                      ),
                    ),
                    if (bio.isNotEmpty)
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
                ),
              ),
            ],
          ),
          if (post.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              post.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg.withValues(alpha: 0.88),
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ],
          UcgPostMediaSection(
            post: post,
            topSpacing: 6,
            openLightboxOnTap: true,
            maxPreviewImages: 3,
            onVideoTap: onTap,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metaStyle,
                  ),
                ),
                if (onLikeTap != null)
                  GestureDetector(
                    onTap: onLikeTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        height: 32,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (post.likeCount > 0) ...[
                              Text('${post.likeCount}', style: metaStyle),
                              const SizedBox(width: 2),
                            ],
                            Icon(
                              post.likedByMe
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 22 * 2 / 3,
                              color: post.likedByMe
                                  ? primary
                                  : fg.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
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
