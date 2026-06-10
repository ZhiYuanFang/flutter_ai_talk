import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exceptions.dart';
import '../../theme/app_visual_tokens.dart';
import '../data/ucg_feature_flags.dart';
import '../data/ucg_media_picker.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_login_gate.dart';
import 'ucg_post_detail_screen.dart';
import 'ucg_profile_screens.dart' show UcgFollowListScreen;
import 'widgets/ucg_my_post_timeline_item.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_profile_header.dart';
import '../theme/ucg_theme.dart';
import 'widgets/ucg_visual_widgets.dart';

enum UcgProfileMode { ownerTab, viewerScreen }

enum UcgProfilePostsSource { mine, user }

/// 资料头展开态头像外径（含 ring padding）。
const _kProfileExpandedAvatarOuter = 86.0;
const _kProfileExpandedAvatarRadius = 43.0;
const _kProfileCollapsedAvatarRadius = 16.0;
const _kProfileToolbarHeight = 44.0;

/// 统一资料壳层：折叠顶栏；[`kUcgTreasureEnabled`] 时含「动态」「宝藏」Tab，否则仅动态列表。
class UcgProfileShell extends ConsumerStatefulWidget {
  const UcgProfileShell({
    super.key,
    required this.mode,
    required this.profile,
    required this.postsSource,
    this.postsUserId,
    required this.showOwnerActions,
    this.wxBound = true,
    this.leading,
    this.isFollowing = false,
    this.followBusy = false,
    this.onFollow,
    this.onMessage,
  });

  final UcgProfileMode mode;
  final UcgProfile profile;
  final UcgProfilePostsSource postsSource;
  final String? postsUserId;
  final bool showOwnerActions;
  final bool wxBound;
  final Widget? leading;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;

  @override
  ConsumerState<UcgProfileShell> createState() => _UcgProfileShellState();
}

class _UcgProfileShellState extends ConsumerState<UcgProfileShell> {
  /// 资料卡内边距（[UcgSurfaceCard] 默认 16×2）。
  static const _kProfileCardPadding = 32.0;
  static const _kProfileCardRowHeight = 86.0;
  static const _kProfileCardActionsBlock = 34.0;
  static const _kProfileCardBioBlock = 46.0;

  static double _headerExpandedHeight({
    required bool showOwnerActions,
    required double flexibleTopPad,
    required bool hasViewerActions,
    required bool hasBio,
  }) {
    if (showOwnerActions) return 248.0;
    if (!hasViewerActions) return 228.0;
    final cardHeight = _kProfileCardPadding +
        _kProfileCardRowHeight +
        (hasBio ? _kProfileCardBioBlock : 0) +
        _kProfileCardActionsBlock;
    return _kProfileToolbarHeight + flexibleTopPad + cardHeight;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final shellBg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    final profile = widget.profile;
    final leading = widget.leading;
    final showOwnerActions = widget.showOwnerActions;
    final flexibleTopPad = leading != null ? 32.0 : 4.0;
    final hasViewerActions = !showOwnerActions && widget.onFollow != null;
    final hasBio = profile.bio.trim().isNotEmpty;
    final headerExpandedHeight = _headerExpandedHeight(
      showOwnerActions: showOwnerActions,
      flexibleTopPad: flexibleTopPad,
      hasViewerActions: hasViewerActions,
      hasBio: hasBio,
    );

    final postsTab = UcgProfilePostsTab(
      postsSource: widget.postsSource,
      postsUserId: widget.postsUserId,
      wxBound: widget.wxBound,
      showOwnerActions: showOwnerActions,
    );

    List<Widget> headerSlivers(BuildContext context) {
      final overlapHandle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
      return [
        SliverOverlapAbsorber(
          handle: overlapHandle,
          sliver: SliverPersistentHeader(
            pinned: true,
            delegate: _UcgProfileHeaderDelegate(
              expandedHeight: headerExpandedHeight,
              backgroundColor: shellBg,
              flexibleTopPad: flexibleTopPad,
              showOwnerActions: showOwnerActions,
              profile: profile,
              wxBound: widget.wxBound,
              primary: primary,
              leading: leading,
              isFollowing: widget.isFollowing,
              followBusy: widget.followBusy,
              onFollow: widget.onFollow,
              onMessage: widget.onMessage,
            ),
          ),
        ),
        if (showOwnerActions && !widget.wxBound)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: UcgSurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '绑定微信后可发帖、互动与私信',
                        style: TextStyle(
                          fontSize: 13,
                          color: fg.withValues(alpha: 0.75),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (kUcgTreasureEnabled)
          SliverPersistentHeader(
            pinned: true,
            delegate: _UcgProfileTabBarDelegate(
              TabBar(
                labelColor: primary,
                unselectedLabelColor: fg.withValues(alpha: 0.5),
                indicatorColor: primary,
                tabs: const [
                  Tab(text: '动态'),
                  Tab(text: '宝藏'),
                ],
              ),
              backgroundColor: shellBg,
            ),
          ),
      ];
    }

    final nestedScroll = NestedScrollView(
      // 宝藏关闭时勿 float，避免内层列表浮入资料卡遮挡关注/私信按钮。
      floatHeaderSlivers: kUcgTreasureEnabled,
      headerSliverBuilder: (context, innerBoxIsScrolled) => headerSlivers(context),
      body: kUcgTreasureEnabled
          ? TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                postsTab,
                const UcgProfileTreasureTab(),
              ],
            )
          : postsTab,
    );

