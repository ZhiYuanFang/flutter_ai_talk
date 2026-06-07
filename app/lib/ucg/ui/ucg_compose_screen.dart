import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ucg_media_picker.dart';
import '../data/ucg_media_url.dart';
import '../data/ucg_models.dart';
import '../providers/ucg_providers.dart';
import 'widgets/ucg_network_image.dart';
import 'widgets/ucg_visual_widgets.dart';

/// 发布页：文本 + ≤9 图 OR 1 视频（超限自动压缩；视频 ≤15s / 20MB 目标）。
class UcgComposeScreen extends ConsumerStatefulWidget {
  const UcgComposeScreen({super.key, this.editingPost});

  final UcgPost? editingPost;

  @override
  ConsumerState<UcgComposeScreen> createState() => _UcgComposeScreenState();
}

class _UcgComposeScreenState extends ConsumerState<UcgComposeScreen> {
  static const maxImages = 9;

  late final TextEditingController _text;
  final _imageKeys = <String>[];
  final _imageCdnUrls = <String, String>{};
  String? _videoKey;
  var _publishing = false;
  var _uploadingMedia = false;

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
    } else {
      unawaited(_restoreDraft());
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await ref.read(ucgComposeDraftStoreProvider).load();
    if (draft == null || !mounted) return;
    _text.text = draft.text;
    setState(() {
      _imageKeys
        ..clear()
        ..addAll(draft.imageKeys);
      _videoKey = draft.videoKey;
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

  @override
  void dispose() {
    unawaited(_persistDraft());
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
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
      final uploads = await ucgPickAndUploadImages(
        repo: ref.read(ucgRepositoryProvider),
        remainingSlots: remaining,
      );
      if (!mounted || uploads.isEmpty) return;
      setState(() {
        for (final upload in uploads) {
          _imageKeys.add(upload.objectKey);
          final cdn = upload.cdnUrl?.trim();
          if (cdn != null && cdn.isNotEmpty) {
            _imageCdnUrls[upload.objectKey] = cdn;
          }
        }
      });
      unawaited(_persistDraft());
    } catch (e) {
      _toast('图片上传失败');
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_imageKeys.isNotEmpty) {
      _toast('已选择图片，不能再添加视频');
      return;
    }
    setState(() => _uploadingMedia = true);
    try {
      final upload = await ucgPickAndUploadVideo(repo: ref.read(ucgRepositoryProvider));
      if (!mounted) return;
      if (upload == null) return;
      setState(() => _videoKey = upload.objectKey);
      unawaited(_persistDraft());
    } on StateError catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('视频上传失败');
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
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
    if (_uploadingMedia) {
      _toast('媒体上传中，请稍候');
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
    } catch (e) {
      _toast('发布失败');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final busy = _publishing || _uploadingMedia;

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: widget.editingPost == null ? '发布动态' : '编辑动态',
            subtitle: '分享宝宝的可爱瞬间',
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: busy ? null : () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : _publish,
                child: _publishing
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                    : Text('发布', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                UcgShellGlassCard(
                  child: TextField(
                    controller: _text,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: '分享育儿日常…',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                    onChanged: (_) => unawaited(_persistDraft()),
                  ),
                ),
                const SizedBox(height: 12),
                if (_imageKeys.isNotEmpty) ...[
                  UcgShellGlassCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in _imageKeys)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: UcgNetworkImage(
                                  url: UcgMediaUrl.resolveUrl(
                                    objectKey: key,
                                    cdnUrl: _imageCdnUrls[key],
                                  ),
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  iconSize: 20,
                                  onPressed: busy
                                      ? null
                                      : () {
                                          setState(() {
                                            _imageKeys.remove(key);
                                            _imageCdnUrls.remove(key);
                                          });
                                          unawaited(_persistDraft());
                                        },
                                  icon: Icon(Icons.cancel_rounded, color: primary.withValues(alpha: 0.8)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_videoKey != null && _videoKey!.isNotEmpty) ...[
                  UcgShellGlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.videocam_rounded, color: primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_videoKey!.split('/').last)),
                        IconButton(
                          onPressed: busy
                              ? null
                              : () {
                                  setState(() => _videoKey = null);
                                  unawaited(_persistDraft());
                                },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                UcgShellGlassCard(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      UcgInteractionChip(
                        icon: Icons.photo_outlined,
                        label: _uploadingMedia ? '上传中…' : '添加图片',
                        onTap: busy ? null : () => unawaited(_pickImages()),
                      ),
                      UcgInteractionChip(
                        icon: Icons.videocam_outlined,
                        label: '添加视频',
                        onTap: busy ? null : () => unawaited(_pickVideo()),
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
