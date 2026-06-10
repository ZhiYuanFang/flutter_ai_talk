import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/ai_quota_errors.dart';
import '../../api/api_exceptions.dart';
import '../../providers/ai_quota_provider.dart';
import '../../ui/widgets/ai_quota_remaining_hint.dart';
import '../data/ucg_compose_media_slot.dart';
import '../data/ucg_media_url.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import '../../config/ucg_ai_polish_consent_store.dart';
import '../../theme/app_visual_tokens.dart';
import '../../ui/widgets/app_glass_overlay.dart';
import '../../ui/widgets/managed_keyboard_text_field.dart';
import 'widgets/ucg_compose_local_preview.dart';
import 'widgets/ucg_compose_entry_sheet.dart';
import 'widgets/ucg_compose_light_glass_panel.dart';
import 'widgets/ucg_compose_media_grid.dart';
import 'widgets/ucg_media_viewer.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

/// compose 关闭结果：新帖发表成功时 shell 切「我的」。
class UcgComposePopResult {
  const UcgComposePopResult({this.publishedNewPost = false});

  final bool publishedNewPost;
}

/// 发布页：玻璃 panel + 9 宫格；本地预览 + 后台上传。
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
  final _imageSlots = <UcgComposeMediaSlot>[];
  UcgComposeMediaSlot? _videoSlot;
  final _sessionUploadedKeys = <String>{};
  var _publishing = false;
  var _polishing = false;
  var _draggingImage = false;

  bool get _hasVideo => _videoSlot != null && !_videoSlot!.removed;

  bool get _hasContent =>
      _text.text.trim().isNotEmpty || _imageSlots.isNotEmpty || _hasVideo;

  bool get _showAiPolish => _imageSlots.isNotEmpty && !_hasVideo;

  bool get _busy => _publishing || _polishing;

  bool get _canAddImages =>
      !widget.textOnly && !_hasVideo && _imageSlots.length < maxImages;

  bool get _showImageGrid => _imageSlots.isNotEmpty || _canAddImages;

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
    if (post != null) {
      for (var i = 0; i < post.imageKeys.length; i++) {
        final key = post.imageKeys[i];
        final cdn = i < post.imageCdnUrls.length ? post.imageCdnUrls[i] : null;
        _imageSlots.add(UcgComposeMediaSlot.remoteImage(objectKey: key, cdnUrl: cdn));
        _sessionUploadedKeys.add(key);
      }
      if (post.videoKey != null && post.videoKey!.isNotEmpty) {
        _videoSlot = UcgComposeMediaSlot.remoteVideo(objectKey: post.videoKey!);
        _sessionUploadedKeys.add(post.videoKey!);
      }
    } else {
      final initial = widget.initialMedia;
      if (initial != null && !initial.isEmpty) {
        _applyInitialMedia(initial);
      } else {
        unawaited(_restoreDraft());
      }
    }
  }

  void _applyInitialMedia(UcgComposeInitialMedia initial) {
    for (var i = 0; i < initial.imageLocalPaths.length; i++) {
      if (_imageSlots.length >= maxImages) break;
      final bytes = i < initial.imageLocalBytes.length ? initial.imageLocalBytes[i] : null;
      _addLocalSlot(
        path: initial.imageLocalPaths[i],
        isVideo: false,
        bytes: bytes,
      );
    }
    if (initial.videoLocalPath != null && initial.videoLocalPath!.isNotEmpty) {
      _addLocalSlot(
        path: initial.videoLocalPath!,
        isVideo: true,
        bytes: initial.videoLocalBytes,
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
  }

  UcgComposeMediaSlot _addLocalSlot({
    required String path,
    required bool isVideo,
    Uint8List? bytes,
  }) {
    final slot = UcgComposeMediaSlot.localFile(
      id: nextComposeSlotId(),
      path: path,
      isVideo: isVideo,
      bytes: bytes,
    );
    if (isVideo) {
      _videoSlot = slot;
    } else {
      _imageSlots.add(slot);
    }
    _enqueueSlotUpload(slot);
    return slot;
  }

  void _enqueueSlotUpload(UcgComposeMediaSlot slot) {
    startComposeSlotBackgroundUpload(
      repo: ref.read(ucgRepositoryProvider),
      slot: slot,
      onUpdated: () {
        if (!mounted) return;
        if (slot.isDone && slot.objectKey != null) {
          _sessionUploadedKeys.add(slot.objectKey!);
        }
        setState(() {});
      },
    );
  }

  Future<void> _restoreDraft() async {
    final draft = await ref.read(ucgComposeDraftStoreProvider).load();
    if (draft == null || draft.isEmpty || !mounted) return;
    _text.text = draft.text;
    setState(() {
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
        if (mounted) setState(() {});
      },
    );
    await ref.read(ucgComposeDraftStoreProvider).save(
          UcgComposeDraft(
            text: _text.text,
            imageKeys: uploaded.imageKeys,
            videoKey: uploaded.videoKey,
            editingPostId: widget.editingPost?.id,
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
      setState(() => _applyInitialMedia(initial));
    } catch (_) {
      _toast('选择图片失败');
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
          if (mounted) setState(() {});
        },
      );
      final polished = await ref.read(ucgRepositoryProvider).polishPost(
            imageKeys: uploaded.imageKeys,
            text: _text.text,
          );
      if (!mounted) return;
      _text.text = polished;
      ref.invalidate(aiQuotaStatusProvider);
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
    if (_busy) {
      _toast('请稍候');
      return;
    }
    setState(() => _publishing = true);
    try {
      final uploaded = await ensureComposeMediaUploaded(
        repo: ref.read(ucgRepositoryProvider),
        imageSlots: _imageSlots,
        videoSlot: _videoSlot,
        onUpdated: () {
          if (mounted) setState(() {});
        },
      );
      if (widget.editingPost != null) {
        await ref.read(ucgRepositoryProvider).updatePost(
              postId: widget.editingPost!.id,
              text: text,
              imageKeys: uploaded.imageKeys,
              videoKey: uploaded.videoKey,
            );
      } else {
        await ref.read(ucgRepositoryProvider).createPost(
              text: text,
              imageKeys: uploaded.imageKeys,
              videoKey: uploaded.videoKey,
            );
      }
      await ref.read(ucgComposeDraftStoreProvider).clear();
      ref.read(ucgPostsChangedProvider.notifier).update((n) => n + 1);
      ref.invalidate(ucgMyProfileProvider);
      if (!mounted) return;
      if (widget.editingPost != null) {
        Navigator.pop(context);
      } else {
        Navigator.pop(context, const UcgComposePopResult(publishedNewPost: true));
      }
    } catch (_) {
      _toast('发布失败');
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
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shellBg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    final shellFg = tokens?.onShell ?? scheme.onSurface;
    final hintColor = ucgComposeLightHintColor(context);
    final videoSlot = _videoSlot;

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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                              if (_showImageGrid) ...[
                                const SizedBox(height: 12),
                                UcgComposeImageGrid(
                                  cells: _gridCells,
                                  busy: _publishing || _polishing,
                                  canAddMore: _canAddImages,
                                  onAddTap: () => unawaited(_pickImages()),
                                  onReorder: _reorderImages,
                                  onDragStarted: (_) => setState(() => _draggingImage = true),
                                  onDragEnded: () => setState(() => _draggingImage = false),
                                ),
                              ],
                              if (_hasVideo && videoSlot != null) ...[
                                const SizedBox(height: 12),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: _busy ? null : () => unawaited(_openVideoPreview(videoSlot)),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: _buildVideoPreview(videoSlot),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Material(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        shape: const CircleBorder(),
                                        clipBehavior: Clip.antiAlias,
                                        child: IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: _busy ? null : () => unawaited(_removeVideo()),
                                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (_showAiPolish) ...[
                                const SizedBox(height: 8),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: AiQuotaRemainingHint(
                                    feature: AiQuotaRemainingHintFeature.polish,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _polishing ? null : () => unawaited(_polishWithAi()),
                                    icon: _polishing
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: scheme.primary,
                                            ),
                                          )
                                        : Icon(Icons.auto_fix_high_outlined, size: 18, color: scheme.primary),
                                    label: Text(
                                      _polishing ? '润笔中…' : 'AI润笔',
                                      style: TextStyle(color: shellFg),
                                    ),
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

  Widget _buildVideoPreview(UcgComposeMediaSlot slot) {
    final localPath = slot.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          UcgComposeLocalPreview(
            localPath: localPath,
            localBytes: slot.localBytes,
            fit: BoxFit.cover,
            isVideo: true,
          ),
          Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white.withValues(alpha: 0.92),
              size: 48,
            ),
          ),
        ],
      );
    }
    if (slot.objectKey != null && slot.objectKey!.isNotEmpty) {
      final url = UcgMediaUrl.resolveUrl(objectKey: slot.objectKey!, cdnUrl: slot.cdnUrl);
      return Stack(
        fit: StackFit.expand,
        children: [
          UcgNetworkImage(url: url, fit: BoxFit.cover),
          Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white.withValues(alpha: 0.92),
              size: 48,
            ),
          ),
        ],
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
    final key = slot.objectKey;
    if (key != null && key.isNotEmpty) {
      await showUcgVideoFullscreen(
        context,
        videoUrl: UcgMediaUrl.resolveUrl(objectKey: key, cdnUrl: slot.cdnUrl),
      );
      return;
    }
    final path = slot.localPath;
    if (path != null && path.isNotEmpty) {
      await showUcgVideoFullscreen(context, filePath: path);
    }
  }
}
