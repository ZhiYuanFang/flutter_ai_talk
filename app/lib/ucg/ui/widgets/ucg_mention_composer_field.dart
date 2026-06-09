import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/widgets/keyboard_input_bridge.dart';
import '../../../ui/widgets/managed_keyboard_text_field.dart';
import 'ucg_mention_text.dart';

/// 评论 Composer：控制器仅存展示文本 `@昵称`；发送时由 [wireText] 拼回 `@昵称#wxId`。
class UcgMentionComposerFieldWithHighlight extends StatefulWidget {
  const UcgMentionComposerFieldWithHighlight({
    super.key,
    required this.controller,
    required this.hint,
    required this.scene,
    this.initialWireText,
    this.selfWxId,
    this.enabled = true,
    this.autofocus = false,
    this.onConfirm,
    this.style,
    this.decoration,
    this.textInputAction,
    this.onSubmitted,
    this.anchorKey,
    this.showPreview = true,
  });

  final TextEditingController controller;
  final String? initialWireText;
  final String? selfWxId;
  final String hint;
  final String scene;
  final bool enabled;
  final bool autofocus;
  final VoidCallback? onConfirm;
  final TextStyle? style;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final GlobalKey? anchorKey;
  final bool showPreview;

  @override
  State<UcgMentionComposerFieldWithHighlight> createState() =>
      UcgMentionComposerFieldWithHighlightState();
}

class UcgMentionComposerFieldWithHighlightState
    extends State<UcgMentionComposerFieldWithHighlight> {
  var _applyingAtomicDelete = false;
  String? _mentionNick;
  String? _mentionWxId;
  late final FocusNode _focusNode;
  late final _MentionAtomicDeleteFormatter _atomicDeleteFormatter;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _atomicDeleteFormatter = _MentionAtomicDeleteFormatter(this);
    _bootstrapFromWire(widget.initialWireText ?? widget.controller.text);
    widget.controller.addListener(_onControllerChanged);
  }

  String get wireText => UcgMentionText.toWire(
        widget.controller.text,
        nick: _mentionNick,
        wxId: _mentionWxId,
        selfWxId: widget.selfWxId,
      );

  int? _leadingMentionEndIn(String text) {
    final nick = _mentionNick;
    if (nick == null || nick.isEmpty) return null;

    final core = '@$nick';
    if (text.startsWith(core)) {
      if (text.length > core.length && text[core.length] == ' ') {
        return core.length + 1;
      }
      return core.length;
    }

    if (text.startsWith('@')) {
      final space = text.indexOf(' ');
      if (space >= 0) return space + 1;
      return text.length;
    }

    return null;
  }

  void _clearMention() {
    _mentionNick = null;
    _mentionWxId = null;
  }

  void _bootstrapFromWire(String wire) {
    final parsed = UcgMentionText.parseLeadingMention(wire);
    final selfId = widget.selfWxId?.trim() ?? '';
    final wxId = parsed.wxId?.trim() ?? '';
    if (selfId.isNotEmpty && wxId.isNotEmpty && selfId == wxId) {
      _clearMention();
      widget.controller.text = wire;
      return;
    }
    _mentionNick = parsed.nick;
    _mentionWxId = parsed.wxId;
    if (parsed.nick != null) {
      widget.controller.text = parsed.display;
      widget.controller.selection = TextSelection.collapsed(offset: parsed.display.length);
    }
  }

  @override
  void didUpdateWidget(covariant UcgMentionComposerFieldWithHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _bootstrapFromWire(widget.initialWireText ?? widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  static int? _deletedOffset(String prev, String next) {
    if (next.length != prev.length - 1) return null;
    final minLen = next.length < prev.length ? next.length : prev.length;
    for (var i = 0; i < minLen; i++) {
      if (prev[i] != next[i]) return i;
    }
    return prev.length - 1;
  }

  TextEditingValue applyAtomicMentionDelete(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_applyingAtomicDelete || _mentionNick == null) return newValue;
    if (newValue.text.length >= oldValue.text.length) return newValue;

    final mentionEnd = _leadingMentionEndIn(oldValue.text);
    if (mentionEnd == null || mentionEnd <= 0) return newValue;

    var shouldStripMention = false;

    final deletedAt = _deletedOffset(oldValue.text, newValue.text);
    if (deletedAt != null) {
      shouldStripMention = deletedAt < mentionEnd;
    } else {
      final selection = oldValue.selection;
      if (selection.isValid && !selection.isCollapsed) {
        shouldStripMention = selection.start < mentionEnd;
      }
    }

    if (!shouldStripMention) return newValue;

    _applyingAtomicDelete = true;
    _clearMention();
    final nextText = oldValue.text.substring(mentionEnd);
    _applyingAtomicDelete = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });

    return TextEditingValue(
      text: nextText,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _onControllerChanged() {
    if (_applyingAtomicDelete) return;
    final text = widget.controller.text;
    if (_mentionNick != null && (text.isEmpty || !text.startsWith('@'))) {
      _clearMention();
    }
    setState(() {});
  }

  Widget buildField(BuildContext context) {
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final fieldDecoration = (widget.decoration ?? const InputDecoration()).copyWith(
      hintText: widget.hint,
    );

    return ManagedKeyboardTextField(
      controller: widget.controller,
      focusNode: _focusNode,
      hint: widget.hint,
      scene: widget.scene,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      onConfirm: widget.onConfirm,
      anchorKey: widget.anchorKey,
      textInputAction: widget.textInputAction ?? TextInputAction.newline,
      onSubmitted: widget.onSubmitted,
      blurPolicy: BlurWithoutConfirmPolicy.softSyncDraft,
      style: baseStyle,
      decoration: fieldDecoration,
      inputFormatters: [_atomicDeleteFormatter],
      maxLines: null,
      minLines: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildField(context);
  }
}

class _MentionAtomicDeleteFormatter extends TextInputFormatter {
  _MentionAtomicDeleteFormatter(this.state);

  final UcgMentionComposerFieldWithHighlightState state;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return state.applyAtomicMentionDelete(oldValue, newValue);
  }
}
