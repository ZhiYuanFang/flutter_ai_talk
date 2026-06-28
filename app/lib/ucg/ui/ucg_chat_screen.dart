import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/history_line_format.dart';
import '../../providers/session_provider.dart';
import '../../ui/widgets/keyboard_input_bridge.dart';
import '../../theme/app_visual_tokens.dart';
import '../theme/ucg_theme.dart';
import '../data/ucg_media_picker.dart';
import '../data/ucg_models.dart';
import '../data/ucg_video_upload.dart';
import '../providers/ucg_providers.dart';
import 'ucg_login_gate.dart';
import 'ucg_profile_screens.dart';
import 'widgets/ucg_compose_local_preview.dart';
import 'widgets/ucg_media_viewer.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

String _peerDisplayName(UcgConversation conv, {String? resolvedNickname}) {
  final nick = (resolvedNickname ?? conv.peerNickname).trim();
  if (nick.isNotEmpty) return nick;
  if (conv.peerId.isNotEmpty) return '用户 ${conv.peerId}';
  return '用户';
}

class UcgChatScreen extends ConsumerStatefulWidget {
  const UcgChatScreen({super.key, required this.conversation});

  final UcgConversation conversation;

  @override
  ConsumerState<UcgChatScreen> createState() => _UcgChatScreenState();
}

enum _ChatPendingMediaStatus { pending, uploading, done, failed }

class _PendingChatMedia {
  _PendingChatMedia({
    required this.localPath,
    required this.isVideo,
    this.localBytes,
  });

  final String localPath;
  final Uint8List? localBytes;
  final bool isVideo;
  String? objectKey;
  String? cdnUrl;
  _ChatPendingMediaStatus status = _ChatPendingMediaStatus.pending;
  Future<void>? uploadFuture;

  bool get isDone =>
      status == _ChatPendingMediaStatus.done &&
      objectKey != null &&
      objectKey!.isNotEmpty;
}

