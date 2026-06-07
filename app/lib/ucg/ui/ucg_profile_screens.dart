import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_visual_tokens.dart';
import '../../providers/session_provider.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_chat_screen.dart';
import 'ucg_login_gate.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_profile_header.dart';
import 'widgets/ucg_visual_widgets.dart';

class UcgUserProfileScreen extends ConsumerStatefulWidget {
  const UcgUserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UcgUserProfileScreen> createState() => _UcgUserProfileScreenState();
}

class _UcgUserProfileScreenState extends ConsumerState<UcgUserProfileScreen> {
  UcgProfile? _profile;
  var _loading = true;
  var _isFollowing = false;
  var _followBusy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final loggedIn = ref.read(sessionProvider).isLoggedIn;
      _profile = await ref.read(ucgRepositoryProvider).fetchProfile(
            widget.userId,
            withAuthorization: loggedIn,
          );
      if (_profile != null) {
        _isFollowing = _profile!.isFollowing;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (!await requireUcgWxAccount(context, ref)) return;
    setState(() => _followBusy = true);
    final repo = ref.read(ucgRepositoryProvider);
    try {
      if (_isFollowing) {
        await repo.unfollowUser(widget.userId);
      } else {
        await repo.followUser(widget.userId);
      }
      ref.invalidate(ucgMyProfileProvider);
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          if (_profile != null) {
            _profile = _profile!.copyWith(isFollowing: _isFollowing);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isFollowing ? '取消关注失败' : '关注失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _startChat() async {
    if (!await requireUcgWxAccount(context, ref)) return;
    try {
      final conv = await ref.read(ucgRepositoryProvider).createConversation(widget.userId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => UcgChatScreen(conversation: conv)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法发起私信')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final mine = ref.watch(ucgCurrentUserIdProvider) == widget.userId;

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: '',
            showTitle: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: fg.withValues(alpha: 0.75)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _profile == null
                    ? const UcgEmptyState(
                        icon: Icons.person_off_outlined,
                        title: '用户不存在',
                        subtitle: '该用户可能已注销或不可见',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          UcgShellGlassCard(
                            child: UcgProfileHeader(
                              avatar: _ProfileAvatarRing(
                                avatarUrl: _profile!.avatarUrl,
                                primary: primary,
                                radius: 42,
                              ),
                              nickname: _profile!.nickname,
                              bio: _profile!.bio.isNotEmpty ? _profile!.bio : null,
                              followingCount: _profile!.followingCount,
                              ipLocationText: _profile!.ipLocationDisplay,
                              actions: !mine
                                  ? UcgProfileActionRow(
                                      isFollowing: _isFollowing,
                                      followBusy: _followBusy,
                                      onFollow: _toggleFollow,
                                      onMessage: _startChat,
                                    )
                                  : null,
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

class UcgFollowListScreen extends ConsumerStatefulWidget {
  const UcgFollowListScreen({super.key});

  @override
  ConsumerState<UcgFollowListScreen> createState() => _UcgFollowListScreenState();
}

class _UcgFollowListScreenState extends ConsumerState<UcgFollowListScreen> {
  var _items = <UcgProfile>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      _items = await ref.read(ucgRepositoryProvider).fetchFollowingList();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: '关注列表',
            subtitle: '你关注的宝妈宝爸',
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: fg.withValues(alpha: 0.75)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _items.isEmpty
                    ? const UcgEmptyState(
                        icon: Icons.favorite_outline_rounded,
                        title: '还没有关注任何人',
                        subtitle: '在广场发现有趣的育儿伙伴吧',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final p = _items[i];
                          return UcgShellGlassCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => UcgUserProfileScreen(userId: p.userId),
                                ),
                              );
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                _ProfileAvatarRing(
                                  avatarUrl: p.avatarThumbnailUrl,
                                  primary: primary,
                                  radius: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.nickname,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: 0.45)),
                              ],
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

class _ProfileAvatarRing extends StatelessWidget {
  const _ProfileAvatarRing({
    required this.avatarUrl,
    required this.primary,
    required this.radius,
  });

  final String? avatarUrl;
  final Color primary;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primary.withValues(alpha: 0.35), width: 2),
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