    if (!kUcgTreasureEnabled) return nestedScroll;

    // 双 Tab 需 DefaultTabController 与 header TabBar 联动。
    return DefaultTabController(length: 2, child: nestedScroll);
  }
}

/// 随 [shrinkOffset] 每帧更新折叠进度，驱动资料头与头像 morph。
class _UcgProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  _UcgProfileHeaderDelegate({
    required this.expandedHeight,
    required this.backgroundColor,
    required this.flexibleTopPad,
    required this.showOwnerActions,
    required this.profile,
    required this.wxBound,
    required this.primary,
    this.leading,
    required this.isFollowing,
    required this.followBusy,
    this.onFollow,
    this.onMessage,
  });

  final double expandedHeight;
  final Color backgroundColor;
  final double flexibleTopPad;
  final bool showOwnerActions;
  final UcgProfile profile;
  final bool wxBound;
  final Color primary;
  final Widget? leading;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;

  static const _avatarPlaceholder = SizedBox(
    width: _kProfileExpandedAvatarOuter,
    height: _kProfileExpandedAvatarOuter,
  );

  @override
  double get minExtent => _kProfileToolbarHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 0.0;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final expandedCenterX = 16 + 16 + _kProfileExpandedAvatarRadius;
    final cardTop = _kProfileToolbarHeight + flexibleTopPad - shrinkOffset;
    final expandedCenterY = cardTop + 16 + _kProfileExpandedAvatarRadius;
    final collapsedCenterX = screenWidth / 2;
    final collapsedCenterY = _kProfileToolbarHeight / 2;

    final radius = lerpDouble(_kProfileExpandedAvatarRadius, _kProfileCollapsedAvatarRadius, t)!;
    final centerX = lerpDouble(expandedCenterX, collapsedCenterX, t)!;
    final centerY = lerpDouble(expandedCenterY, collapsedCenterY, t)!;
    final innerRadius = (radius - 3).clamp(4.0, 40.0);
    final cardOpacity = (1.0 - t * 1.15).clamp(0.0, 1.0);

    return ColoredBox(
      color: backgroundColor,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          if (cardOpacity > 0.01)
            Positioned(
              top: cardTop,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: cardOpacity,
                child: UcgSurfaceCard(
                  child: showOwnerActions
                      ? UcgProfileOwnerHeaderCard(
                          profile: profile,
                          wxBound: wxBound,
                          primary: primary,
                          avatarPlaceholder: _avatarPlaceholder,
                        )
                      : UcgProfileHeader(
                          avatar: _avatarPlaceholder,
                          nickname: profile.nickname,
                          bio: profile.bio.isNotEmpty ? profile.bio : null,
                          followingCount: profile.followingCount,
                          ipLocationText: profile.ipLocationDisplay,
                          actions: onFollow != null
                              ? UcgProfileActionRow(
                                  isFollowing: isFollowing,
                                  followBusy: followBusy,
                                  onFollow: onFollow,
                                  onMessage: onMessage,
                                )
                              : null,
                        ),
                ),
              ),
            ),
          Positioned(
            left: centerX - radius,
            top: centerY - radius,
            width: radius * 2,
            height: radius * 2,
            child: IgnorePointer(
              ignoring: t > 0.85,
              child: showOwnerActions && t < 0.85
                  ? _UcgProfileAvatarPicker(
                      profile: profile,
                      wxBound: wxBound,
                      primary: primary,
                      displayRadius: innerRadius,
                      showCameraBadge: t < 0.25,
                    )
                  : _UcgProfileMorphAvatarRing(
                      avatarUrl: profile.avatarUrl,
                      primary: primary,
                      radius: innerRadius,
                      borderWidth: t > 0.5 ? 1.5 : 2,
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _kProfileToolbarHeight,
            child: Row(
              children: [
                if (leading != null) leading!,
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _UcgProfileHeaderDelegate oldDelegate) =>
      expandedHeight != oldDelegate.expandedHeight ||
      backgroundColor != oldDelegate.backgroundColor ||
      flexibleTopPad != oldDelegate.flexibleTopPad ||
      showOwnerActions != oldDelegate.showOwnerActions ||
      profile != oldDelegate.profile ||
      wxBound != oldDelegate.wxBound ||
      primary != oldDelegate.primary ||
      leading != oldDelegate.leading ||
      isFollowing != oldDelegate.isFollowing ||
      followBusy != oldDelegate.followBusy ||
      onFollow != oldDelegate.onFollow ||
      onMessage != oldDelegate.onMessage;
}

class _UcgProfileMorphAvatarRing extends StatelessWidget {
  const _UcgProfileMorphAvatarRing({
    required this.avatarUrl,
    required this.primary,
    required this.radius,
    this.borderWidth = 2,
  });

  final String? avatarUrl;
  final Color primary;
  final double radius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(borderWidth > 1.75 ? 2 : 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primary.withValues(alpha: 0.35), width: borderWidth),
      ),
      child: UcgAvatar(
        radius: radius,
        url: avatarUrl,
        backgroundColor: primary.withValues(alpha: 0.12),
        foregroundColor: primary,
        placeholderIcon: Icons.face_retouching_natural_rounded,
        placeholderIconSize: radius,
      ),
    );
  }
}

