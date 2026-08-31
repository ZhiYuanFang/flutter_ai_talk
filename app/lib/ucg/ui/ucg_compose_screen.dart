import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/ai_quota_errors.dart';
import '../../api/api_exceptions.dart';
import '../../api/app_debug_log.dart';
import '../data/ucg_location.dart';
import '../data/ucg_compose_media_slot.dart';
import '../data/ucg_media_url.dart';
import '../data/ucg_models.dart';
import '../../config/env.dart';
import '../data/ucg_video_upload.dart';
import '../data/ucg_video_playback.dart';
import '../providers/ucg_providers.dart';
import '../../config/ucg_ai_polish_consent_store.dart';
import '../../theme/app_visual_tokens.dart';
import '../../ui/auth/auth_field_scroll.dart';
import '../../ui/widgets/app_glass_overlay.dart';
import '../../ui/widgets/keyboard_input_bridge.dart';
import '../../ui/widgets/managed_keyboard_text_field.dart';
import 'widgets/ucg_compose_local_preview.dart';
import 'widgets/ucg_compose_entry_sheet.dart';
import 'widgets/ucg_compose_light_glass_panel.dart';
import 'widgets/ucg_compose_media_grid.dart';
import 'widgets/ucg_compose_video_preview_layout.dart';
import 'widgets/ucg_media_viewer.dart';
import 'widgets/ucg_visual_widgets.dart';

/// compose 关闭结果：新帖发表成功时 shell 切「我的」。
class UcgComposePopResult {
  const UcgComposePopResult({this.publishedNewPost = false});

  final bool publishedNewPost;
}

/// 发布页：玻璃 panel + 9 宫格；本地预览，提交时 upload。
class UcgComposeScreen extends ConsumerStatefulWidget {
  const UcgComposeScreen({
    super.key,
    this.editingPost,
    this.initialMedia,
    this.textOnly = false,
  });

  final UcgPost? editingPost;
  final UcgComposeInitialMedia? initialMedia;
  final bool textOnly;

  @override
  ConsumerState<UcgComposeScreen> createState() => _UcgComposeScreenState();
}

class _UcgComposeScreenState extends ConsumerState<UcgComposeScreen> {
  static const maxImages = 9;
  static const _bodyHint = '这一刻的想法…';

  late final TextEditingController _text;
  late final TextEditingController _debateLeft;
  late final TextEditingController _debateRight;
  final _imageSlots = <UcgComposeMediaSlot>[];
  UcgComposeMediaSlot? _videoSlot;
  final _sessionUploadedKeys = <String>{};
  var _publishing = false;
  var _polishing = false;
  var _draggingImage = false;
  final _slotsRevision = ValueNotifier(0);
  final _scrollCtrl = ScrollController();
  final _debatePanelAnchorKey = GlobalKey();
  var _debateEnabled = false;

  void _notifySlotsChanged() => _slotsRevision.value++;

  Future<void> _hydrateSlotPreview(UcgComposeMediaSlot slot) async {
    final path = slot.localPath;
    if (path == null || path.isEmpty) return;
    final bytes = await ucgReadLocalImageBytes(path);
    if (!mounted || bytes == null || bytes.isEmpty) return;
    slot.localBytes = bytes;
    _notifySlotsChanged();
  }

  bool get _hasVideo => _videoSlot != null && !_videoSlot!.removed;

  bool get _hasContent =>
      _text.text.trim().isNotEmpty || _imageSlots.isNotEmpty || _hasVideo;

  bool get _showAiPolish => _imageSlots.isNotEmpty && !_hasVideo;

  bool get _busy => _publishing || _polishing;

  bool get _canAddImages =>
      !widget.textOnly && !_hasVideo && _imageSlots.length < maxImages;

  /// 编辑帖且无图无视频：单一 entry sheet 添加入口（方案 B）。
  bool get _showUnifiedEditMediaEntry =>
      widget.editingPost != null &&
      !widget.textOnly &&
      !_hasVideo &&
      _imageSlots.isEmpty;

  /// 新发视频帖选定后不可移除（须退出重选）。
  bool get _canRemoveVideo => widget.editingPost != null && _hasVideo;

