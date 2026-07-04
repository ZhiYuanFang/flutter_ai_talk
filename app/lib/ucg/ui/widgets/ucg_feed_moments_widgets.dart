import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_visual_tokens.dart';
import '../../data/ucg_models.dart';
import '../../providers/ucg_providers.dart';
import 'ucg_media_viewer.dart';
import 'ucg_network_image.dart';

const _kMediaGap = 3.0;
const _kMediaRadius = 4.0;
const kUcgEngagementMaxLines = 1;
const kUcgEngagementLineHeight = 1.35;
const _kEngagementMaxLines = kUcgEngagementMaxLines;
const _kEngagementLineHeight = kUcgEngagementLineHeight;
const _kLikerAvatarSize = 19.0; // 28 × 2/3
const _kLikerAvatarRadius = 5.0;
const _kLikerAvatarGap = 2.0;

/// 我的动态审核状态：头像行右侧水平角标（pending/rejected 半透明分态色）。
class UcgPostAuditBadge extends StatelessWidget {
  const UcgPostAuditBadge({super.key, required this.post});

  final UcgPost post;

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(post);
    if (label.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final (bg, border, fg) = switch (post.status) {
      UcgPostStatus.pendingAudit => (
          scheme.primary.withValues(alpha: 0.22),
          scheme.primary.withValues(alpha: 0.5),
          scheme.primary,
        ),
      UcgPostStatus.rejected => (
          scheme.error.withValues(alpha: 0.22),
          scheme.error.withValues(alpha: 0.5),
          scheme.error,
        ),
      _ => (
          scheme.primary.withValues(alpha: 0.22),
          scheme.primary.withValues(alpha: 0.5),
          scheme.primary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, height: 1.2),
      ),
    );
  }

  static String _labelFor(UcgPost post) {
    return switch (post.status) {
      UcgPostStatus.pendingAudit => '审核中',
      UcgPostStatus.rejected => '已下架',
      _ => '',
    };
  }

  static bool visibleFor(UcgPost post) =>
      post.status == UcgPostStatus.pendingAudit || post.status == UcgPostStatus.rejected;
}

/// 广场 Feed 帖子 meta：`MM-dd HH:mm · 属地 · 距离`（缺项省略）。
String ucgPostFeedMetaLine(UcgPost post, String time, {String? currentUserId}) {
  final loc = post.ipLocationDisplay;
  final dist = post.shouldShowDistance(currentUserId) ? post.distanceDisplay : '';
  if (loc.isNotEmpty && dist.isNotEmpty) return '$time · $loc · $dist';
  if (loc.isNotEmpty) return '$time · $loc';
  if (dist.isNotEmpty) return '$time · $dist';
  return time;
}

/// 帖子图片/视频区，供广场 Feed 与「我的动态」时间轴复用。
class UcgPostMediaSection extends StatelessWidget {
  const UcgPostMediaSection({
    super.key,
    required this.post,
    this.topSpacing = 10,
    this.openLightboxOnTap = true,
    this.maxPreviewImages,
    this.onVideoTap,
  });

  final UcgPost post;
  final double topSpacing;
  final bool openLightboxOnTap;
  /// 非 null 时广场预览：最多展示 N 张横排图，超出在第 N 张标 +剩余数。
  final int? maxPreviewImages;
  /// 视频预览点击（广场 moment 卡可进详情；profile 不传则走外层 InkWell）。
  final VoidCallback? onVideoTap;

  @override
  Widget build(BuildContext context) {
    if (post.imageUrls.isEmpty && post.videoUrl == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (post.imageUrls.isNotEmpty) ...[
          SizedBox(height: topSpacing),
          if (maxPreviewImages != null)
            UcgSquareFeedMediaPreview(
              post: post,
              maxImages: maxPreviewImages!,
              openLightboxOnTap: openLightboxOnTap,
              onVideoTap: onVideoTap,
            )
          else
            UcgMomentsMediaGrid(
              fullUrls: post.imageUrls,
              thumbnailUrls: post.imageThumbnailUrls,
              openLightboxOnTap: openLightboxOnTap,
            ),
        ] else if (post.videoUrl != null) ...[
          SizedBox(height: topSpacing),
          if (maxPreviewImages != null)
            UcgSquareFeedMediaPreview(
              post: post,
              maxImages: maxPreviewImages!,
              openLightboxOnTap: openLightboxOnTap,
              onVideoTap: onVideoTap,
            )
          else
            UcgMomentsVideoTile(
              videoUrl: post.videoUrl!,
              posterUrl: post.videoThumbnailUrl,
              videoWidth: post.videoWidth,
              videoHeight: post.videoHeight,
            ),
        ],
      ],
    );
  }
}

