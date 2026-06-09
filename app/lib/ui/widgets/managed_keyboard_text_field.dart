import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_input_bridge.dart';
import 'keyboard_dismiss_scope.dart';
import 'keyboard_lift.dart';

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
    this.overlayConfig,
    this.anchorKey,
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
  final KeyboardOverlayConfig? overlayConfig;
  /// 顶组件滚动锚点；若省略则默认锚定本输入框。
  /// 可与页面其它位置同一 [GlobalKey]（如资料页可见昵称/简介区）。
  final GlobalKey? anchorKey;

  @override
  State<ManagedKeyboardTextField> createState() => ManagedKeyboardTextFieldState();
}

class ManagedKeyboardTextFieldState extends State<ManagedKeyboardTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  late KeyboardOverlayConfig _config;
  final GlobalKey _fieldLiftAnchorKey = GlobalKey();

  GlobalKey get _liftAnchorKey => widget.anchorKey ?? _fieldLiftAnchorKey;

  bool get _usesOverlayEditorOnly => _config.showInputField;

  @override
  void initState() {
    super.initState();
    _config = widget.overlayConfig ?? resolveOverlayConfig(widget.scene);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    if (widget.autofocus && _usesOverlayEditorOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _beginOverlayEditorSession();
      });
    } else if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ManagedKeyboardTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _config = widget.overlayConfig ?? resolveOverlayConfig(widget.scene);
    if (_usesOverlayEditorOnly &&
        widget.enabled &&
        !oldWidget.enabled &&
        keyboardInputBridgeController.binding?.controller != widget.controller) {
      _beginOverlayEditorSession();
    }
    if (_focusNode.hasFocus &&
        keyboardInputBridgeController.binding?.controller == widget.controller) {
      keyboardInputBridgeController.refreshBindingCallbacks(
        onConfirm: widget.onConfirm,
        onBlurWithoutConfirm: widget.onBlurWithoutConfirm,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    keyboardInputBridgeController.dismiss(controller: widget.controller);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _attachToBridge();
      return;
    }
    if (keyboardInputBridgeController.shouldSkipDetachOnFocusLoss(widget.controller)) {
      return;
    }
    keyboardInputBridgeController.detach(controller: widget.controller, force: true);
  }

  void _attachToBridge() {
    final alreadyBound = keyboardInputBridgeController.binding?.controller == widget.controller &&
        keyboardInputBridgeController.binding?.focusNode == _focusNode;
    keyboardInputBridgeController.attach(
      controller: widget.controller,
      focusNode: _focusNode,
      onConfirm: widget.onConfirm,
      scene: widget.scene,
      obscureText: widget.obscureText,
      hint: widget.hint,
      blurPolicy: widget.blurPolicy,
      onBlurWithoutConfirm: widget.onBlurWithoutConfirm,
      overlayConfig: _config,
      anchorKey: _liftAnchorKey,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_usesOverlayEditorOnly) {
        keyboardInputBridgeController.ensureBindingEditorFocus();
        if (!alreadyBound) {
          keyboardInputBridgeController.requestKeyboard();
        }
      }
      keyboardInputBridgeController.liftAnchor(context);
    });
  }

  /// overlay-primary 无页面 TextField：先 attach 浮层，再由浮层 TextField 接管 focusNode。
  /// overlay-primary：打开浮层编辑会话（页面无 TextField 时由外部调用）。
  void beginEditorSession() => _beginOverlayEditorSession();

  void _beginOverlayEditorSession() {
    if (!widget.enabled) return;
    _attachToBridge();
  }

  void _requestFocusFromTap() {
    if (!widget.enabled) return;
    if (_usesOverlayEditorOnly) {
      if (keyboardInputBridgeController.binding?.controller != widget.controller) {
        _beginOverlayEditorSession();
        return;
      }
      keyboardInputBridgeController.revealSystemKeyboardFromFieldTap();
      return;
    }
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      return;
    }
    keyboardInputBridgeController.revealSystemKeyboardFromFieldTap();
  }

  Widget _buildOverlayEditorAttachHost() {
    final tapTarget = Listener(
      onPointerDown: (event) {
        noteKeyboardLiftTap(_focusNode, event.position);
        _requestFocusFromTap();
      },
      child: widget.visibility == ManagedInputVisibility.hidden
          ? const ExcludeSemantics(
              child: SizedBox(width: 1, height: 1),
            )
          : const SizedBox.expand(),
    );

    if (widget.anchorKey != null) {
      return KeyboardDismissExclude(child: tapTarget);
    }
    return KeyboardDismissExclude(
      child: KeyedSubtree(key: _fieldLiftAnchorKey, child: tapTarget),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usesOverlayEditorOnly) {
      return _buildOverlayEditorAttachHost();
    }

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
      onTap: keyboardInputBridgeController.revealSystemKeyboardFromFieldTap,
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

    if (widget.anchorKey != null) {
      return KeyboardDismissExclude(
        child: Listener(
          onPointerDown: (event) => noteKeyboardLiftTap(_focusNode, event.position),
          child: field,
        ),
      );
    }
    return KeyboardDismissExclude(
      child: Listener(
        onPointerDown: (event) => noteKeyboardLiftTap(_focusNode, event.position),
        child: KeyedSubtree(key: _fieldLiftAnchorKey, child: field),
      ),
    );
  }
}