  bool get _showImageGrid =>
      _imageSlots.isNotEmpty || (_canAddImages && !_showUnifiedEditMediaEntry);

  bool get _showVideoArea => _hasVideo;

  List<UcgComposeGridCell> get _gridCells => _imageSlots
      .map(
        (s) => UcgComposeGridCell(
          id: s.id,
          localPath: s.localPath,
          localBytes: s.localBytes,
          objectKey: s.objectKey,
          cdnUrl: s.cdnUrl,
        ),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final post = widget.editingPost;
    _text = TextEditingController(text: post?.text ?? '');
    _debateLeft = TextEditingController(text: post?.debateLeft ?? '');
    _debateRight = TextEditingController(text: post?.debateRight ?? '');
    if (post != null) {
      for (var i = 0; i < post.imageKeys.length; i++) {
        final key = post.imageKeys[i];
        final cdn = i < post.imageCdnUrls.length ? post.imageCdnUrls[i] : null;
        _imageSlots.add(UcgComposeMediaSlot.remoteImage(objectKey: key, cdnUrl: cdn));
        _sessionUploadedKeys.add(key);
      }
      if (post.videoKey != null && post.videoKey!.isNotEmpty) {
        _videoSlot = UcgComposeMediaSlot.remoteVideo(objectKey: post.videoKey!)
          ..videoWidth = post.videoWidth
          ..videoHeight = post.videoHeight;
        _sessionUploadedKeys.add(post.videoKey!);
      }
    } else {
      final initial = widget.initialMedia;
      if (initial != null && !initial.isEmpty) {
        unawaited(_applyInitialMedia(initial));
      } else {
        unawaited(_restoreDraft());
      }
    }
  }

  Future<void> _applyInitialMedia(UcgComposeInitialMedia initial) async {
    for (var i = 0; i < initial.imageLocalPaths.length; i++) {
      if (_imageSlots.length >= maxImages) break;
      var bytes = i < initial.imageLocalBytes.length ? initial.imageLocalBytes[i] : null;
      if (bytes != null && bytes.isEmpty) bytes = null;
      final path = initial.imageLocalPaths[i];
      bytes ??= await ucgReadLocalImageBytes(path);
      if (!mounted) return;
      final slot = _addLocalSlot(
        path: path,
        isVideo: false,
        bytes: bytes,
      );
      if ((bytes == null || bytes.isEmpty) && !kIsWeb) {
        unawaited(_hydrateSlotPreview(slot));
      }
      _notifySlotsChanged();
    }
    if (initial.videoLocalPath != null && initial.videoLocalPath!.isNotEmpty) {
      if (!AppEnv.ucgVideoUploadEnabled) {
        _toast(kUcgVideoUploadDisabledMessage);
        if (mounted) _notifySlotsChanged();
        return;
      }
      if (_imageSlots.isNotEmpty) {
        _toast('已选择图片，不能再添加视频');
        if (mounted) _notifySlotsChanged();
        return;
      }
      if (!mounted) return;
      _addLocalSlot(
        path: initial.videoLocalPath!,
        isVideo: true,
        bytes: initial.videoLocalBytes,
        mediaUri: initial.videoMediaUri,
      );
    }
    for (final key in initial.imageKeys) {
      if (_imageSlots.length >= maxImages) break;
      _imageSlots.add(UcgComposeMediaSlot.remoteImage(objectKey: key));
      _sessionUploadedKeys.add(key);
    }
    if (initial.videoKey != null && initial.videoKey!.isNotEmpty) {
      _videoSlot = UcgComposeMediaSlot.remoteVideo(objectKey: initial.videoKey!);
      _sessionUploadedKeys.add(initial.videoKey!);
    }
    if (mounted) _notifySlotsChanged();
  }

  UcgComposeMediaSlot _addLocalSlot({
    required String path,
    required bool isVideo,
    Uint8List? bytes,
    String? mediaUri,
  }) {
    final slot = UcgComposeMediaSlot.localFile(
      id: nextComposeSlotId(),
      path: path,
      isVideo: isVideo,
      bytes: bytes,
      mediaUri: mediaUri,
    );
    if (isVideo) {
      _videoSlot = slot;
      unawaited(_probeVideoSlotDimensions(slot));
    } else {
      _imageSlots.add(slot);
    }
    return slot;
  }

