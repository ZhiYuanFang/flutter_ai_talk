import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_visual_tokens.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_login_gate.dart';
import 'widgets/ucg_visual_widgets.dart';

class UcgProfileEditScreen extends ConsumerStatefulWidget {
  const UcgProfileEditScreen({super.key, required this.initial});

  final UcgProfile initial;

  @override
  ConsumerState<UcgProfileEditScreen> createState() => _UcgProfileEditScreenState();
}

class _UcgProfileEditScreenState extends ConsumerState<UcgProfileEditScreen> {
  late final TextEditingController _nickname;
  late final TextEditingController _bio;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.initial.nickname);
    _bio = TextEditingController(text: widget.initial.bio);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(ucgRepositoryProvider).updateMyProfile(
            UcgProfile(
              userId: widget.initial.userId,
              nickname: _nickname.text.trim(),
              avatarKey: widget.initial.avatarKey,
              bio: _bio.text.trim(),
            ),
          );
      ref.invalidate(ucgMyProfileProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: '编辑资料',
            subtitle: '完善你的育儿名片',
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: fg.withValues(alpha: 0.75)),
              onPressed: _saving ? null : () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                      )
                    : Text('保存', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const UcgSectionLabel(label: '基本信息'),
                UcgShellGlassCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nickname,
                        enabled: !_saving,
                        decoration: InputDecoration(
                          labelText: '昵称',
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: fg.withValues(alpha: 0.55)),
                        ),
                      ),
                      Divider(height: 1, color: fg.withValues(alpha: 0.08)),
                      TextField(
                        controller: _bio,
                        enabled: !_saving,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: '简介',
                          hintText: '介绍一下你和宝宝吧…',
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: fg.withValues(alpha: 0.55)),
                          hintStyle: TextStyle(color: fg.withValues(alpha: 0.35)),
                        ),
                      ),
                    ],
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

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      _profile = await ref.read(ucgRepositoryProvider).fetchProfile(widget.userId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (!await requireUcgLogin(context, ref)) return;
    final repo = ref.read(ucgRepositoryProvider);
    if (_isFollowing) {
      await repo.unfollowUser(widget.userId);
    } else {
      await repo.followUser(widget.userId);
    }
    if (mounted) setState(() => _isFollowing = !_isFollowing);
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
            title: '用户主页',
            subtitle: '看看 TA 的育儿故事',
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
                            child: Column(
                              children: [
                                _ProfileAvatarRing(
                                  avatarUrl: _profile!.avatarUrl,
                                  primary: primary,
                                  radius: 42,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _profile!.nickname,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fg),
                                ),
                                if (_profile!.bio.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _profile!.bio,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: fg.withValues(alpha: 0.65), height: 1.4),
                                    ),
                                  ),
                                if (!mine) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.tonal(
                                      onPressed: _toggleFollow,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _isFollowing
                                            ? fg.withValues(alpha: 0.08)
                                            : primary.withValues(alpha: 0.14),
                                        foregroundColor: _isFollowing ? fg.withValues(alpha: 0.7) : primary,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(_isFollowing ? '已关注' : '关注 TA'),
                                    ),
                                  ),
                                ],
                              ],
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
                                  avatarUrl: p.avatarUrl,
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
      child: CircleAvatar(
        radius: radius,
        backgroundColor: primary.withValues(alpha: 0.12),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Icon(Icons.face_retouching_natural_rounded, color: primary, size: radius)
            : null,
      ),
    );
  }
}
