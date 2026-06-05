import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_compose_screen.dart';
import 'ucg_login_gate.dart';
import 'ucg_messages_tab.dart';
import 'ucg_profile_screens.dart';
import 'ucg_square_tab.dart';
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
      ref.read(ucgRepositoryProvider).setWsConnectionDesired(true);
    } else {
      ref.read(ucgRepositoryProvider).setWsConnectionDesired(false);
    }
  }

  Future<void> _openCompose({UcgPost? editing}) async {
    if (!await requireUcgLogin(context, ref)) return;
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
    final profileAsync = ref.watch(ucgMyProfileProvider);
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return UcgTabPage(
      title: '我的',
      subtitle: '记录与分享你的育儿故事',
      leading: ucgBackLeading(context, onBackToFeeding),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => UcgLoginPrompt(
          message: ref.read(sessionProvider).isLoggedIn ? '加载资料失败' : '登录后查看我的',
        ),
        data: (profile) {
          if (profile == null) {
            return const UcgLoginPrompt(message: '登录后查看我的');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              UcgShellGlassCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary.withValues(alpha: 0.35), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        backgroundImage:
                            profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                        child: profile.avatarUrl == null
                            ? Icon(Icons.face_retouching_natural_rounded, color: primary, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.nickname.isEmpty ? '未设置昵称' : profile.nickname,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fg),
                    ),
                    if (profile.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          profile.bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: fg.withValues(alpha: 0.65), height: 1.4),
                        ),
                      ),
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => UcgProfileEditScreen(initial: profile),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primary.withValues(alpha: 0.14),
                        foregroundColor: primary,
                      ),
                      child: const Text('编辑资料'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProfileStatChip(label: '关注', value: '${profile.followingCount}', primary: primary, fg: fg),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProfileStatChip(label: '动态', value: '${profile.postCount}', primary: primary, fg: fg),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              UcgShellGlassCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const UcgFollowListScreen()),
                  );
                },
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.favorite_outline_rounded, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('关注列表', style: TextStyle(color: fg, fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: 0.45)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const UcgSectionLabel(label: '我的动态'),
              const _MyPostsSection(),
              const SizedBox(height: 12),
              UcgShellGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.diamond_outlined, color: fg.withValues(alpha: 0.45), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('我的宝藏', style: TextStyle(color: fg, fontWeight: FontWeight.w500)),
                    ),
                    Text('尚未开通', style: TextStyle(color: fg.withValues(alpha: 0.45), fontSize: 13)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  const _ProfileStatChip({
    required this.label,
    required this.value,
    required this.primary,
    required this.fg,
  });

  final String label;
  final String value;
  final Color primary;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return UcgShellGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _MyPostsSection extends ConsumerStatefulWidget {
  const _MyPostsSection();

  @override
  ConsumerState<_MyPostsSection> createState() => _MyPostsSectionState();
}

class _MyPostsSectionState extends ConsumerState<_MyPostsSection> {
  var _posts = <UcgPost>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final page = await ref.read(ucgRepositoryProvider).fetchMyPosts(page: 1);
      if (mounted) setState(() => _posts = page.items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_posts.isEmpty) {
      return const UcgEmptyState(
        icon: Icons.edit_note_rounded,
        title: '还没有发布动态',
        subtitle: '点击底部 + 分享第一条育儿日常吧',
      );
    }
    return Column(
      children: [
        for (final post in _posts) ...[
          UcgFeedCard(post: post, showStatusBanner: true),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