class _UcgProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  _UcgProfileTabBarDelegate(this.tabBar, {required this.backgroundColor});

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _UcgProfileTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
}

/// 宝藏 Tab 占位。
class UcgProfileTreasureTab extends StatelessWidget {
  const UcgProfileTreasureTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: UcgEmptyState(
                  icon: Icons.diamond_outlined,
                  title: '尚未开通',
                  subtitle: '我们正在筹备宝藏内容\n敬请期待',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class UcgProfilePostsTab extends ConsumerStatefulWidget {
  const UcgProfilePostsTab({
    super.key,
    required this.postsSource,
    this.postsUserId,
    required this.wxBound,
    required this.showOwnerActions,
  });

  final UcgProfilePostsSource postsSource;
  final String? postsUserId;
  final bool wxBound;
  final bool showOwnerActions;

  @override
  ConsumerState<UcgProfilePostsTab> createState() => _UcgProfilePostsTabState();
}

class _UcgProfilePostsTabState extends ConsumerState<UcgProfilePostsTab> {
  static const _listPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

  Future<void> _refresh() {
    if (widget.postsSource == UcgProfilePostsSource.mine) {
      return ref.refresh(ucgMyPostsProvider.future);
    }
    final userId = widget.postsUserId;
    if (userId == null || userId.isEmpty) return Future.value();
    return ref.refresh(ucgUserPostsProvider(userId).future);
  }

  Widget _timelineItem(BuildContext context, List<UcgPost> posts, int i) {
    return UcgMyPostTimelineItem(
      key: ValueKey(posts[i].id),
      post: posts[i],
      showDateColumn: i == 0 ||
          !UcgMyPostTimelineItem.isSameCalendarDay(
            posts[i].displayAt.toLocal(),
            posts[i - 1].displayAt.toLocal(),
          ),
      showDivider: i < posts.length - 1,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => UcgPostDetailScreen(
              postId: posts[i].id,
              seedPost: posts[i],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showOwnerActions && !widget.wxBound) {
      return Builder(
        builder: (context) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: UcgEmptyState(
                  icon: Icons.edit_note_rounded,
                  title: '绑定微信后查看动态',
                  subtitle: '与喂养模块共用同一账号，绑定后即可发帖',
                ),
              ),
            ],
          );
        },
      );
    }

