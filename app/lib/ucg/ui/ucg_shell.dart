import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exceptions.dart';
import '../../providers/session_provider.dart';
import '../../session/token_expiry.dart';
import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import '../data/ucg_media_picker.dart';
import 'ucg_compose_screen.dart';
import 'ucg_login_gate.dart';
import 'ucg_messages_tab.dart';
import 'ucg_profile_screens.dart' show UcgFollowListScreen;
import 'ucg_square_tab.dart';
import '../theme/ucg_theme.dart';
import 'ucg_post_detail_screen.dart';
import 'widgets/ucg_my_post_timeline_item.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_profile_header.dart';
import 'widgets/ucg_visual_widgets.dart';

class UcgShell extends ConsumerStatefulWidget {
  const UcgShell({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  ConsumerState<UcgShell> createState() => _UcgShellState();
}

class _UcgShellState extends ConsumerState<UcgShell> {
  var _tabIndex = 0;

  int get _stackIndex {
    if (_tabIndex <= 1) return _tabIndex;
    if (_tabIndex == 3) return 2;
    if (_tabIndex == 4) return 3;
    return 0;
  }

  void _onTabTap(int index) {
    if (index == 2) {
      unawaited(_openCompose());
      return;
    }
    setState(() => _tabIndex = index);
    if (index == 3) {
      final wxId = ref.read(ucgCurrentUserIdProvider);
      if (isUcgWxAccountBound(wxId)) {
        ref.read(ucgRepositoryProvider).setWsConnectionDesired(true);
        bumpUcgConversationsRefresh(ref);
      }
    } else if (index == 4) {
      ref.invalidate(ucgMyProfileProvider);
    } else {
      ref.read(ucgRepositoryProvider).setWsConnectionDesired(false);
    }
  }

  Future<void> _openCompose({UcgPost? editing}) async {
    if (!await requireUcgWxAccount(context, ref)) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => UcgComposeScreen(editingPost: editing)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(ucgUnreadCountProvider) > 0;
    final back = widget.onBackToFeeding;

    return UcgScaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: [
          UcgSquareTab(onBackToFeeding: back),
          UcgTreasurePlaceholder(onBackToFeeding: back),
          UcgMessagesTab(onBackToFeeding: back),
          UcgProfileTab(onBackToFeeding: back),
        ],
      ),
      bottomNavigationBar: UcgGlassBottomDock(
        currentIndex: _tabIndex,
        showMessageBadge: unread,
        onTap: _onTabTap,
        onComposeTap: () => unawaited(_openCompose()),
      ),
    );
  }
}

