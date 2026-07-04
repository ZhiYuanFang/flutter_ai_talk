import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_visual_tokens.dart';
import '../../data/ucg_models.dart';
import '../../providers/ucg_providers.dart';
import 'ucg_mention_composer_field.dart';
import 'ucg_visual_widgets.dart';

/// 帖子评论/论点输入 Sheet（广场就地互动与详情页复用）。
Future<void> showUcgPostCommentSheet(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  String? initialText,
  String? title,
  String? hint,
  bool optional = false,
  bool isDebate = false,
  String? myVoteSide,
  Future<void> Function(UcgComment added)? onCommentAdded,
}) {
  final resolvedTitle = title ??
      ((initialText != null && initialText.trim().isNotEmpty) ? '回复评论' : '写评论');
  final resolvedHint = hint ??
      ((initialText != null && initialText.trim().isNotEmpty) ? '回复…' : '写评论…');

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(ctx).bottom + 16,
        ),
        child: UcgPostCommentSheet(
          postId: postId,
          initialText: initialText,
          title: resolvedTitle,
          hint: resolvedHint,
          optional: optional,
          isDebate: isDebate,
          myVoteSide: myVoteSide,
          onCommentAdded: onCommentAdded,
        ),
      );
    },
  );
}

class UcgPostCommentSheet extends ConsumerStatefulWidget {
  const UcgPostCommentSheet({
    super.key,
    required this.postId,
    this.initialText,
    required this.title,
    required this.hint,
    this.optional = false,
    this.isDebate = false,
    this.myVoteSide,
    this.onCommentAdded,
  });

  final String postId;
  final String? initialText;
  final String title;
  final String hint;
  final bool optional;
  final bool isDebate;
  final String? myVoteSide;
  final Future<void> Function(UcgComment added)? onCommentAdded;

  @override
  ConsumerState<UcgPostCommentSheet> createState() => _UcgPostCommentSheetState();
}

class _UcgPostCommentSheetState extends ConsumerState<UcgPostCommentSheet> {
  final _composerKey = GlobalKey<UcgMentionComposerFieldWithHighlightState>();
  final _commentPreviewAnchorKey = GlobalKey();
  late final TextEditingController _controller;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = (_composerKey.currentState?.wireText ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    if (widget.isDebate && (widget.myVoteSide == null || widget.myVoteSide!.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先投票后再发表论点')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final added = await ref.read(ucgRepositoryProvider).addComment(widget.postId, text);
      if (!mounted) return;
      await widget.onCommentAdded?.call(added);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
              ),
            ),
            if (widget.optional)
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: const Text('跳过'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        UcgPageComposerChrome(
          controller: _controller,
          enabled: !_sending,
          busy: _sending,
          confirmLabel: '发送',
          onConfirm: _sending ? null : () => unawaited(_send()),
          padding: EdgeInsets.zero,
          field: UcgMentionComposerFieldWithHighlight(
            key: _composerKey,
            controller: _controller,
            initialWireText: widget.initialText,
            selfWxId: ref.watch(ucgCurrentUserIdProvider),
            autofocus: true,
            enabled: !_sending,
            hint: widget.hint,
            scene: 'ucg.post.comment',
            anchorKey: _commentPreviewAnchorKey,
            onConfirm: _sending ? null : () => unawaited(_send()),
            style: TextStyle(color: fg),
            textInputAction: TextInputAction.newline,
            decoration: ucgComposerFieldDecoration(context, hint: widget.hint),
          ),
        ),
      ],
    );
  }
}