    final AsyncValue<List<UcgPost>> postsAsync;
    if (widget.postsSource == UcgProfilePostsSource.mine) {
      postsAsync = ref.watch(ucgMyPostsProvider);
    } else {
      final userId = widget.postsUserId ?? '';
      postsAsync = ref.watch(ucgUserPostsProvider(userId));
    }

    return Builder(
      builder: (context) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: _listPadding,
                sliver: postsAsync.when(
                  skipLoadingOnReload: true,
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: UcgEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: '加载失败',
                      subtitle: '下拉刷新重试',
                      action: TextButton(
                        onPressed: () => unawaited(_refresh()),
                        child: const Text('重试'),
                      ),
                    ),
                  ),
                  data: (posts) {
                    if (posts.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: UcgEmptyState(
                          icon: Icons.edit_note_rounded,
                          title: widget.showOwnerActions ? '还没有发布动态' : '暂无已发布动态',
                          subtitle: widget.showOwnerActions
                              ? '点击底部 + 分享第一条育儿日常吧'
                              : '该用户还没有发布内容',
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _timelineItem(context, posts, i),
                        childCount: posts.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class UcgProfileOwnerHeaderCard extends ConsumerStatefulWidget {
  const UcgProfileOwnerHeaderCard({
    super.key,
    required this.profile,
    required this.wxBound,
    required this.primary,
    this.avatarPlaceholder,
  });

  final UcgProfile profile;
  final bool wxBound;
  final Color primary;
  final Widget? avatarPlaceholder;

  @override
  ConsumerState<UcgProfileOwnerHeaderCard> createState() => _UcgProfileOwnerHeaderCardState();
}

class _UcgProfileOwnerHeaderCardState extends ConsumerState<UcgProfileOwnerHeaderCard> {
  var _saving = false;

  Future<bool> _ensureWxBound() async {
    if (widget.wxBound) return true;
    return requireUcgWxAccount(context, ref);
  }

  Future<void> _saveProfile({String? nickname, String? bio}) async {
    if (!await _ensureWxBound()) return;
    setState(() => _saving = true);
    try {
      await ref.read(ucgRepositoryProvider).updateMyProfile(
            widget.profile.copyWith(
              nickname: nickname ?? widget.profile.nickname,
              bio: bio ?? widget.profile.bio,
            ),
          );
      ref.invalidate(ucgMyProfileProvider);
    } on ApiBusinessException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openFieldEditSheet({
    required String title,
    required String hint,
    required String scene,
    required String initialText,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    required Future<void> Function(String text) onSaved,
  }) async {
    if (!await _ensureWxBound()) return;
    if (!mounted) return;
    final result = await showModalBottomSheet<String>(
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
          child: UcgProfileFieldEditSheet(
            title: title,
            hint: hint,
            scene: scene,
            initialText: initialText,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            busy: _saving,
          ),
        );
      },
    );
    if (result == null || !mounted) return;
    await onSaved(result);
  }

  Future<void> _startNicknameEdit() async {
    await _openFieldEditSheet(
      title: '编辑昵称',
      hint: '昵称',
      scene: 'ucg.profile.nickname',
      initialText: widget.profile.nickname,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n\r]'))],
      onSaved: (text) async {
        final next = text.replaceAll(RegExp(r'[\n\r]'), '').trim();
        if (next == widget.profile.nickname) return;
        await _saveProfile(nickname: next);
      },
    );
  }

  Future<void> _startBioEdit() async {
    await _openFieldEditSheet(
      title: '编辑简介',
      hint: '介绍一下你和宝宝吧…',
      scene: 'ucg.profile.bio',
      initialText: widget.profile.bio,
      maxLines: 5,
      onSaved: (text) async {
        final next = text.trim();
        if (next == widget.profile.bio) return;
        await _saveProfile(bio: next);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcgProfileHeader(
          avatar: widget.avatarPlaceholder ??
              _UcgProfileAvatarPicker(
                profile: widget.profile,
                wxBound: widget.wxBound,
                primary: widget.primary,
              ),
          nickname: widget.profile.nickname,
          bio: widget.profile.bio.isNotEmpty ? widget.profile.bio : null,
          bioPlaceholder: '点击编辑个人简介',
          onBioTap: _saving ? null : () => unawaited(_startBioEdit()),
          followingCount: widget.profile.followingCount,
          onFollowingTap: widget.wxBound
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const UcgFollowListScreen()),
                  );
                }
              : () => unawaited(requireUcgWxAccount(context, ref)),
          ipLocationText: widget.profile.ipLocationDisplay,
          nicknameTrailing: IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: fg.withValues(alpha: 0.45)),
            tooltip: '编辑昵称',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            onPressed: _saving ? null : () => unawaited(_startNicknameEdit()),
          ),
        ),
      ],
    );
  }
}

