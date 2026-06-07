import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../theme/ucg_theme.dart';
import '../data/ucg_media_picker.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'ucg_login_gate.dart';
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

class _UcgChatScreenState extends ConsumerState<UcgChatScreen> {
  final _controller = TextEditingController();
  final _messages = <UcgChatMessage>[];
  var _loading = true;
  var _uploadingMedia = false;
  var _isFollowing = false;
  var _followLoaded = false;
  var _followBusy = false;
  String? _resolvedPeerNickname;
  String? _resolvedPeerAvatarThumbnailUrl;
  var _unreadBadgeCleared = false;

  @override
  void initState() {
    super.initState();
    ref.read(ucgRepositoryProvider).setWsConnectionDesired(true);
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
    ref.read(ucgRepositoryProvider).incomingMessages.listen((msg) {
      if (msg.conversationId != widget.conversation.id) return;
      if (!mounted) return;
      setState(() => _messages.add(msg));
      if (!msg.isMine) {
        unawaited(_markAsRead(lastMsgId: msg.id));
      }
    });
  }

  Future<void> _markAsRead({String? lastMsgId}) async {
    try {
      await ref.read(ucgRepositoryProvider).markConversationRead(
            widget.conversation.id,
            lastMsgId: lastMsgId,
          );
      if (!_unreadBadgeCleared && widget.conversation.unreadCount > 0) {
        _unreadBadgeCleared = true;
        final prev = ref.read(ucgUnreadCountProvider);
        final delta = widget.conversation.unreadCount;
        ref.read(ucgUnreadCountProvider.notifier).state =
            (prev - delta).clamp(0, prev);
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final list =
          await ref.read(ucgRepositoryProvider).fetchChatHistory(widget.conversation.id);
      if (mounted) setState(() => _messages.addAll(list));
      final lastId = list.isNotEmpty ? list.last.id : null;
      await _markAsRead(lastMsgId: lastId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    bumpUcgConversationsRefresh(ref);
    _controller.dispose();
    super.dispose();
  }

  UcgChatMessage _localPending({
    required String id,
    String text = '',
    String? imageKey,
    String? videoKey,
    String? mediaCdnUrl,
  }) {
    return UcgChatMessage(
      id: id,
      conversationId: widget.conversation.id,
      senderId: ref.read(ucgCurrentUserIdProvider) ?? '',
      text: text,
      imageKey: imageKey,
      videoKey: videoKey,
      mediaCdnUrl: mediaCdnUrl,
      createdAt: DateTime.now(),
      status: UcgChatMessageStatus.pending,
      isMine: true,
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
        imageKey: m.imageKey,
        videoKey: m.videoKey,
        mediaCdnUrl: m.mediaCdnUrl,
        createdAt: m.createdAt,
        status: status,
        isMine: m.isMine,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _uploadingMedia) return;
    _controller.clear();
    final id = 'local-${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _messages.add(_localPending(id: id, text: text)));
    try {
      await ref.read(ucgRepositoryProvider).sendChatMessage(
            conversationId: widget.conversation.id,
            text: text,
          );
      if (!mounted) return;
      _markMessage(id, UcgChatMessageStatus.delivered);
    } catch (_) {
      if (!mounted) return;
      _markMessage(id, UcgChatMessageStatus.failed);
    }
  }

  Future<void> _showAttachMenu() async {
    if (_uploadingMedia) return;
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
    await _sendMedia(isVideo: choice == 'video');
  }

  Future<void> _sendMedia({required bool isVideo}) async {
    setState(() => _uploadingMedia = true);
    final id = 'local-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final upload = await ucgPickAndUploadChatMedia(
        repo: ref.read(ucgRepositoryProvider),
        isVideo: isVideo,
      );
      if (upload == null || !mounted) return;

      final caption = _controller.text.trim();
      if (caption.isNotEmpty) _controller.clear();

      setState(() {
        _messages.add(_localPending(
          id: id,
          text: caption,
          imageKey: isVideo ? null : upload.objectKey,
          videoKey: isVideo ? upload.objectKey : null,
          mediaCdnUrl: upload.cdnUrl,
        ));
      });

      await ref.read(ucgRepositoryProvider).sendChatMessage(
            conversationId: widget.conversation.id,
            text: caption,
            imageKey: isVideo ? null : upload.objectKey,
            videoKey: isVideo ? upload.objectKey : null,
          );
      if (!mounted) return;
      _markMessage(id, UcgChatMessageStatus.delivered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is StateError ? e.message : '媒体发送失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
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
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _messages.isEmpty
                    ? const UcgEmptyState(
                        icon: Icons.waving_hand_rounded,
                        title: '打个招呼吧',
                        subtitle: '发送第一条消息，开启温馨对话',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  m.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!m.isMine) ...[
                                  _ChatAvatar(url: peerAvatarThumbnailUrl, primary: primary),
                                  const SizedBox(width: 8),
                                ],
                                _ChatBubble(message: m, primary: primary, fg: fg),
                                if (m.isMine) ...[
                                  const SizedBox(width: 8),
                                  _ChatAvatar(url: myAvatarThumbnailUrl, primary: primary),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          UcgGlassInputDock(
            controller: _controller,
            hintText: _uploadingMedia ? '正在处理媒体…' : '发消息…',
            onSend: _send,
            onAttach: _showAttachMenu,
            busy: _uploadingMedia,
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
  });

  final String nickname;
  final String? avatarUrl;
  final Color primary;
  final Color fg;

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

    return Row(
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
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.url, required this.primary});

  final String? url;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return UcgAvatar(
      radius: 18,
      url: url,
      backgroundColor: primary.withValues(alpha: 0.1),
      foregroundColor: primary,
      placeholderIconSize: 20,
    );
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

  @override
  Widget build(BuildContext context) {
    final m = message;
    final statusIcon = switch (m.status) {
      UcgChatMessageStatus.pending => Icons.schedule_rounded,
      UcgChatMessageStatus.failed => Icons.error_outline_rounded,
      UcgChatMessageStatus.delivered => Icons.done_all_rounded,
    };
    final statusColor = m.status == UcgChatMessageStatus.failed
        ? Theme.of(context).colorScheme.error
        : primary.withValues(alpha: 0.65);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (m.hasImage && m.imageUrl != null)
          _MediaImage(previewUrl: m.imageThumbnailUrl ?? m.imageUrl!, fullUrl: m.imageUrl!),
        if (m.hasVideo && m.videoUrl != null) _MediaVideo(url: m.videoUrl!),
        if (m.text.isNotEmpty)
          Text(
            m.text,
            style: TextStyle(
              color: m.isMine ? UcgTheme.onPrimary(context) : fg,
              height: 1.35,
              fontSize: 15,
            ),
          ),
      ],
    );

    if (m.isMine) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: ClipRRect(
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(child: content),
                    const SizedBox(width: 6),
                    Icon(statusIcon, size: 14, color: statusColor.withValues(alpha: 0.9)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      child: UcgShellGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 18,
        child: content,
      ),
    );
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
  const _MediaVideo({required this.url});

  final String url;

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
          ),
        ),
      ),
    );
  }
}