class _UcgChatScreenState extends ConsumerState<UcgChatScreen> {
  static const _followBottomThreshold = 80.0;
  static const _viewportScrollDuration = Duration(milliseconds: 200);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <UcgChatMessage>[];
  var _loading = true;
  var _followLatest = true;
  double? _lastListViewportHeight;
  var _sending = false;
  _PendingChatMedia? _pendingMedia;
  var _isFollowing = false;
  var _followLoaded = false;
  var _followBusy = false;
  String? _resolvedPeerNickname;
  String? _resolvedPeerAvatarThumbnailUrl;
  var _unreadBadgeCleared = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onMessageListScroll);
    unawaited(_loadHistory());
    unawaited(_ensurePeerProfile());
    _listenWs();
  }

  Future<void> _ensurePeerProfile() async {
    final conv = widget.conversation;
    if (conv.peerId.isEmpty) return;
    final loggedIn = ref.read(sessionProvider).isLoggedIn;
    final needsNickname = conv.peerNickname.trim().isEmpty;
    final needsAvatar = conv.peerAvatarThumbnailUrl == null;
    final needsFollowing = loggedIn;
    if (!needsNickname && !needsAvatar && !needsFollowing) return;
    try {
      final profile = await ref.read(ucgRepositoryProvider).fetchProfile(
            conv.peerId,
            withAuthorization: loggedIn,
          );
      if (!mounted || profile == null) return;
      setState(() {
        if (needsNickname && profile.nickname.trim().isNotEmpty) {
          _resolvedPeerNickname = profile.nickname;
        }
        if (needsAvatar && profile.avatarThumbnailUrl != null) {
          _resolvedPeerAvatarThumbnailUrl = profile.avatarThumbnailUrl;
        }
        if (needsFollowing) {
          _isFollowing = profile.isFollowing;
          _followLoaded = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    if (!await requireUcgWxAccount(context, ref)) return;
    final peerId = widget.conversation.peerId;
    if (peerId.isEmpty) return;
    setState(() => _followBusy = true);
    final repo = ref.read(ucgRepositoryProvider);
    try {
      if (_isFollowing) {
        await repo.unfollowUser(peerId);
      } else {
        await repo.followUser(peerId);
      }
      ref.invalidate(ucgMyProfileProvider);
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _followLoaded = true;
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

  String? get _peerAvatarThumbnailUrl =>
      _resolvedPeerAvatarThumbnailUrl ?? widget.conversation.peerAvatarThumbnailUrl;

  void _listenWs() {
    final repo = ref.read(ucgRepositoryProvider);
    repo.incomingMessages.listen((msg) {
      if (msg.conversationId != widget.conversation.id) return;
      if (!mounted) return;
      setState(() => _upsertMessage(msg));
      if (_followLatest) {
        _scheduleScrollToLatest();
      }
      if (!msg.isMine) {
        unawaited(_markAsRead(lastMsgId: msg.id));
      }
    });
    repo.auditFailedClientIds.listen((clientMsgId) {
      if (!mounted) return;
      setState(() => _markMessageByClientId(clientMsgId, UcgChatMessageStatus.failed));
    });
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return _followLatest;
    final pos = _scrollController.position;
    if (!pos.maxScrollExtent.isFinite) return _followLatest;
    // reverse ListView: offset 0 is the visual bottom (latest messages).
    return pos.pixels <= _followBottomThreshold;
  }

  void _onMessageListScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom = _isNearBottom;
    if (_followLatest != nearBottom) {
      setState(() => _followLatest = nearBottom);
    }
  }

  void _scheduleScrollToLatest({bool animate = true}) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToLatest(animate: animate);
    });
  }

  void _scrollToLatest({bool animate = true}) {
    void tryScroll({bool withAnimation = false}) {
      if (!_scrollController.hasClients) return;
      const target = 0.0;
      final pos = _scrollController.position;
      if ((pos.pixels - target).abs() < 1) return;
      if (withAnimation) {
        _scrollController.animateTo(
          target,
          duration: _viewportScrollDuration,
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    }

    tryScroll(withAnimation: animate);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      tryScroll(withAnimation: animate);
    });
  }

  void _onListViewportHeight(double height) {
    final previous = _lastListViewportHeight;
    _lastListViewportHeight = height;
    if (previous == null) {
      if (_followLatest) {
        _scheduleScrollToLatest(animate: false);
      }
      return;
    }
    final delta = previous - height;
    if (delta.abs() < 0.5) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_followLatest) {
        _scrollToLatest();
        return;
      }
      final pos = _scrollController.position;
      final next = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
      _scrollController.animateTo(
        next,
        duration: _viewportScrollDuration,
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _markAsRead({String? lastMsgId}) async {
    try {
      await ref.read(ucgRepositoryProvider).markConversationRead(
            widget.conversation.id,
            lastMsgId: lastMsgId,
          );
      if (!_unreadBadgeCleared) {
        _unreadBadgeCleared = true;
        unawaited(ref.read(ucgUnreadSyncProvider)());
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final list =
          await ref.read(ucgRepositoryProvider).fetchChatHistory(widget.conversation.id);
      if (mounted) {
        setState(() => _messages.addAll(list));
        _scheduleScrollToLatest(animate: false);
      }
      final lastId = list.isNotEmpty ? list.last.id : null;
      await _markAsRead(lastMsgId: lastId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    bumpUcgConversationsRefresh(ref);
    _scrollController.removeListener(_onMessageListScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _newClientMsgId() => 'client-${DateTime.now().millisecondsSinceEpoch}';

  void _upsertMessage(UcgChatMessage incoming) {
    final clientKey = incoming.clientMsgId?.trim() ?? '';
    if (clientKey.isNotEmpty) {
      final i = _messages.indexWhere(
        (m) => m.clientMsgId == clientKey || m.id == clientKey,
      );
      if (i >= 0) {
        _messages[i] = incoming;
        return;
      }
    }
    if (incoming.id.isNotEmpty) {
      final i = _messages.indexWhere((m) => m.id == incoming.id);
      if (i >= 0) {
        _messages[i] = incoming;
        return;
      }
    }
    _messages.add(incoming);
  }

  UcgChatMessage _localPending({
    required String clientMsgId,
    String text = '',
    String? imageKey,
    String? videoKey,
    String? mediaCdnUrl,
  }) {
    return UcgChatMessage(
      id: clientMsgId,
      conversationId: widget.conversation.id,
      senderId: ref.read(ucgCurrentUserIdProvider) ?? '',
      text: text,
      clientMsgId: clientMsgId,
      imageKey: imageKey,
      videoKey: videoKey,
      mediaCdnUrl: mediaCdnUrl,
      createdAt: DateTime.now(),
      status: UcgChatMessageStatus.pending,
      isMine: true,
    );
  }

  void _markMessageByClientId(String clientMsgId, UcgChatMessageStatus status) {
    final i = _messages.indexWhere(
      (m) => m.clientMsgId == clientMsgId || m.id == clientMsgId,
    );
    if (i < 0) return;
    final m = _messages[i];
    _messages[i] = UcgChatMessage(
      id: m.id,
      conversationId: m.conversationId,
      senderId: m.senderId,
      text: m.text,
      clientMsgId: m.clientMsgId,
      imageKey: m.imageKey,
      videoKey: m.videoKey,
      mediaCdnUrl: m.mediaCdnUrl,
      mediaThumbnailUrl: m.mediaThumbnailUrl,
      createdAt: m.createdAt,
      status: status,
      isMine: m.isMine,
    );
  }

  void _markMessage(String id, UcgChatMessageStatus status) {
    setState(() {
      final i = _messages.indexWhere((m) => m.id == id);
      if (i < 0) return;
      final m = _messages[i];
      _messages[i] = UcgChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        senderId: m.senderId,
        text: m.text,
        clientMsgId: m.clientMsgId,
        imageKey: m.imageKey,
        videoKey: m.videoKey,
        mediaCdnUrl: m.mediaCdnUrl,
        mediaThumbnailUrl: m.mediaThumbnailUrl,
        createdAt: m.createdAt,
        status: status,
        isMine: m.isMine,
      );
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _controller.text.trim();
    final pending = _pendingMedia;
    if (text.isEmpty && pending == null) return;

    setState(() => _sending = true);
    String? clientMsgId;
    try {
      if (pending != null) {
        await _ensurePendingUpload(pending);
        if (!mounted) return;
        if (!pending.isDone) {
          final message = pending.isVideo ? kUcgVideoUploadUserFailureMessage : '媒体上传失败，请移除后重试';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          return;
        }
      }

      final msgId = _newClientMsgId();
      clientMsgId = msgId;
      final imageKey = pending != null && !pending.isVideo ? pending.objectKey : null;
      final videoKey = pending != null && pending.isVideo ? pending.objectKey : null;
      final mediaCdnUrl = pending?.cdnUrl;

      _controller.clear();
      setState(() {
        _pendingMedia = null;
        _followLatest = true;
        _messages.add(_localPending(
          clientMsgId: msgId,
          text: text,
          imageKey: imageKey,
          videoKey: videoKey,
          mediaCdnUrl: mediaCdnUrl,
        ));
      });
      _scheduleScrollToLatest();
      await ref.read(ucgRepositoryProvider).sendChatMessage(
            conversationId: widget.conversation.id,
            clientMsgId: msgId,
            text: text,
            imageKey: imageKey,
            videoKey: videoKey,
          );
    } catch (_) {
      if (!mounted) return;
      if (clientMsgId != null) {
        _markMessage(clientMsgId, UcgChatMessageStatus.failed);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showAttachMenu() async {
    if (_sending) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('发送图片'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('发送视频'),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await _pickPendingMedia(isVideo: choice == 'video');
  }

  Future<void> _pickPendingMedia({required bool isVideo}) async {
    try {
      final picked = await ucgPickChatMediaLocal(isVideo: isVideo);
      if (picked == null || !mounted) return;
      final pending = _PendingChatMedia(
        localPath: picked.localPath,
        localBytes: picked.localBytes,
        isVideo: picked.isVideo,
      );
      setState(() => _pendingMedia = pending);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is StateError ? e.message : '媒体选择失败')),
        );
      }
    }
  }

  void _startPendingUpload(_PendingChatMedia pending) {
    pending.uploadFuture = _uploadPendingMedia(pending);
  }

  Future<void> _uploadPendingMedia(_PendingChatMedia pending) async {
    pending.status = _ChatPendingMediaStatus.uploading;
    if (mounted) setState(() {});
    try {
      final uploaded = await ucgUploadChatLocalMedia(
        repo: ref.read(ucgRepositoryProvider),
        localPath: pending.localPath,
        isVideo: pending.isVideo,
        localBytes: pending.localBytes,
      );
      if (!mounted || _pendingMedia != pending) return;
      pending.objectKey = uploaded.objectKey;
      pending.cdnUrl = uploaded.cdnUrl;
      pending.status = _ChatPendingMediaStatus.done;
    } catch (e) {
      if (_pendingMedia == pending) {
        pending.status = _ChatPendingMediaStatus.failed;
        if (mounted && pending.isVideo && e is StateError && e.message == kUcgVideoUploadUserFailureMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(kUcgVideoUploadUserFailureMessage)),
          );
        }
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _ensurePendingUpload(_PendingChatMedia pending) async {
    if (pending.isDone) return;
    if (pending.status == _ChatPendingMediaStatus.failed) {
      pending.status = _ChatPendingMediaStatus.pending;
      _startPendingUpload(pending);
    }
    final future = pending.uploadFuture;
    if (future != null) {
      await future;
      return;
    }
    await _uploadPendingMedia(pending);
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UcgUserProfileScreen(userId: userId),
        ),
      ),
    );
  }

  void _clearPendingMedia() {
    setState(() => _pendingMedia = null);
  }

  Widget _buildPendingMediaBar(Color fg) {
    final pending = _pendingMedia;
    if (pending == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: UcgComposeLocalPreview(
                localPath: pending.localPath,
                localBytes: pending.localBytes,
                fit: BoxFit.cover,
                isVideo: pending.isVideo,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pending.isVideo ? '待发送视频' : '待发送图片',
              style: TextStyle(color: fg.withValues(alpha: 0.75), fontSize: 13),
            ),
          ),
          if (_sending && pending.status == _ChatPendingMediaStatus.uploading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg.withValues(alpha: 0.45),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: fg.withValues(alpha: 0.6)),
            onPressed: _sending ? null : _clearPendingMedia,
            tooltip: '移除',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final conv = widget.conversation;
    final myId = ref.watch(ucgCurrentUserIdProvider);
    final myAvatarThumbnailUrl =
        ref.watch(ucgMyProfileProvider).valueOrNull?.avatarThumbnailUrl;
    final peerAvatarThumbnailUrl = _peerAvatarThumbnailUrl;
    final peerTitle = _peerDisplayName(conv, resolvedNickname: _resolvedPeerNickname);
    final isSelfChat = myId != null && myId == conv.peerId;

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: peerTitle,
            titleWidget: _ChatPeerHeaderTitle(
              nickname: peerTitle,
              avatarUrl: peerAvatarThumbnailUrl,
              primary: primary,
              fg: fg,
              onTap: () => _openProfile(conv.peerId),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: fg.withValues(alpha: 0.75)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: isSelfChat
                ? const []
                : [
                    _ChatFollowButton(
                      isFollowing: _isFollowing,
                      loaded: _followLoaded,
                      busy: _followBusy,
                      onPressed: _toggleFollow,
                      primary: primary,
                      fg: fg,
                    ),
                  ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: keyboardInputBridgeController,
              builder: (context, child) {
                readRawViewInsetBottom(context);
                return child!;
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _onListViewportHeight(constraints.maxHeight);
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (_messages.isEmpty) {
                    return const UcgEmptyState(
                      icon: Icons.waving_hand_rounded,
                      title: '打个招呼吧',
                      subtitle: '发送第一条消息，开启温馨对话',
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[_messages.length - 1 - i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                              m.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!m.isMine) ...[
                              _ChatAvatar(
                                url: peerAvatarThumbnailUrl,
                                primary: primary,
                                onTap: () => _openProfile(conv.peerId),
                              ),
                              const SizedBox(width: 8),
                            ],
                            _ChatBubble(message: m, primary: primary, fg: fg),
                            if (m.isMine) ...[
                              const SizedBox(width: 8),
                              _ChatAvatar(
                                url: myAvatarThumbnailUrl,
                                primary: primary,
                                onTap: myId != null ? () => _openProfile(myId) : null,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _buildPendingMediaBar(fg),
          UcgInputDock(
            controller: _controller,
            hintText: '发消息…',
            onSend: _send,
            onAttach: _showAttachMenu,
            busy: _sending,
          ),
        ],
      ),
    );
  }
}

/// Compact follow toggle for chat header (right side).
class _ChatFollowButton extends StatelessWidget {
  const _ChatFollowButton({
    required this.isFollowing,
    required this.loaded,
    required this.busy,
    required this.onPressed,
    required this.primary,
    required this.fg,
  });

  final bool isFollowing;
  final bool loaded;
  final bool busy;
  final VoidCallback onPressed;
  final Color primary;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return SizedBox(
        width: 52,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }

    return TextButton(
      onPressed: busy ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isFollowing ? fg.withValues(alpha: 0.68) : primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: busy
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            )
          : Text(
              isFollowing ? '已关注' : '关注',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
    );
  }
}

/// Compact peer avatar + nickname for chat AppBar (WeChat-style, left-aligned).
class _ChatPeerHeaderTitle extends StatelessWidget {
  const _ChatPeerHeaderTitle({
    required this.nickname,
    required this.avatarUrl,
    required this.primary,
    required this.fg,
    this.onTap,
  });

  final String nickname;
  final String? avatarUrl;
  final Color primary;
  final Color fg;
  final VoidCallback? onTap;

  static const _avatarRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              height: 1.2,
            ) ??
        TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 17, height: 1.2);

    final row = Row(
      children: [
        const SizedBox(width: 4),
        UcgAvatar(
          radius: _avatarRadius,
          url: avatarUrl,
          backgroundColor: primary.withValues(alpha: 0.1),
          foregroundColor: primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
      ],
    );

    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: row);
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.url,
    required this.primary,
    this.onTap,
  });

  final String? url;
  final Color primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = UcgAvatar(
      radius: 18,
      url: url,
      backgroundColor: primary.withValues(alpha: 0.1),
      foregroundColor: primary,
      placeholderIconSize: 20,
    );
    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.primary,
    required this.fg,
  });

  final UcgChatMessage message;
  final Color primary;
  final Color fg;

  bool _hasMedia(UcgChatMessage m) =>
      (m.hasImage && m.imageUrl != null) || (m.hasVideo && m.videoUrl != null);

  bool _isPureMedia(UcgChatMessage m) => m.text.trim().isEmpty && _hasMedia(m);

  String? _chatTimeLabel(UcgChatMessage m) {
    if (historyInstantUnset(m.createdAt)) return null;
    return formatHistoryInstant(m.createdAt.toLocal(), DateTime.now());
  }

  Widget _wrapWithTime(Widget body, double maxWidth, bool isMine) {
    final label = _chatTimeLabel(message);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.45)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaSection(UcgChatMessage m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (m.hasImage && m.imageUrl != null)
          _MediaImage(previewUrl: m.imageThumbnailUrl ?? m.imageUrl!, fullUrl: m.imageUrl!),
        if (m.hasVideo && m.videoUrl != null)
          _MediaVideo(url: m.videoUrl!, posterUrl: m.videoThumbnailUrl),
      ],
    );
  }

  Widget _textBubble(BuildContext context, UcgChatMessage m, {EdgeInsets? padding}) {
    final bubblePadding = padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    final text = Text(
      m.text,
      style: TextStyle(
        color: m.isMine ? UcgTheme.onPrimary(context) : fg,
        height: 1.35,
        fontSize: 15,
      ),
    );

    if (m.isMine) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(6),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.88),
                  Color.lerp(primary, UcgTheme.surface(context), 0.12)!.withValues(alpha: 0.92),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(color: primary.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Padding(padding: bubblePadding, child: text),
          ),
        ),
      );
    }

    return UcgSurfaceCard(
      padding: bubblePadding,
      borderRadius: 18,
      child: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = message;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.72;
    final statusIcon = switch (m.status) {
      UcgChatMessageStatus.pending => Icons.schedule_rounded,
      UcgChatMessageStatus.failed => Icons.error_outline_rounded,
      UcgChatMessageStatus.delivered => Icons.done_all_rounded,
    };
    final statusColor = m.status == UcgChatMessageStatus.failed
        ? Theme.of(context).colorScheme.error
        : primary.withValues(alpha: 0.65);

    final Widget body;
    if (_isPureMedia(m)) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: _mediaSection(m)),
          if (m.isMine) ...[
            const SizedBox(width: 6),
            Icon(statusIcon, size: 14, color: statusColor.withValues(alpha: 0.9)),
          ],
        ],
      );
    } else if (_hasMedia(m) && m.text.trim().isNotEmpty) {
      body = Column(
        crossAxisAlignment: m.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _mediaSection(m),
          const SizedBox(height: 4),
          m.isMine
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(child: _textBubble(context, m)),
                    const SizedBox(width: 6),
                    Icon(statusIcon, size: 14, color: statusColor.withValues(alpha: 0.9)),
                  ],
                )
              : _textBubble(context, m),
        ],
      );
    } else if (m.isMine) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: _textBubble(context, m)),
          const SizedBox(width: 6),
          Icon(statusIcon, size: 14, color: statusColor.withValues(alpha: 0.9)),
        ],
      );
    } else {
      body = _textBubble(context, m);
    }

    return _wrapWithTime(body, maxWidth, m.isMine);
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({required this.previewUrl, required this.fullUrl});

  final String previewUrl;
  final String fullUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => showUcgPhotoLightbox(context, urls: [fullUrl]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
            child: UcgNetworkImage(url: previewUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _MediaVideo extends StatelessWidget {
  const _MediaVideo({required this.url, this.posterUrl});

  final String url;
  final String? posterUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 220,
          child: UcgInlineVideoPlayer(
            videoUrl: url,
            aspectRatio: 16 / 9,
            borderRadius: 12,
            posterUrl: posterUrl,
          ),
        ),
      ),
    );
  }
}