/// 广场纵向 Feed 媒体预览：最多 [maxImages] 张横排；超出时末格角标 +剩余数。
class UcgSquareFeedMediaPreview extends StatelessWidget {
  const UcgSquareFeedMediaPreview({
    super.key,
    required this.post,
    this.maxImages = 3,
    this.openLightboxOnTap = false,
    this.onVideoTap,
  });

  final UcgPost post;
  final int maxImages;
  final bool openLightboxOnTap;
  final VoidCallback? onVideoTap;

  String _thumbnailAt(int index) {
    final thumbs = post.imageThumbnailUrls;
    if (index < thumbs.length && thumbs[index].isNotEmpty) {
      return thumbs[index];
    }
    return post.imageUrls[index];
  }

  Widget _wrapTap(Widget child, VoidCallback? onTap) {
    if (onTap == null) return child;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  void _openLightbox(BuildContext context, int index) {
    final urls = post.imageUrls;
    unawaited(
      showUcgPhotoLightbox(
        context,
        urls: urls,
        thumbnailUrls: List.generate(urls.length, _thumbnailAt),
        initialIndex: index.clamp(0, urls.length - 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (post.videoUrl != null) {
      return _wrapTap(
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: UcgVideoSnapshotPoster(
              posterUrl: post.videoThumbnailUrl,
              videoUrl: post.videoUrl,
              aspectRatio: 16 / 9,
              borderRadius: 8,
            ),
          ),
        ),
        onVideoTap,
      );
    }

    final urls = post.imageUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    final total = urls.length;
    final showCount = total.clamp(1, maxImages);
    final overflow = total > maxImages ? total - maxImages : 0;

    Widget cell(int index, {required int overflowBadge}) {
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            UcgNetworkImage(url: _thumbnailAt(index), fit: BoxFit.cover),
            if (overflowBadge > 0)
              Positioned(
                right: 6,
                bottom: 6,
                child: _FeedOverflowBadge(count: overflowBadge),
              ),
          ],
        ),
      );
      return _wrapTap(
        image,
        openLightboxOnTap ? () => _openLightbox(context, index) : null,
      );
    }

