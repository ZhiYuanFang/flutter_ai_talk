import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ucg_media_url.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import '../../config/ucg_ai_polish_consent_store.dart';
import '../../theme/app_visual_tokens.dart';
import '../../ui/widgets/app_glass_overlay.dart';
import '../../ui/widgets/managed_keyboard_text_field.dart';
import 'widgets/ucg_compose_entry_sheet.dart';
import 'widgets/ucg_compose_light_glass_panel.dart';
import 'widgets/ucg_compose_media_grid.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

/// 发布页：玻璃 panel + 9 宫格；支持 textOnly 与入口预填。
class UcgComposeScreen extends ConsumerStatefulWidget {
  const UcgComposeScreen({
    super.key,
    this.editingPost,
    this.initialImageKeys,
    this.initialVideoKey,
    this.textOnly = false,
  });

  final UcgPost? editingPost;
  final List<String>? initialImageKeys;
  final String? initialVideoKey;
  final bool textOnly;

  @override
  ConsumerState<UcgComposeScreen> createState() => _UcgComposeScreenState();
}

class _UcgComposeScreenState extends ConsumerState<UcgComposeScreen> {
  static const maxImages = 9;
  static const _bodyHint = '这一刻的想法…';

  late final TextEditingController _text;
  final _imageKeys = <String>[];
  final _imageCdnUrls = <String, String>{};
  final _sessionUploadedKeys = <String>{};
  String? _videoKey;
  var _publishing = false;
  var _uploadingMedia = false;
  var _polishing = false;
  var _draggingImage = false;

  bool get _hasContent =>
      _text.text.trim().isNotEmpty ||
      _imageKeys.isNotEmpty ||
      (_videoKey != null && _videoKey!.isNotEmpty);

  bool get _showAiPolish =>
      _imageKeys.isNotEmpty && (_videoKey == null || _videoKey!.isEmpty) && !_uploadingMedia;

  bool get _busy => _publishing || _uploadingMedia || _polishing;

  bool get _canAddImages =>
      !widget.textOnly &&
      (_videoKey == null || _videoKey!.isEmpty) &&
      _imageKeys.length < maxImages;

  bool get _showImageGrid => _imageKeys.isNotEmpty || _canAddImages;