  void _recordSessionUploadedKeys() {
    for (final slot in _imageSlots) {
      if (!slot.removed && slot.isDone && slot.objectKey != null) {
        _sessionUploadedKeys.add(slot.objectKey!);
      }
    }
    final video = _videoSlot;
    if (video != null && !video.removed && video.isDone && video.objectKey != null) {
      _sessionUploadedKeys.add(video.objectKey!);
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await ref.read(ucgComposeDraftStoreProvider).load();
    if (draft == null || draft.isEmpty || !mounted) return;
    _text.text = draft.text;
    _debateLeft.text = draft.debateLeft;
    _debateRight.text = draft.debateRight;
    setState(() {
      _debateEnabled = draft.debateEnabled;
      _imageSlots
        ..clear()
        ..addAll(draft.imageKeys.map((k) => UcgComposeMediaSlot.remoteImage(objectKey: k)));
      _videoSlot = draft.videoKey != null && draft.videoKey!.isNotEmpty
          ? UcgComposeMediaSlot.remoteVideo(objectKey: draft.videoKey!)
          : null;
      _sessionUploadedKeys
        ..clear()
        ..addAll(draft.imageKeys);
      if (draft.videoKey != null && draft.videoKey!.isNotEmpty) {
        _sessionUploadedKeys.add(draft.videoKey!);
      }
    });
  }

  Future<void> _persistDraft() async {
    final uploaded = await ensureComposeMediaUploaded(
      repo: ref.read(ucgRepositoryProvider),
      imageSlots: _imageSlots,
      videoSlot: _videoSlot,
      onUpdated: () {
        if (mounted) _notifySlotsChanged();
      },
    );
    _recordSessionUploadedKeys();
    await ref.read(ucgComposeDraftStoreProvider).save(
          UcgComposeDraft(
            text: _text.text,
            imageKeys: uploaded.imageKeys,
            videoKey: uploaded.videoKey,
            editingPostId: widget.editingPost?.id,
            debateEnabled: _debateEnabled,
            debateLeft: _debateLeft.text,
            debateRight: _debateRight.text,
          ),
        );
  }

  Future<void> _discardSession() async {
    for (final slot in [..._imageSlots, if (_videoSlot != null) _videoSlot!]) {
      slot.removed = true;
    }
    final keys = _sessionUploadedKeys.toList(growable: false);
    await ref.read(ucgComposeDraftStoreProvider).clear();
    if (keys.isNotEmpty) {
      try {
        await ref.read(ucgRepositoryProvider).deleteMedia(objectKeys: keys);
      } catch (_) {}
    }
    _sessionUploadedKeys.clear();
  }

  Future<void> _removeImageAt(int index) async {
    if (index < 0 || index >= _imageSlots.length) return;
    final slot = _imageSlots[index];
    slot.removed = true;
    setState(() => _imageSlots.removeAt(index));
    if (slot.isDone && slot.objectKey != null) {
      try {
        await ref.read(ucgRepositoryProvider).deleteMedia(objectKeys: [slot.objectKey!]);
        _sessionUploadedKeys.remove(slot.objectKey);
      } catch (_) {
        _toast('删除媒体失败');
      }
    }
  }

  Future<void> _removeVideo() async {
    final slot = _videoSlot;
    if (slot == null) return;
    slot.removed = true;
    setState(() => _videoSlot = null);
    if (slot.isDone && slot.objectKey != null) {
      try {
        await ref.read(ucgRepositoryProvider).deleteMedia(objectKeys: [slot.objectKey!]);
        _sessionUploadedKeys.remove(slot.objectKey);
      } catch (_) {
        _toast('删除视频失败');
      }
    }
  }

  Future<bool> _onCloseRequested() async {
    if (!_hasContent) return true;
    final action = await showGlassComposeExitDialog(
      context,
      onSaveDraft: () async {
        try {
          await _persistDraft();
          return true;
        } catch (_) {
          _toast('保存草稿失败');
          return false;
        }
      },
    );
    switch (action) {
      case GlassComposeExitAction.saveDraft:
        return true;
      case GlassComposeExitAction.discard:
        await _discardSession();
        return true;
      case GlassComposeExitAction.cancel:
      case null:
        return false;
    }
  }

  Future<void> _pickImages() async {
    if (widget.textOnly) return;
    if (_hasVideo) {
      _toast('已选择视频，不能再添加图片');
      return;
    }
    final remaining = maxImages - _imageSlots.length;
    if (remaining <= 0) {
      _toast('最多选择 $maxImages 张图片');
      return;
    }
    try {
      final initial = await ucgPickMoreImagesForCompose(
        context,
        repo: ref.read(ucgRepositoryProvider),
        remainingSlots: remaining,
      );
      if (!mounted || initial == null || initial.isEmpty) return;
      await _applyInitialMedia(initial);
    } catch (_) {
      _toast('选择图片失败');
    }
  }

  Future<void> _pickMediaViaEntrySheet() async {
    if (!_showUnifiedEditMediaEntry) return;
    try {
      final initial = await showUcgComposeEntrySheet(
        context,
        repo: ref.read(ucgRepositoryProvider),
      );
      if (!mounted || initial == null || initial.isEmpty) return;
      await _applyInitialMedia(initial);
    } catch (_) {
      _toast('选择媒体失败');
    }
  }

  Future<bool> _ensureUcgAiPolishConsent() async {
    if (await UcgAiPolishConsentStore.load()) return true;
    if (!mounted) return false;
    final agreed = await showGlassConfirmDialog(
          context,
          title: '使用 AI 润笔前请知悉',
          message: '您所选图片及当前正文将发送至第三方 AI 服务，用于生成润色文案。',
          confirmLabel: '同意并继续',
        ) ??
        false;
    if (!agreed) return false;
    await UcgAiPolishConsentStore.saveAccepted();
    return true;
  }

  Future<void> _polishWithAi() async {
    if (!_showAiPolish || _polishing) return;
    if (!await _ensureUcgAiPolishConsent()) return;
    setState(() => _polishing = true);
    try {
      final uploaded = await ensureComposeMediaUploaded(
        repo: ref.read(ucgRepositoryProvider),
        imageSlots: _imageSlots,
        videoSlot: null,
        onUpdated: () {
          if (mounted) _notifySlotsChanged();
        },
      );
      _recordSessionUploadedKeys();
      final result = await ref.read(ucgRepositoryProvider).polishPost(
            imageKeys: uploaded.imageKeys,
            text: _text.text,
          );
      if (!mounted) return;
      _text.text = result.polishedText;
      // 客户端先行去额度：不展示 quotaDegraded 降速 toast
      _toast('已润笔，可继续编辑');
    } on ApiBusinessException catch (e) {
      if (!mounted) return;
      if (!await handleAiQuotaException(context, e)) {
        _toast(e.message.isNotEmpty ? e.message : 'AI 润笔失败');
      }
    } catch (_) {
      _toast('AI 润笔失败');
    } finally {
      if (mounted) setState(() => _polishing = false);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _publish() async {
    final text = _text.text.trim();
    if (text.isEmpty && _imageSlots.isEmpty && !_hasVideo) {
      _toast('请输入内容或添加媒体');
      return;
    }
    final leftRaw = _debateLeft.text.trim();
    final rightRaw = _debateRight.text.trim();
    var left = leftRaw;
    var right = rightRaw;
    if (!_debateEnabled) {
      left = '';
      right = '';
    } else {
      if (left.isEmpty && right.isEmpty) {
        _toast('请填写双方立场');
        return;
      }
      if (left.isEmpty != right.isEmpty) {
        _toast('请补全另一方立场');
        return;
      }
    }
    if (left.runes.length > 5 || right.runes.length > 5) {
      _toast('立场标签最多 5 字');
      return;
    }
    if (_busy) {
      _toast('请稍候');
      return;
    }
    setState(() => _publishing = true);
    var stage = 'upload';
    AppDebugLog.ucgCompose(
      'compose publish start editing=${widget.editingPost != null} '
      'images=${_imageSlots.length} hasVideo=$_hasVideo',
    );
    try {
      final uploaded = await ensureComposeMediaUploaded(
        repo: ref.read(ucgRepositoryProvider),
        imageSlots: _imageSlots,
        videoSlot: _videoSlot,
        onUpdated: () {
          if (mounted) _notifySlotsChanged();
        },
      );
      _recordSessionUploadedKeys();
      stage = 'location';
      final coords = await ensureUcgLocationForDistance(context, ref);
      stage = 'createPost';
      if (widget.editingPost != null) {
        await ref.read(ucgRepositoryProvider).updatePost(
              postId: widget.editingPost!.id,
              text: text,
              imageKeys: uploaded.imageKeys,
              videoKey: uploaded.videoKey,
              lat: coords?.lat,
              lng: coords?.lng,
            );
      } else {
        await ref.read(ucgRepositoryProvider).createPost(
              text: text,
              imageKeys: uploaded.imageKeys,
              videoKey: uploaded.videoKey,
              lat: coords?.lat,
              lng: coords?.lng,
              debateLeft: left.isEmpty ? null : left,
              debateRight: right.isEmpty ? null : right,
            );
      }
      AppDebugLog.ucgCompose('compose publish ok editing=${widget.editingPost != null}');
      await ref.read(ucgComposeDraftStoreProvider).clear();
      ref.read(ucgPostsChangedProvider.notifier).update((n) => n + 1);
      ref.invalidate(ucgMyProfileProvider);
      if (!mounted) return;
      if (widget.editingPost != null) {
        Navigator.pop(context);
      } else {
        Navigator.pop(context, const UcgComposePopResult(publishedNewPost: true));
      }
    } catch (e) {
      AppDebugLog.ucgCompose('compose publish fail stage=$stage err=$e');
      if (stage == 'upload' && e is StateError && e.message == kUcgVideoUploadUserFailureMessage) {
        _toast(kUcgVideoUploadUserFailureMessage);
      } else {
        _toast('发布失败');
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _reorderImages(int from, int to) {
    if (from == to || from < 0 || to < 0 || from >= _imageSlots.length || to >= _imageSlots.length) {
      return;
    }
    setState(() {
      final item = _imageSlots.removeAt(from);
      _imageSlots.insert(to, item);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _slotsRevision.dispose();
    _text.dispose();
    _debateLeft.dispose();
    _debateRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shellBg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    final shellFg = tokens?.onShell ?? scheme.onSurface;
    final hintColor = ucgComposeLightHintColor(context);
    final sideFormatter = [LengthLimitingTextInputFormatter(5)];
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bridge = keyboardInputBridgeController;
    final binding = bridge.binding;
    final rawKeyboardBottom = readRawViewInsetBottom(context);
    final overlayChrome =
        bridge.overlayVisible(rawKeyboardBottom) ? bridge.accessoryChromeHeight.toDouble() : 0.0;
    scheduleInlineAuthScrollOnInset(
      context,
      focusedNode: binding?.focusNode,
      scrollController: _scrollCtrl,
      anchorKey: binding?.anchorKey,
      keyboardOverlayChrome: overlayChrome,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onCloseRequested() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: UcgScaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                shellBg,
                Color.alphaBlend(scheme.primary.withValues(alpha: 0.04), shellBg),
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    if (await _onCloseRequested() && context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: Text('取消', style: TextStyle(color: shellFg, fontSize: 16)),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _busy ? null : _publish,
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                              shape: const StadiumBorder(),
                            ),
                            child: _publishing
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : Text(widget.editingPost != null ? '更新' : '发表'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24 + bottomInset + overlayChrome,
                      ),
                      children: [
                        UcgComposeLightGlassPanel(
                          eventAccent: scheme.primary,
                          contentPadding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ManagedKeyboardTextField(
                                controller: _text,
                                maxLines: 6,
                                hint: _bodyHint,
                                scene: 'ucg.compose.body',
                                onConfirm: () => unawaited(_persistDraft()),
                                style: TextStyle(color: shellFg, fontSize: 16, height: 1.45),
                                decoration: InputDecoration(
                                  hintText: _bodyHint,
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: hintColor),
                                ),
                              ),
                              if (_showUnifiedEditMediaEntry) ...[
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cellSize = ucgComposeCellSize(constraints.maxWidth);
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: UcgComposeAddTile(
                                        size: cellSize,
                                        onTap: _busy
                                            ? null
                                            : () => unawaited(_pickMediaViaEntrySheet()),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (_showImageGrid) ...[
                                const SizedBox(height: 12),
                                ValueListenableBuilder<int>(
                                  valueListenable: _slotsRevision,
                                  builder: (context, _, __) => UcgComposeImageGrid(
                                    cells: _gridCells,
                                    busy: _publishing || _polishing,
                                    canAddMore: _canAddImages,
                                    onAddTap: () => unawaited(_pickImages()),
                                    onReorder: _reorderImages,
                                    onDragStarted: (_) => setState(() => _draggingImage = true),
                                    onDragEnded: () => setState(() => _draggingImage = false),
                                  ),
                                ),
                              ],
                              if (_showVideoArea) ...[
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final contentWidth = constraints.maxWidth;
                                    return ValueListenableBuilder<int>(
                                      valueListenable: _slotsRevision,
                                      builder: (context, _, __) {
                                        final slot = _videoSlot;
                                        if (slot == null) return const SizedBox.shrink();
                                        final layout = _videoPreviewLayout(
                                          contentWidth: contentWidth,
                                          slot: slot,
                                        );
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            width: layout.displayWidth,
                                            child: AspectRatio(
                                              aspectRatio: layout.aspectRatio,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  GestureDetector(
                                                    onTap: _busy
                                                        ? null
                                                        : () => unawaited(_openVideoPreview(slot)),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(ucgComposeCellRadius),
                                                      child: _buildVideoPreview(
                                                        slot,
                                                        aspectRatio: layout.aspectRatio,
                                                      ),
                                                    ),
                                                  ),
                                                  if (slot.status == UcgComposeMediaSlotStatus.failed)
                                                    Positioned.fill(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(ucgComposeCellRadius),
                                                        child: ColoredBox(
                                                          color: Colors.black.withValues(alpha: 0.55),
                                                          child: const Center(
                                                            child: Padding(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                              child: Text(
                                                                kUcgVideoUploadUserFailureMessage,
                                                                textAlign: TextAlign.center,
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (slot.status ==
                                                      UcgComposeMediaSlotStatus.uploading)
                                                    Positioned.fill(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(ucgComposeCellRadius),
                                                        child: ColoredBox(
                                                          color: Colors.black.withValues(alpha: 0.45),
                                                          child: const Center(
                                                            child: Text(
                                                              '正在上传…',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (_canRemoveVideo)
                                                    Positioned(
                                                      top: 4,
                                                      right: 4,
                                                      child: Material(
                                                        color: Colors.black.withValues(alpha: 0.55),
                                                        shape: const CircleBorder(),
                                                        clipBehavior: Clip.antiAlias,
                                                        child: IconButton(
                                                          visualDensity: VisualDensity.compact,
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(
                                                            minWidth: 28,
                                                            minHeight: 28,
                                                          ),
                                                          onPressed: _busy
                                                              ? null
                                                              : () => unawaited(_removeVideo()),
                                                          icon: const Icon(
                                                            Icons.close_rounded,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                              // if (_showAiPolish) ...[
                              //   const SizedBox(height: 8),
                              //   Align(
                              //     alignment: Alignment.centerLeft,
                              //     child: TextButton.icon(
                              //       onPressed: _polishing ? null : () => unawaited(_polishWithAi()),
                              //       icon: _polishing
                              //           ? SizedBox(
                              //               width: 16,
                              //               height: 16,
                              //               child: CircularProgressIndicator(
                              //                 strokeWidth: 2,
                              //                 color: scheme.primary,
                              //               ),
                              //             )
                              //           : Icon(Icons.auto_fix_high_outlined, size: 18, color: scheme.primary),
                              //       label: Text(
                              //         _polishing ? '润笔中…' : 'AI润笔',
                              //         style: TextStyle(color: shellFg),
                              //       ),
                              //     ),
                              //   ),
                              // ],
                            ],
                          ),
                        ),
                        if (widget.editingPost == null) ...[
                          const SizedBox(height: 12),
                          KeyedSubtree(
                            key: _debatePanelAnchorKey,
                            child: UcgComposeLightGlassPanel(
                              eventAccent: scheme.primary,
                              contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '辩论',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: shellFg,
                                        ),
                                      ),
                                      const Spacer(),
                                      Switch.adaptive(
                                        value: _debateEnabled,
                                        onChanged: _busy
                                            ? null
                                            : (v) => setState(() => _debateEnabled = v),
                                      ),
                                    ],
                                  ),
                                  if (_debateEnabled) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ManagedKeyboardTextField(
                                            controller: _debateLeft,
                                            hint: '左方立场',
                                            anchorKey: _debatePanelAnchorKey,
                                            scene: 'ucg.compose.debate',
                                            inputFormatters: sideFormatter,
                                            onConfirm: () => unawaited(_persistDraft()),
                                            style: TextStyle(color: shellFg, fontSize: 15),
                                            decoration: InputDecoration(
                                              labelText: '左方立场',
                                              counterText: '',
                                              border: InputBorder.none,
                                              labelStyle: TextStyle(
                                                color: ucgComposeLightSecondaryColor(context),
                                              ),
                                              hintStyle: TextStyle(color: hintColor),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 28, left: 8, right: 8),
                                          child: Text(
                                            'VS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: shellFg.withValues(alpha: 0.45),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ManagedKeyboardTextField(
                                            controller: _debateRight,
                                            hint: '右方立场',
                                            anchorKey: _debatePanelAnchorKey,
                                            scene: 'ucg.compose.debate',
                                            inputFormatters: sideFormatter,
                                            onConfirm: () => unawaited(_persistDraft()),
                                            style: TextStyle(color: shellFg, fontSize: 15),
                                            decoration: InputDecoration(
                                              labelText: '右方立场',
                                              counterText: '',
                                              border: InputBorder.none,
                                              labelStyle: TextStyle(
                                                color: ucgComposeLightSecondaryColor(context),
                                              ),
                                              hintStyle: TextStyle(color: hintColor),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (_draggingImage)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: UcgComposeDeleteOverlay(
                    onAccept: (index) {
                      unawaited(_removeImageAt(index));
                      if (mounted) setState(() => _draggingImage = false);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _probeVideoSlotDimensions(UcgComposeMediaSlot slot) async {
    if (!slot.isVideo || slot.removed) return;
    if (slot.videoWidth != null && slot.videoHeight != null) return;

    final post = widget.editingPost;
    if (post != null &&
        slot.objectKey != null &&
        slot.objectKey == post.videoKey &&
        post.videoWidth != null &&
        post.videoHeight != null &&
        post.videoWidth! > 0 &&
        post.videoHeight! > 0) {
      slot.videoWidth = post.videoWidth;
      slot.videoHeight = post.videoHeight;
      _notifySlotsChanged();
      return;
    }

    final path = slot.localPath;
    final mediaUri = slot.mediaUri;
    if ((path == null || path.isEmpty) && (mediaUri == null || mediaUri.isEmpty)) {
      return;
    }

    final dims = await ucgProbeLocalVideoDimensions(
      path ?? '',
      contentUri: mediaUri,
    );
    if (!mounted || slot.removed) return;
    if (dims.width != null && dims.height != null) {
      slot.videoWidth = dims.width;
      slot.videoHeight = dims.height;
      _notifySlotsChanged();
    }
  }

  ({int? width, int? height, bool isPortrait, double aspectRatio, double displayWidth})
      _videoPreviewLayout({
    required double contentWidth,
    UcgComposeMediaSlot? slot,
    bool addVideoPlaceholder = false,
  }) {
    if (addVideoPlaceholder) {
      return (
        width: null,
        height: null,
        isPortrait: true,
        aspectRatio: ucgComposePortraitVideoAspectRatio,
        displayWidth: ucgComposeVideoDisplayWidth(contentWidth, isPortrait: true),
      );
    }
    final metrics = _videoMetricsForSlot(slot);
    final aspectRatio = ucgVideoPreviewAspectRatio(
      width: metrics.width,
      height: metrics.height,
      isPortrait: metrics.isPortrait,
    );
    return (
      width: metrics.width,
      height: metrics.height,
      isPortrait: metrics.isPortrait,
      aspectRatio: aspectRatio,
      displayWidth: ucgComposeVideoDisplayWidth(contentWidth, isPortrait: metrics.isPortrait),
    );
  }

  ({int? width, int? height, bool isPortrait}) _videoMetricsForSlot(UcgComposeMediaSlot? slot) {
    if (slot == null) {
      return (width: null, height: null, isPortrait: true);
    }
    if (slot.videoWidth != null &&
        slot.videoHeight != null &&
        slot.videoWidth! > 0 &&
        slot.videoHeight! > 0) {
      return (
        width: slot.videoWidth,
        height: slot.videoHeight,
        isPortrait: ucgVideoIsPortrait(width: slot.videoWidth, height: slot.videoHeight),
      );
    }
    final post = widget.editingPost;
    if (post != null &&
        slot.objectKey != null &&
        slot.objectKey == post.videoKey &&
        post.videoWidth != null &&
        post.videoHeight != null &&
        post.videoWidth! > 0 &&
        post.videoHeight! > 0) {
      return (
        width: post.videoWidth,
        height: post.videoHeight,
        isPortrait: ucgVideoIsPortrait(width: post.videoWidth, height: post.videoHeight),
      );
    }
    return (
      width: null,
      height: null,
      isPortrait: true,
    );
  }

  Widget _buildVideoPreview(UcgComposeMediaSlot slot, {required double aspectRatio}) {
    final localPath = slot.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      return UcgLocalVideoThumb(
        filePath: localPath,
        posterBytes: slot.localBytes,
        fit: BoxFit.cover,
        showPlayIcon: true,
      );
    }
    final key = slot.objectKey;
    if (key != null && key.isNotEmpty) {
      return UcgInlineVideoPlayer(
        videoUrl: UcgMediaUrl.videoPlayUrl(objectKey: key, cdnUrl: slot.cdnUrl),
        aspectRatio: aspectRatio,
        borderRadius: 0,
        posterOnly: true,
      );
    }
    return UcgComposeLocalPreview(
      localPath: slot.localPath,
      localBytes: slot.localBytes,
      fit: BoxFit.cover,
      isVideo: true,
    );
  }

  Future<void> _openVideoPreview(UcgComposeMediaSlot slot) async {
    final path = slot.localPath;
    final mediaUri = slot.mediaUri;
    final hasLocalSource = (path != null && path.isNotEmpty) ||
        (mediaUri != null && mediaUri.isNotEmpty);
    if (hasLocalSource) {
      if (!context.mounted) return;
      var videoWidth = slot.videoWidth;
      var videoHeight = slot.videoHeight;
      if (videoWidth == null ||
          videoHeight == null ||
          videoWidth <= 0 ||
          videoHeight <= 0) {
        final dims = await ucgProbeLocalVideoDimensions(
          path ?? '',
          contentUri: mediaUri,
        );
        if (!context.mounted) return;
        videoWidth = dims.width;
        videoHeight = dims.height;
      }
      if (!context.mounted) return;
      await showUcgVideoFullscreen(
        context,
        filePath: path,
        contentUri: mediaUri,
        posterBytes: slot.localBytes,
        videoWidth: videoWidth,
        videoHeight: videoHeight,
      );
      return;
    }
    final key = slot.objectKey;
    if (key != null && key.isNotEmpty) {
      if (!context.mounted) return;
      await showUcgVideoFullscreen(
        context,
        videoUrl: UcgMediaUrl.videoPlayUrl(objectKey: key, cdnUrl: slot.cdnUrl),
      );
    }
  }
}