class _UcgProfileAvatarPicker extends ConsumerStatefulWidget {
  const _UcgProfileAvatarPicker({
    required this.profile,
    required this.wxBound,
    required this.primary,
    this.displayRadius = 40,
    this.showCameraBadge = true,
  });

  final UcgProfile profile;
  final bool wxBound;
  final Color primary;
  final double displayRadius;
  final bool showCameraBadge;

  @override
  ConsumerState<_UcgProfileAvatarPicker> createState() => _UcgProfileAvatarPickerState();
}

class _UcgProfileAvatarPickerState extends ConsumerState<_UcgProfileAvatarPicker> {
  var _uploading = false;

  Future<void> _pickAvatar() async {
    if (!widget.wxBound) {
      if (!await requireUcgWxAccount(context, ref)) return;
      if (!mounted) return;
    }
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final repo = ref.read(ucgRepositoryProvider);
      final upload = await ucgPickAndUploadSingleImage(repo: repo);
      if (upload == null || !mounted) return;
      await repo.updateMyProfile(
        widget.profile.copyWith(avatarKey: upload.objectKey),
      );
      ref.invalidate(ucgMyProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更新失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.displayRadius;
    final borderPad = radius >= 30 ? 3.0 : 2.0;
    final badgeSize = radius >= 30 ? 14.0 : 10.0;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _uploading ? null : () => unawaited(_pickAvatar()),
        customBorder: const CircleBorder(),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.all(borderPad),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.primary.withValues(alpha: 0.35), width: 2),
              ),
              child: UcgAvatar(
                radius: radius,
                url: widget.profile.avatarUrl,
                backgroundColor: widget.primary.withValues(alpha: 0.12),
                foregroundColor: widget.primary,
                placeholderIcon: Icons.face_retouching_natural_rounded,
                placeholderIconSize: radius,
              ),
            ),
            if (_uploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: UcgTheme.scrim(context)),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: UcgTheme.onPrimary(context),
                    ),
                  ),
                ),
              )
            else if (widget.showCameraBadge)
              Positioned(
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(badgeSize * 0.28),
                    child: Icon(Icons.camera_alt_rounded, size: badgeSize, color: UcgTheme.onPrimary(context)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
