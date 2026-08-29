import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/feature_unlock_provider.dart';
import '../../providers/session_provider.dart';
import '../../session/token_expiry.dart';
import '../data/ucg_feature_flags.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_compose_screen.dart';
import 'ucg_login_gate.dart';
import 'ucg_messages_tab.dart';
import 'ucg_profile_shell.dart';
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
  /// IndexedStack 槽位：仅首次进入对应 Tab 时挂载子页，避免消息/我的预拉接口。
  final _stackMounted = <int>{0};

  int get _stackChildCount => kUcgTreasureEnabled ? 4 : 3;

  int _stackIndexForTab(int tabIndex) {
    if (!kUcgTreasureEnabled) {
      if (tabIndex == 0) return 0;
      if (tabIndex == 3) return 1;
      if (tabIndex == 4) return 2;
      return 0;
    }
    if (tabIndex <= 1) return tabIndex;
    if (tabIndex == 3) return 2;
    if (tabIndex == 4) return 3;
    return 0;
  }

  int get _stackIndex => _stackIndexForTab(_tabIndex);

  void _selectTab(int tabIndex) {
    setState(() {
      _tabIndex = tabIndex;
      _stackMounted.add(_stackIndexForTab(tabIndex));
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureShellWs());
  }

  /// C1：进 UCG 仅 HTTP 校准未读（会话 + 互动），不预挂载消息/我的 Tab。
  /// 入场锁未解除时跳过，避免锁下副作用。
  void _ensureShellWs() {
    if (!ref.read(ucgEligibilityStateProvider).isQualified) return;
    final wxId = ref.read(ucgCurrentUserIdProvider);
    if (!isUcgWxAccountBound(wxId)) return;
    unawaited(ref.read(ucgUnreadSyncProvider)());
  }

  void _onTabTap(int index) {
    if (!kUcgTreasureEnabled && index == 1) return;
    if (index == 0 && _tabIndex == 0) {
      widget.onBackToFeeding?.call();
      return;
    }
    if (index == 2) {
      return;
    }
    if (!ref.read(sessionProvider).isLoggedIn && (index == 3 || index == 4)) {
      unawaited(promptLoginForPersonalAction(context, ref));
      return;
    }
    _selectTab(index);
    if (index == 3) {
      bumpUcgConversationsRefresh(ref);
      bumpUcgNotificationsRefresh(ref);
    } else if (index == 4) {
      ref.invalidate(ucgMyProfileProvider);
    }
  }

  Future<void> _openCompose({UcgPost? editing, bool textOnly = false}) async {
    if (!await requireUcgWxAccount(context, ref)) return;
    if (!mounted) return;

    if (editing != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => UcgComposeScreen(editingPost: editing)),
      );
      return;
    }

    if (textOnly) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const UcgComposeScreen(textOnly: true)),
      );
      return;
    }

    final draft = await ref.read(ucgComposeDraftStoreProvider).load();
    if (!mounted) return;
    if (draft != null && !draft.isEmpty) {
      final result = await Navigator.of(context).push<UcgComposePopResult>(
        MaterialPageRoute(builder: (_) => const UcgComposeScreen()),
      );
      if (!mounted) return;
      if (result?.publishedNewPost == true) {
        _selectTab(4);
        ref.invalidate(ucgMyProfileProvider);
      }
      return;
    }

    final result = await Navigator.of(context).push<UcgComposePopResult>(
      MaterialPageRoute(builder: (_) => const UcgComposeScreen()),
    );
    if (!mounted) return;
    if (result?.publishedNewPost == true) {
      _selectTab(4);
      ref.invalidate(ucgMyProfileProvider);
    }
  }

  Widget _buildStackChild(int stackIndex) {
    final back = widget.onBackToFeeding;
    if (!_stackMounted.contains(stackIndex)) {
      return const SizedBox.expand();
    }
    if (!kUcgTreasureEnabled) {
      return switch (stackIndex) {
        0 => UcgSquareTab(onBackToFeeding: back),
        1 => UcgMessagesTab(onBackToFeeding: back),
        2 => UcgProfileTab(onBackToFeeding: back),
        _ => const SizedBox.expand(),
      };
    }
    return switch (stackIndex) {
      0 => UcgSquareTab(onBackToFeeding: back),
      1 => UcgTreasurePlaceholder(onBackToFeeding: back),
      2 => UcgMessagesTab(onBackToFeeding: back),
      3 => UcgProfileTab(onBackToFeeding: back),
      _ => const SizedBox.expand(),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(ucgCurrentUserIdProvider, (prev, next) {
      if (isUcgWxAccountBound(next)) {
        _ensureShellWs();
      }
    });
    // 资格从锁态变为合格后再校准未读
    ref.listen(ucgEligibilityStateProvider, (prev, next) {
      if (next.isQualified && !(prev?.isQualified ?? false)) {
        _ensureShellWs();
      }
    });

    final unread = ref.watch(ucgUnreadCountProvider) > 0;

    return UcgScaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: [
          for (var i = 0; i < _stackChildCount; i++) _buildStackChild(i),
        ],
      ),
      bottomNavigationBar: UcgBottomDock(
        currentIndex: _tabIndex,
        showMessageBadge: unread,
        showComposeEntry: true,
        onTap: _onTabTap,
        onComposeTap: () => unawaited(_openCompose()),
        onComposeLongPress: () => unawaited(_openCompose(textOnly: true)),
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

    return profileAsync.when(
      loading: () => UcgTabPage(
        title: '',
        showTitle: false,
        leading: ucgBackLeading(context, onBackToFeeding),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => UcgTabPage(
        title: '',
        showTitle: false,
        leading: ucgBackLeading(context, onBackToFeeding),
        body: UcgProfileLoadError(
          onRetry: () => ref.invalidate(ucgMyProfileProvider),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return UcgTabPage(
            title: '',
            showTitle: false,
            leading: ucgBackLeading(context, onBackToFeeding),
            body: UcgProfileLoadError(
              onRetry: () => ref.invalidate(ucgMyProfileProvider),
            ),
          );
        }
        return UcgScaffold(
          body: UcgProfileShell(
            mode: UcgProfileMode.ownerTab,
            profile: profile,
            postsSource: UcgProfilePostsSource.mine,
            showOwnerActions: true,
            wxBound: wxBound,
            leading: ucgBackLeading(context, onBackToFeeding),
          ),
        );
      },
    );
  }
}