    if (showCount == 1) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth / 3;
          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: size,
              height: size,
              child: cell(0, overflowBadge: overflow),
            ),
          );
        },
      );
    }

    return Row(
      children: [
        for (var i = 0; i < showCount; i++) ...[
          if (i > 0) const SizedBox(width: _kMediaGap),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: cell(
                i,
                overflowBadge: i == showCount - 1 ? overflow : 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeedOverflowBadge extends StatelessWidget {
  const _FeedOverflowBadge({required this.count});

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
        '+$count',
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

/// WeChat Moments 风格图片九宫格。
class UcgMomentsMediaGrid extends StatelessWidget {
  const UcgMomentsMediaGrid({
    super.key,
    required this.fullUrls,
    this.thumbnailUrls,
    this.openLightboxOnTap = true,
    this.onImageTap,
  });

  final List<String> fullUrls;
  /// 与 [fullUrls] 等长；缺失时回退全分辨率 URL。
  final List<String>? thumbnailUrls;
  final bool openLightboxOnTap;
  final void Function(int index)? onImageTap;

  String _thumbnailAt(int index) {
    final thumbs = thumbnailUrls;
    if (thumbs != null && index < thumbs.length && thumbs[index].isNotEmpty) {
      return thumbs[index];
    }
    return fullUrls[index];
  }

  @override
  Widget build(BuildContext context) {
    if (fullUrls.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final count = fullUrls.length.clamp(1, 9);

        final double gridWidth;
        final int crossAxisCount;
        if (count == 1) {
          gridWidth = containerWidth * 3 / 5;
          crossAxisCount = 1;
        } else if (count == 2) {
          gridWidth = containerWidth * 2 / 3;
          crossAxisCount = 2;
        } else {
          gridWidth = containerWidth;
          crossAxisCount = 3;
        }

        final cellSize =
            (gridWidth - _kMediaGap * (crossAxisCount - 1)) / crossAxisCount;
        final rows = (count + crossAxisCount - 1) ~/ crossAxisCount;
        final gridHeight = cellSize * rows + _kMediaGap * (rows - 1);

        return SizedBox(
          width: gridWidth,
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: _kMediaGap,
              mainAxisSpacing: _kMediaGap,
              childAspectRatio: 1,
            ),
            itemCount: count,
            itemBuilder: (_, i) {
              final image = ClipRRect(
                borderRadius: BorderRadius.circular(_kMediaRadius),
                child: UcgNetworkImage(url: _thumbnailAt(i), fit: BoxFit.cover),
              );
              final hasTapHandler = onImageTap != null || openLightboxOnTap;
              if (!hasTapHandler) return image;

              return GestureDetector(
                onTap: () {
                  if (onImageTap != null) {
                    onImageTap!(i);
                    return;
                  }
                  showUcgPhotoLightbox(
                    context,
                    urls: fullUrls,
                    thumbnailUrls: List.generate(fullUrls.length, _thumbnailAt),
                    initialIndex: i,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: image,
              );
            },
          ),
        );
      },
    );
  }
}

/// 视频缩略：竖屏 3/5 宽，横屏全宽；点击内联播放，控件含全屏展开。
class UcgMomentsVideoTile extends StatefulWidget {
  const UcgMomentsVideoTile({
    super.key,
    required this.videoUrl,
    this.posterUrl,
    this.videoWidth,
    this.videoHeight,
  });

  final String videoUrl;
  final String? posterUrl;
  final int? videoWidth;
  final int? videoHeight;

  @override
  State<UcgMomentsVideoTile> createState() => _UcgMomentsVideoTileState();
}

class _UcgMomentsVideoTileState extends State<UcgMomentsVideoTile> {
  var _playing = false;

  bool get _isPortrait {
    if (widget.videoWidth != null &&
        widget.videoHeight != null &&
        widget.videoWidth! > 0) {
      return widget.videoHeight! > widget.videoWidth!;
    }
    return true;
  }

  double get _aspectRatio {
    if (widget.videoWidth != null &&
        widget.videoHeight != null &&
        widget.videoWidth! > 0 &&
        widget.videoHeight! > 0) {
      return widget.videoWidth! / widget.videoHeight!;
    }
    return _isPortrait ? 9 / 16 : 16 / 9;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final displayWidth =
            _isPortrait ? containerWidth * 3 / 5 : containerWidth;

        return SizedBox(
          width: displayWidth,
          child: _playing
              ? UcgInlineVideoPlayer(
                  videoUrl: widget.videoUrl,
                  posterUrl: widget.posterUrl,
                  aspectRatio: _aspectRatio,
                  borderRadius: _kMediaRadius,
                )
              : GestureDetector(
                  onTap: () => setState(() => _playing = true),
                  behavior: HitTestBehavior.opaque,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_kMediaRadius),
                    child: AspectRatio(
                      aspectRatio: _aspectRatio,
                      child: UcgVideoSnapshotPoster(
                        posterUrl: widget.posterUrl,
                        videoUrl: widget.videoUrl,
                        aspectRatio: _aspectRatio,
                        borderRadius: _kMediaRadius,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// 右下角双圆点：点击后在左侧弹出 detached 浮层（点赞/评论/删除），点外部收起。
class UcgMomentsActionMenu extends StatefulWidget {
  const UcgMomentsActionMenu({
    super.key,
    required this.likedByMe,
    required this.onLikeTap,
    this.onLikeLongPress,
    this.onCommentTap,
    this.onShareTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  final bool likedByMe;
  final VoidCallback? onLikeTap;
  final VoidCallback? onLikeLongPress;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  @override
  State<UcgMomentsActionMenu> createState() => _UcgMomentsActionMenuState();
}

class _UcgMomentsActionMenuState extends State<UcgMomentsActionMenu>
    with SingleTickerProviderStateMixin {
  static const _kMoreBtnSize = 28.0;
  static const _kFloatGap = 8.0;

  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  var _expanded = false;
  var _isDisposing = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fadeAnim = curved;
    _slideAnim = Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero).animate(curved);
    _controllerListener = () {
      final entry = _overlayEntry;
      if (entry != null && entry.mounted) {
        entry.markNeedsBuild();
      }
    };
    _controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _isDisposing = true;
    _controller.removeListener(_controllerListener);
    _controller.stop();
    _removeOverlay(immediate: true);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_expanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _expand() {
    if (_expanded || _isDisposing) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    if (!mounted) return;
    setState(() => _expanded = true);
    _overlayEntry = _buildOverlayEntry();
    overlay.insert(_overlayEntry!);
    unawaited(_controller.forward(from: 0));
  }

  void _collapse() {
    if (!_expanded || _isDisposing) return;
    unawaited(_controller.reverse().then((_) {
      if (!mounted || _isDisposing) return;
      _removeOverlay();
      setState(() => _expanded = false);
    }));
  }

  void _removeOverlay({bool immediate = false}) {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      if (entry.mounted) {
        entry.remove();
      }
      entry.dispose();
    }
    if (immediate) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  OverlayEntry _buildOverlayEntry() {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final pillBg = tokens?.pillBackground ?? fg.withValues(alpha: 0.08);

    return OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _collapse,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.centerLeft,
              followerAnchor: Alignment.centerRight,
              offset: const Offset(-_kFloatGap, 0),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Material(
                    elevation: 2,
                    color: pillBg,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onLikeTap != null)
                            _ActionIcon(
                              icon: widget.likedByMe
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: '点赞',
                              color: widget.likedByMe ? primary : fg.withValues(alpha: 0.75),
                              onTap: () {
                                _collapse();
                                widget.onLikeTap?.call();
                              },
                              onLongPress: widget.onLikeLongPress,
                            ),
                          if (widget.onCommentTap != null)
                            _ActionIcon(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: '评论',
                              color: fg.withValues(alpha: 0.75),
                              onTap: () {
                                _collapse();
                                widget.onCommentTap?.call();
                              },
                            ),
                          if (widget.onShareTap != null)
                            _ActionIcon(
                              icon: Icons.ios_share_rounded,
                              label: '分享',
                              color: fg.withValues(alpha: 0.75),
                              onTap: () {
                                _collapse();
                                widget.onShareTap?.call();
                              },
                            ),
                          if (widget.onEditTap != null)
                            _ActionIcon(
                              icon: Icons.edit_outlined,
                              label: '编辑',
                              color: fg.withValues(alpha: 0.75),
                              onTap: () {
                                _collapse();
                                widget.onEditTap?.call();
                              },
                            ),
                          if (widget.onDeleteTap != null)
                            _ActionIcon(
                              icon: Icons.delete_outline_rounded,
                              label: '删除',
                              color: fg.withValues(alpha: 0.75),
                              onTap: () {
                                _collapse();
                                widget.onDeleteTap?.call();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onLikeTap == null &&
        widget.onCommentTap == null &&
        widget.onShareTap == null &&
        widget.onEditTap == null &&
        widget.onDeleteTap == null) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: _kMoreBtnSize,
            height: _kMoreBtnSize,
            child: Center(
              child: _TwoDotMoreIcon(color: fg.withValues(alpha: 0.85)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 横向排列的两个圆点，用作「更多」入口。
class _TwoDotMoreIcon extends StatelessWidget {
  const _TwoDotMoreIcon({required this.color});

  final Color color;

  static const _dotSize = 5.0;
  static const _gap = 5.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(),
        const SizedBox(width: _gap),
        _dot(),
      ],
    );
  }

  Widget _dot() {
    return Container(
      width: _dotSize,
      height: _dotSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 点赞摘要 + 评论列表（微信朋友圈灰底块）。
class UcgMomentsEngagementBlock extends ConsumerStatefulWidget {
  const UcgMomentsEngagementBlock({
    super.key,
    required this.post,
    this.onCommentTap,
    this.onReplyToComment,
    this.onUserTap,
  });

  final UcgPost post;
  final VoidCallback? onCommentTap;
  final void Function(UcgComment comment)? onReplyToComment;
  final void Function(String userId)? onUserTap;

  @override
  ConsumerState<UcgMomentsEngagementBlock> createState() => _UcgMomentsEngagementBlockState();
}

class _UcgMomentsEngagementBlockState extends ConsumerState<UcgMomentsEngagementBlock> {
  var _loadingComments = false;
  var _commentsLoaded = false;
  var _comments = <UcgComment>[];
  var _loadingLikers = false;
  var _likersLoaded = false;
  var _likers = <UcgLiker>[];
  var _expanded = false;
  var _loadCommentsFailed = false;
  var _loadLikersFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.likeCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_loadLikers()));
    }
    _seedCommentsFromPost();
    if (widget.post.commentCount > 0 && !_commentsLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_loadComments()));
    }
  }

  void _seedCommentsFromPost() {
    if (widget.post.comments.isEmpty) return;
    _comments = List<UcgComment>.from(widget.post.comments);
    _commentsLoaded = true;
  }

  @override
  void didUpdateWidget(covariant UcgMomentsEngagementBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _comments = [];
      _commentsLoaded = false;
      _loadCommentsFailed = false;
      _likers = [];
      _likersLoaded = false;
      _loadLikersFailed = false;
      _expanded = false;
      if (widget.post.likeCount > 0) {
        unawaited(_loadLikers());
      }
      _seedCommentsFromPost();
      if (widget.post.commentCount > 0 && !_commentsLoaded) {
        unawaited(_loadComments());
      }
    } else {
      if (widget.post.likeCount != oldWidget.post.likeCount) {
        if (widget.post.likeCount <= 0) {
          _likers = [];
          _likersLoaded = false;
          _loadLikersFailed = false;
        } else if (!_likersLoaded) {
          unawaited(_loadLikers());
        } else {
          unawaited(_loadLikers(force: true));
        }
      }
      if (widget.post.commentCount > oldWidget.post.commentCount) {
        if (!_commentsLoaded) {
          unawaited(_loadComments());
        } else if (widget.post.commentCount > _comments.length) {
          unawaited(_loadComments(force: true));
        }
      }
    }
  }

  Future<void> _loadLikers({bool force = false}) async {
    if (_loadingLikers || (_likersLoaded && !force)) return;
    if (widget.post.likeCount <= 0) return;
    setState(() {
      _loadingLikers = true;
      if (force) _likersLoaded = false;
    });
    try {
      final list = await ref.read(ucgRepositoryProvider).fetchPostLikes(widget.post.id);
      if (!mounted) return;
      setState(() {
        _likers = list;
        _likersLoaded = true;
        _loadLikersFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadLikersFailed = true);
    } finally {
      if (mounted) setState(() => _loadingLikers = false);
    }
  }

  Future<void> _loadComments({bool force = false}) async {
    if (_loadingComments || (_commentsLoaded && !force)) return;
    setState(() {
      _loadingComments = true;
      if (force) _commentsLoaded = false;
    });
    try {
      final result = await ref.read(ucgRepositoryProvider).fetchComments(widget.post.id);
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

  bool get _hasLikes => widget.post.likeCount > 0;
  bool get _hasComments => widget.post.commentCount > 0 || _comments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasLikes && !_hasComments && !_loadingComments && !_loadingLikers) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = fg.withValues(alpha: 0.06);

    final likeLine = _hasLikes
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _kLikerAvatarSize,
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _loadingLikers && !_likersLoaded
                    ? SizedBox(
                        height: _kLikerAvatarSize,
                        width: _kLikerAvatarSize,
                        child: Center(
                          child: SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      )
                    : _loadLikersFailed
                        ? GestureDetector(
                            onTap: () => unawaited(_loadLikers()),
                            child: Text(
                              '${widget.post.likeCount} 人（点击重试）',
                              style: TextStyle(
                                fontSize: 13,
                                color: primary.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                height: _kEngagementLineHeight,
                              ),
                            ),
                          )
                        : _likers.isNotEmpty
                            ? Wrap(
                                spacing: _kLikerAvatarGap,
                                runSpacing: _kLikerAvatarGap,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: [
                                  for (final liker in _likers)
                                    _LikerAvatarChip(
                                      liker: liker,
                                      onTap: widget.onUserTap == null
                                          ? null
                                          : () => widget.onUserTap!(liker.wxId),
                                    ),
                                ],
                              )
                            : Text(
                                '${widget.post.likeCount} 人',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primary.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  height: _kEngagementLineHeight,
                                ),
                              ),
              ),
            ],
          )
        : null;

    Widget? commentsBlock;
    if (_loadingComments && !_commentsLoaded) {
      commentsBlock = Padding(
        padding: EdgeInsets.only(top: _hasLikes ? 6 : 0),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: fg.withValues(alpha: 0.4)),
        ),
      );
    } else if (_loadCommentsFailed && _hasComments) {
      commentsBlock = Padding(
        padding: EdgeInsets.only(top: _hasLikes ? 6 : 0),
        child: GestureDetector(
          onTap: () => unawaited(_loadComments()),
          child: Text(
            '评论加载失败，点击重试',
            style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
          ),
        ),
      );
    } else if (_comments.isNotEmpty) {
      commentsBlock = _CommentsList(
        comments: _comments,
        expanded: _expanded,
        fg: fg,
        onReplyToComment: widget.onReplyToComment,
        onUserTap: widget.onUserTap,
      );
    } else if (_hasComments && _commentsLoaded) {
      commentsBlock = Padding(
        padding: EdgeInsets.only(top: _hasLikes ? 6 : 0),
        child: Text(
          '${widget.post.commentCount} 条评论',
          style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.55)),
        ),
      );
    }

    final needsExpand = _comments.length > _kEngagementMaxLines;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likeLine != null) likeLine,
          if (commentsBlock != null) commentsBlock,
          if (needsExpand)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () {
                  if (!_expanded && widget.post.commentCount > _comments.length) {
                    unawaited(_loadComments(force: true).then((_) {
                      if (mounted) setState(() => _expanded = true);
                    }));
                    return;
                  }
                  setState(() => _expanded = !_expanded);
                },
                child: Text(
                  _expanded ? '折叠' : '展开',
                  style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.45)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LikerAvatarChip extends StatelessWidget {
  const _LikerAvatarChip({
    required this.liker,
    this.onTap,
  });

  final UcgLiker liker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(_kLikerAvatarRadius),
      child: SizedBox(
        width: _kLikerAvatarSize,
        height: _kLikerAvatarSize,
        child: liker.avatarThumbnailUrl != null
            ? UcgNetworkImage(url: liker.avatarThumbnailUrl!, fit: BoxFit.cover)
            : ColoredBox(
                color: primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, size: 11, color: primary),
              ),
      ),
    );
    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: avatar);
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({
    required this.comments,
    required this.expanded,
    required this.fg,
    this.onReplyToComment,
    this.onUserTap,
  });

  final List<UcgComment> comments;
  final bool expanded;
  final Color fg;
  final void Function(UcgComment comment)? onReplyToComment;
  final void Function(String userId)? onUserTap;

  @override
  Widget build(BuildContext context) {
    final needsCollapse = comments.length > _kEngagementMaxLines;
    final visible = !needsCollapse || expanded
        ? comments
        : comments.take(_kEngagementMaxLines).toList();
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _CommentLine(
              comment: visible[i],
              fg: fg,
              primary: primary,
              expanded: expanded,
              onReplyToComment: onReplyToComment,
              onUserTap: onUserTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentLine extends StatelessWidget {
  const _CommentLine({
    required this.comment,
    required this.fg,
    required this.primary,
    required this.expanded,
    this.onReplyToComment,
    this.onUserTap,
  });

  final UcgComment comment;
  final Color fg;
  final Color primary;
  final bool expanded;
  final void Function(UcgComment comment)? onReplyToComment;
  final void Function(String userId)? onUserTap;

  @override
  Widget build(BuildContext context) {
    final author = comment.authorNickname.isEmpty ? '用户' : comment.authorNickname;
    final labelPrefix = comment.voteSideLabel?.trim();
    final bodyStyle = TextStyle(fontSize: 13, height: _kEngagementLineHeight, color: fg.withValues(alpha: 0.82));
    final authorStyle = TextStyle(
      fontSize: 13,
      height: _kEngagementLineHeight,
      color: primary.withValues(alpha: 0.92),
      fontWeight: FontWeight.w600,
    );
    const avatarSize = 20.0;

    Widget avatar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: comment.authorAvatarThumbnailUrl != null &&
                comment.authorAvatarThumbnailUrl!.isNotEmpty
            ? UcgNetworkImage(url: comment.authorAvatarThumbnailUrl!, fit: BoxFit.cover)
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

    Widget authorWidget = Text(author, style: authorStyle);
    if (onUserTap != null && comment.authorId.isNotEmpty) {
      authorWidget = GestureDetector(
        onTap: () => onUserTap!(comment.authorId),
        behavior: HitTestBehavior.opaque,
        child: authorWidget,
      );
    }

    final spans = <InlineSpan>[
      if (labelPrefix != null && labelPrefix.isNotEmpty)
        TextSpan(text: '【$labelPrefix】', style: bodyStyle),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: authorWidget,
      ),
      TextSpan(text: '：${comment.text}', style: bodyStyle),
    ];

    return GestureDetector(
      onTap: onReplyToComment == null ? null : () => onReplyToComment!(comment),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(children: spans),
              maxLines: expanded ? null : 2,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