  @override
  void initState() {
    super.initState();
    final post = widget.editingPost;
    _text = TextEditingController(text: post?.text ?? '');
    if (post != null) {
      _imageKeys.addAll(post.imageKeys);
      for (var i = 0; i < post.imageKeys.length; i++) {
        if (i < post.imageCdnUrls.length && post.imageCdnUrls[i].isNotEmpty) {
          _imageCdnUrls[post.imageKeys[i]] = post.imageCdnUrls[i];
        }
      }
      _videoKey = post.videoKey;
      _sessionUploadedKeys.addAll(post.imageKeys);
      if (post.videoKey != null && post.videoKey!.isNotEmpty) {
        _sessionUploadedKeys.add(post.videoKey!);
      }
    } else if (widget.initialImageKeys != null && widget.initialImageKeys!.isNotEmpty) {
      _imageKeys.addAll(widget.initialImageKeys!);
      _sessionUploadedKeys.addAll(widget.initialImageKeys!);
    } else if (widget.initialVideoKey != null && widget.initialVideoKey!.isNotEmpty) {
      _videoKey = widget.initialVideoKey;
      _sessionUploadedKeys.add(widget.initialVideoKey!);
    } else {
      unawaited(_restoreDraft());
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await ref.read(ucgComposeDraftStoreProvider).load();
    if (draft == null || draft.isEmpty || !mounted) return;
    _text.text = draft.text;
    setState(() {
      _imageKeys
        ..clear()
        ..addAll(draft.imageKeys);
      _videoKey = draft.videoKey;
      _sessionUploadedKeys
        ..clear()
        ..addAll(draft.imageKeys);
      if (draft.videoKey != null && draft.videoKey!.isNotEmpty) {
        _sessionUploadedKeys.add(draft.videoKey!);
      }
    });
  }

  Future<void> _persistDraft() async {
    await ref.read(ucgComposeDraftStoreProvider).save(
          UcgComposeDraft(
            text: _text.text,
            imageKeys: List.unmodifiable(_imageKeys),
            videoKey: _videoKey,
            editingPostId: widget.editingPost?.id,
          ),
        );
  }

  Future<void> _discardSession() async {
    final keys = _sessionUploadedKeys.toList(growable: false);
    await ref.read(ucgComposeDraftStoreProvider).clear();
    if (keys.isNotEmpty) {
      try {
        await ref.read(ucgRepositoryProvider).deleteMedia(objectKeys: keys);
      } catch (_) {}
    }
    _sessionUploadedKeys.clear();
  }

  void _trackUpload(String objectKey) {
    if (objectKey.isNotEmpty) _sessionUploadedKeys.add(objectKey);
  }

  Future<void> _removeImageAt(int index) async {
    if (index < 0 || index >= _imageKeys.length) return;
    final key = _imageKeys[index];
    setState(() {
      _imageKeys.removeAt(index);
      _imageCdnUrls.remove(key);
    });
    try {
      await ref.read(ucgRepositoryProvider).deleteMedia(objectKeys: [key]);
      _sessionUploadedKeys.remove(key);
    } catch (_) {
      _toast('删除媒体失败');
    }
  }

  Future<void> _removeVideo() async {
    final key = _videoKey;
    if (key == null || key.isEmpty) return;
    setState(() => _videoKey = null);
    try {
      await ref.read(ucgRepositoryProvider).deleteMedia(objectKeys: [key]);
      _sessionUploadedKeys.remove(key);
    } catch (_) {
      _toast('删除视频失败');
    }
  }

  Future<bool> _onCloseRequested() async {
    if (!_hasContent) return true;
    final action = await showGlassComposeExitDialog(context);
    switch (action) {
      case GlassComposeExitAction.saveDraft:
        await _persistDraft();
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
    if (_videoKey != null && _videoKey!.isNotEmpty) {
      _toast('已选择视频，不能再添加图片');
      return;
    }
    final remaining = maxImages - _imageKeys.length;
    if (remaining <= 0) {
      _toast('最多选择 $maxImages 张图片');
      return;
    }
    setState(() => _uploadingMedia = true);
    try {
      final initial = await ucgPickMoreImagesForCompose(
        context,
        repo: ref.read(ucgRepositoryProvider),
        remainingSlots: remaining,
      );
      if (!mounted || initial == null || initial.isEmpty) return;
      setState(() {
        for (final key in initial.imageKeys) {
          if (_imageKeys.length >= maxImages) break;
          _imageKeys.add(key);
          _trackUpload(key);
        }
      });
    } catch (_) {
      _toast('图片上传失败');
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
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
      final polished = await ref.read(ucgRepositoryProvider).polishPost(
            imageKeys: List.unmodifiable(_imageKeys),
            text: _text.text,
          );
      if (!mounted) return;
      _text.text = polished;
      _toast('已润笔，可继续编辑');
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
    if (text.isEmpty && _imageKeys.isEmpty && (_videoKey == null || _videoKey!.isEmpty)) {
      _toast('请输入内容或添加媒体');
      return;
    }
    if (_busy) {
      _toast('请稍候');
      return;
    }
    setState(() => _publishing = true);
    try {
      await ref.read(ucgRepositoryProvider).createPost(
            text: text,
            imageKeys: _imageKeys,
            videoKey: _videoKey,
          );
      await ref.read(ucgComposeDraftStoreProvider).clear();
      ref.read(ucgPostsChangedProvider.notifier).update((n) => n + 1);
      ref.invalidate(ucgMyProfileProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _toast('发布失败');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _reorderImages(int from, int to) {
    if (from == to || from < 0 || to < 0 || from >= _imageKeys.length || to >= _imageKeys.length) {
      return;
    }
    setState(() {
      final item = _imageKeys.removeAt(from);
      _imageKeys.insert(to, item);
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
    final secondaryColor = ucgComposeLightSecondaryColor(context);

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
                                : const Text('发表'),
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
                                  imageKeys: _imageKeys,
                                  cdnUrls: _imageCdnUrls,
                                  busy: _publishing || _polishing,
                                  addBusy: _uploadingMedia,
                                  canAddMore: _canAddImages,
                                  onAddTap: () => unawaited(_pickImages()),
                                  onReorder: _reorderImages,
                                  onDragStarted: (_) => setState(() => _draggingImage = true),
                                  onDragEnded: () => setState(() => _draggingImage = false),
                                ),
                              ],
                              if (_videoKey != null && _videoKey!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: UcgNetworkImage(
                                        url: UcgMediaUrl.resolveUrl(objectKey: _videoKey!),
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.videocam_rounded, color: secondaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _videoKey!.split('/').last,
                                        style: TextStyle(color: secondaryColor, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _busy ? null : () => unawaited(_removeVideo()),
                                      icon: Icon(Icons.close_rounded, color: secondaryColor),
                                    ),
                                  ],
                                ),
                                if (!widget.textOnly)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '更换视频请关闭并重新从发布入口选择',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryColor.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                              ],
                              if (_showAiPolish) ...[
                                const SizedBox(height: 8),
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
                              if (_uploadingMedia)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '上传中…',
                                    style: TextStyle(fontSize: 12, color: secondaryColor.withValues(alpha: 0.85)),
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
}