class UcgProfileTab extends ConsumerWidget {
  const UcgProfileTab({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.isLoggedIn) {
      return UcgTabPage(
        title: '',
        showTitle: false,
        leading: ucgBackLeading(context, onBackToFeeding),
        body: const UcgLoginPrompt(message: '登录后查看我的'),
      );
    }

    final wxId = ref.watch(ucgCurrentUserIdProvider);
    final wxBound = isUcgWxAccountBound(wxId);
    final profileAsync = ref.watch(ucgMyProfileProvider);
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return UcgTabPage(
      title: '',
      showTitle: false,
      leading: ucgBackLeading(context, onBackToFeeding),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => UcgProfileLoadError(
          onRetry: () => ref.invalidate(ucgMyProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return UcgProfileLoadError(
              onRetry: () => ref.invalidate(ucgMyProfileProvider),
            );
          }
          return DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      if (!wxBound) ...[
                        UcgShellGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '绑定微信后可发帖、互动与私信',
                                  style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.75), height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      UcgShellGlassCard(
                        child: _MyProfileHeaderCard(
                          profile: profile,
                          wxBound: wxBound,
                          primary: primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TabBar(
                        labelColor: primary,
                        unselectedLabelColor: fg.withValues(alpha: 0.5),
                        indicatorColor: primary,
                        tabs: const [
                          Tab(text: '我的动态'),
                          Tab(text: '我的宝藏'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _MyPostsSection(wxBound: wxBound),
                      const _MyTreasureTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyProfileHeaderCard extends ConsumerStatefulWidget {
  const _MyProfileHeaderCard({
    required this.profile,
    required this.wxBound,
    required this.primary,
  });

  final UcgProfile profile;
  final bool wxBound;
  final Color primary;

  @override
  ConsumerState<_MyProfileHeaderCard> createState() => _MyProfileHeaderCardState();
}

class _MyProfileHeaderCardState extends ConsumerState<_MyProfileHeaderCard> {
  var _editingNickname = false;
  var _editingBio = false;
  var _saving = false;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.profile.nickname);
    _bioCtrl = TextEditingController(text: widget.profile.bio);
  }

  @override
  void didUpdateWidget(covariant _MyProfileHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingNickname && oldWidget.profile.nickname != widget.profile.nickname) {
      _nicknameCtrl.text = widget.profile.nickname;
    }
    if (!_editingBio && oldWidget.profile.bio != widget.profile.bio) {
      _bioCtrl.text = widget.profile.bio;
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _commitNickname() async {
    final next = _nicknameCtrl.text.trim();
    setState(() => _editingNickname = false);
    if (next == widget.profile.nickname) return;
    await _saveProfile(nickname: next);
  }

  Future<void> _commitBio() async {
    final next = _bioCtrl.text.trim();
    setState(() => _editingBio = false);
    if (next == widget.profile.bio) return;
    await _saveProfile(bio: next);
  }

  Future<void> _startNicknameEdit() async {
    if (!await _ensureWxBound()) return;
    if (!mounted) return;
    setState(() => _editingNickname = true);
  }

  Future<void> _startBioEdit() async {
    if (!await _ensureWxBound()) return;
    if (!mounted) return;
    setState(() => _editingBio = true);
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;

    if (_editingNickname) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nicknameCtrl,
            autofocus: true,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: '昵称',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: _saving ? null : () => unawaited(_commitNickname()),
              ),
            ),
            onSubmitted: (_) => unawaited(_commitNickname()),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcgProfileHeader(
          avatar: _ProfileAvatarPicker(
            profile: widget.profile,
            wxBound: widget.wxBound,
            primary: widget.primary,
          ),
          nickname: widget.profile.nickname,
          bio: _editingBio ? null : (widget.profile.bio.isNotEmpty ? widget.profile.bio : null),
          bioPlaceholder: '点击编辑个人简介',
          onBioTap: _editingBio || _saving ? null : () => unawaited(_startBioEdit()),
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
        if (_editingBio) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            autofocus: true,
            enabled: !_saving,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '介绍一下你和宝宝吧…',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: _saving ? null : () => unawaited(_commitBio()),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileAvatarPicker extends ConsumerStatefulWidget {
  const _ProfileAvatarPicker({
    required this.profile,
    required this.wxBound,
    required this.primary,
  });

  final UcgProfile profile;
  final bool wxBound;
  final Color primary;

  @override
  ConsumerState<_ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends ConsumerState<_ProfileAvatarPicker> {
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
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _uploading ? null : () => unawaited(_pickAvatar()),
        customBorder: const CircleBorder(),
        child: Stack(
          alignment: Alignment.center,
          children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.primary.withValues(alpha: 0.35), width: 2),
            ),
            child: UcgAvatar(
              radius: 40,
              url: widget.profile.avatarUrl,
              backgroundColor: widget.primary.withValues(alpha: 0.12),
              foregroundColor: widget.primary,
              placeholderIcon: Icons.face_retouching_natural_rounded,
              placeholderIconSize: 40,
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
          else
            Positioned(
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.primary,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.camera_alt_rounded, size: 14, color: UcgTheme.onPrimary(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyTreasureTab extends StatelessWidget {
  const _MyTreasureTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: UcgEmptyState(
        icon: Icons.diamond_outlined,
        title: '尚未开通',
        subtitle: '我们正在筹备宝藏内容\n敬请期待',
      ),
    );
  }
}

class _MyPostsSection extends ConsumerStatefulWidget {
  const _MyPostsSection({required this.wxBound});

  final bool wxBound;

  @override
  ConsumerState<_MyPostsSection> createState() => _MyPostsSectionState();
}

class _MyPostsSectionState extends ConsumerState<_MyPostsSection> {
  static const _listPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

  Future<void> _refresh() => ref.refresh(ucgMyPostsProvider.future);

  Widget _timelineItem(BuildContext context, List<UcgPost> posts, int i) {
    return UcgMyPostTimelineItem(
      key: ValueKey(posts[i].id),
      post: posts[i],
      showDateColumn: i == 0 ||
          !UcgMyPostTimelineItem.isSameCalendarDay(
            posts[i].createdAt.toLocal(),
            posts[i - 1].createdAt.toLocal(),
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
    if (!widget.wxBound) {
      return const UcgEmptyState(
        icon: Icons.edit_note_rounded,
        title: '绑定微信后查看动态',
        subtitle: '与喂养模块共用同一账号，绑定后即可发帖',
      );
    }

    final postsAsync = ref.watch(ucgMyPostsProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
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
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: UcgEmptyState(
                      icon: Icons.edit_note_rounded,
                      title: '还没有发布动态',
                      subtitle: '点击底部 + 分享第一条育儿日常吧',
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
  }
}
