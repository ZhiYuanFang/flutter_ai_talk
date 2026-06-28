import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/ucg_models.dart';
import '../../theme/ucg_theme.dart';
import 'ucg_media_viewer.dart';
import 'ucg_network_image.dart';
import 'ucg_visual_widgets.dart';

/// 小红书式双列 Feed 卡片：头像、昵称、bio、媒体、时间、右下点赞数（只读）。
class UcgMasonryFeedCard extends StatelessWidget {
  const UcgMasonryFeedCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onAvatarTap,
    this.currentUserId,
  });

  final UcgPost post;
  final VoidCallback onTap;
  final VoidCallback? onAvatarTap;
  /// 当前登录 wxId；用于隐藏本人帖距离角标。
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final fg = UcgTheme.onRecordsCard(context);
    final primary = Theme.of(context).colorScheme.primary;
    final time = DateFormat('MM-dd HH:mm').format(post.displayAt.toLocal());
    final timeStyle = TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.42));
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
          const SizedBox(height: 6),
          _MasonryMedia(post: post, currentUserId: currentUserId),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(child: Text(time, style: timeStyle)),
                if (post.likeCount > 0) ...[
                  Text('${post.likeCount}', style: timeStyle),
                  const SizedBox(width: 2),
                  Icon(
                    post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 22 * 2 / 3,
                    color: post.likedByMe
                        ? timeStyle.color
                        : fg.withValues(alpha: 0.45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasonryMedia extends StatelessWidget {
  const _MasonryMedia({required this.post, this.currentUserId});

  final UcgPost post;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (post.imageUrls.isNotEmpty) {
      final url = post.imageThumbnailUrls.isNotEmpty
          ? post.imageThumbnailUrls.first
          : post.imageUrls.first;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              UcgNetworkImage(url: url, fit: BoxFit.cover),
              if (post.shouldShowDistance(currentUserId))
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: _DistanceBadge(label: post.distanceDisplay),
                ),
              if (post.imageUrls.length > 1)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _MultiImageCountBadge(count: post.imageUrls.length),
                ),
            ],
          ),
        ),
      );
    }
    if (post.videoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              UcgVideoSnapshotPoster(
                posterUrl: post.videoThumbnailUrl,
                videoUrl: post.videoUrl,
                aspectRatio: 3 / 4,
                borderRadius: 8,
              ),
              if (post.shouldShowDistance(currentUserId))
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: _DistanceBadge(label: post.distanceDisplay),
                ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.92),
          height: 1.2,
        ),
      ),
    );
  }
}

class _MultiImageCountBadge extends StatelessWidget {
  const _MultiImageCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '×$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.92),
          height: 1.2,
        ),
      ),
    );
  }
}
