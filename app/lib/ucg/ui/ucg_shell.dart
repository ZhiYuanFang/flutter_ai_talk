import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/session_provider.dart';
import '../../session/token_expiry.dart';
import '../data/ucg_feature_flags.dart';
import '../data/ucg_models.dart';
import '../data/ucg_repository.dart';
import '../providers/ucg_providers.dart';
import 'ucg_compose_screen.dart';
import 'ucg_login_gate.dart';
import 'ucg_messages_tab.dart';
import 'ucg_profile_shell.dart';
import 'ucg_square_tab.dart';
import 'widgets/ucg_compose_entry_sheet.dart';
import 'widgets/ucg_visual_widgets.dart';

class UcgShell extends ConsumerStatefulWidget {
  const UcgShell({super.key, this.onBackToFeeding});

  final VoidCallback? onBackToFeeding;

  @override
  ConsumerState<UcgShell> createState() => _UcgShellState();
}

class _UcgShellState extends ConsumerState<UcgShell> {
  var _tabIndex = 0;
  StreamSubscription<void>? _notifSub;
  UcgRepository? _repo;

  int get _stackIndex {
    if (!kUcgTreasureEnabled) {
      if (_tabIndex == 0) return 0;
      if (_tabIndex == 3) return 1;
      if (_tabIndex == 4) return 2;
      return 0;
    }
    if (_tabIndex <= 1) return _tabIndex;
    if (_tabIndex == 3) return 2;
    if (_tabIndex == 4) return 3;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureShellWs());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _ensureShellWs() {
    final wxId = ref.read(ucgCurrentUserIdProvider);
    if (!isUcgWxAccountBound(wxId)) return;
    _repo = ref.read(ucgRepositoryProvider);
    final repo = _repo!;
    _notifSub?.cancel();
    _notifSub = repo.notificationEvents.listen((_) {
      bumpUcgNotificationsRefresh(ref);
      unawaited(_syncShellUnreadBadge());
    });
    unawaited(_syncShellUnreadBadge());
  }

  Future<void> _syncShellUnreadBadge() async {
    final wxId = ref.read(ucgCurrentUserIdProvider);
    if (!isUcgWxAccountBound(wxId)) return;
    try {
      final repo = ref.read(ucgRepositoryProvider);
      final notifPage = await repo.fetchCommentNotifications(page: 1);
      final convPage = await repo.fetchConversations(page: 1);
      final chatUnread = convPage.items.fold<int>(0, (s, c) => s + c.unreadCount);
      ref.read(ucgUnreadCountProvider.notifier).state = chatUnread + notifPage.unreadCount;
    } catch (_) {}
  }

  void _onTabTap(int index) {
    if (!kUcgTreasureEnabled && index == 1) return;
    if (index == 2) {
      unawaited(_openCompose());
      return;
    }
    if (!ref.read(sessionProvider).isLoggedIn && (index == 3 || index == 4)) {
      unawaited(promptLoginForPersonalAction(context, ref));
      return;
    }
    setState(() => _tabIndex = index);
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
        setState(() => _tabIndex = 4);
      }
      return;
    }

    final repo = ref.read(ucgRepositoryProvider);
    if (!mounted) return;
    final initial = await showUcgComposeEntrySheet(context, repo: repo);
    if (!mounted) return;
    if (initial == null || initial.isEmpty) return;

    final result = await Navigator.of(context).push<UcgComposePopResult>(
      MaterialPageRoute(
        builder: (_) => UcgComposeScreen(initialMedia: initial),
      ),
    );
    if (!mounted) return;
    if (result?.publishedNewPost == true) {
      setState(() => _tabIndex = 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(ucgCurrentUserIdProvider, (prev, next) {
      if (isUcgWxAccountBound(next)) {
        _ensureShellWs();
      }
    });
    ref.listen<int>(ucgNotificationsChangedProvider, (prev, next) {
      unawaited(_syncShellUnreadBadge());
    });

    final unread = ref.watch(ucgUnreadCountProvider) > 0;
    final back = widget.onBackToFeeding;

    return UcgScaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: [
          UcgSquareTab(onBackToFeeding: back),
          if (kUcgTreasureEnabled) UcgTreasurePlaceholder(onBackToFeeding: back),
          UcgMessagesTab(onBackToFeeding: back),
          UcgProfileTab(onBackToFeeding: back),
        ],
      ),
      bottomNavigationBar: UcgBottomDock(
        currentIndex: _tabIndex,
        showMessageBadge: unread,
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
