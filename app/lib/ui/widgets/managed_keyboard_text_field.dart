import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_input_bridge.dart';

enum ManagedInputVisibility { visible, hidden }

/// 受管控文本输入：自动对接 [keyboardInputBridgeController] 的 attach/detach/updateDraft。
class ManagedKeyboardTextField extends StatefulWidget {
  const ManagedKeyboardTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.scene,
    this.onConfirm,
    this.onBlurWithoutConfirm,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.decoration,
    this.style,
    this.focusNode,
    this.visibility = ManagedInputVisibility.visible,
    this.blurPolicy,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final String scene;
  final VoidCallback? onConfirm;
  final VoidCallback? onBlurWithoutConfirm;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final InputDecoration? decoration;
  final TextStyle? style;
  final FocusNode? focusNode;
  final ManagedInputVisibility visibility;
  final BlurWithoutConfirmPolicy? blurPolicy;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<ManagedKeyboardTextField> createState() => _ManagedKeyboardTextFieldState();
}

class _ManagedKeyboardTextFieldState extends State<ManagedKeyboardTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    keyboardInputBridgeController.detach(controller: widget.controller);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      keyboardInputBridgeController.attach(
        controller: widget.controller,
        focusNode: _focusNode,
        onConfirm: widget.onConfirm,
        scene: widget.scene,
        obscureText: widget.obscureText,
        hint: widget.hint,
        blurPolicy: widget.blurPolicy,
        onBlurWithoutConfirm: widget.onBlurWithoutConfirm,
      );
      return;
    }
    keyboardInputBridgeController.detach(controller: widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      textInputAction: widget.textInputAction,
      style: widget.style,
      decoration: widget.decoration,
      inputFormatters: widget.inputFormatters,
      onSubmitted: widget.onSubmitted,
      onChanged: (value) {
        keyboardInputBridgeController.updateDraft(value);
        widget.onChanged?.call(value);
      },
    );

    if (widget.visibility == ManagedInputVisibility.hidden) {
      return ExcludeSemantics(
        child: SizedBox(
          width: 1,
          height: 1,
          child: Opacity(opacity: 0, child: field),
        ),
      );
    }

    return field;
  }
}
