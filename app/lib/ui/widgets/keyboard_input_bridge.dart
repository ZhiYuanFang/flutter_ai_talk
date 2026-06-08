import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ucg_emoji_data.dart';

enum InputMode { keyboard, emoji }

enum BlurWithoutConfirmPolicy {
  /// Legacy behavior: detach without changing controller or calling onConfirm.
  defaultPolicy,

  /// Restore controller text from attach-time snapshot (profile nickname/bio).
  discardRestoreSnapshot,

  /// Write draft back to controller without onConfirm (chat/comment/compose).
  softSyncDraft,
}

BlurWithoutConfirmPolicy resolveBlurPolicyForScene(String scene) {
  switch (scene) {
    case 'ucg.profile.nickname':
    case 'ucg.profile.bio':
      return BlurWithoutConfirmPolicy.discardRestoreSnapshot;
    case 'ucg.chat':
    case 'ucg.post.comment':
    case 'ucg.compose.body':
      return BlurWithoutConfirmPolicy.softSyncDraft;
    default:
      return BlurWithoutConfirmPolicy.defaultPolicy;
  }
}

class KeyboardInputBinding {
  const KeyboardInputBinding({
    required this.controller,
    required this.focusNode,
    required this.onConfirm,
    required this.scene,
    required this.obscureText,
    required this.hint,
    required this.blurPolicy,
    this.onBlurWithoutConfirm,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onConfirm;
  final String scene;
  final bool obscureText;
  final String hint;
  final BlurWithoutConfirmPolicy blurPolicy;
  final VoidCallback? onBlurWithoutConfirm;
}

class KeyboardInputBridgeController extends ChangeNotifier {
  KeyboardInputBinding? _binding;
  String _draftText = '';
  String _snapshotText = '';
  InputMode _inputMode = InputMode.keyboard;
  bool _confirmed = false;
  double _lastKeyboardInset = 0;

  KeyboardInputBinding? get binding => _binding;
  bool get hasBinding => _binding != null;
  String get draftText => _draftText;
  InputMode get inputMode => _inputMode;
  double get lastKeyboardInset => _lastKeyboardInset;

  bool get isUcgScene => _binding?.scene.startsWith('ucg.') ?? false;

  bool get canInsertNewline {
    final binding = _binding;
    if (binding == null) return false;
    if (binding.obscureText) return false;
    if (binding.scene == 'ucg.profile.nickname') return false;
    return binding.scene.startsWith('ucg.');
  }

  String get visibleText {
    final b = _binding;
    if (b == null) return '';
    if (!b.obscureText) return _draftText;
    if (_draftText.isEmpty) return '';
    return List<String>.filled(_draftText.runes.length, '•').join();
  }

  String get hint => _binding?.hint ?? '';

  bool get showsHintPlaceholder => visibleText.isEmpty && hint.isNotEmpty;

  void noteKeyboardInset(double keyboardBottom) {
    if (keyboardBottom > 0) {
      _lastKeyboardInset = keyboardBottom;
    }
  }

  bool overlayVisible(double keyboardBottom) {
    if (!hasBinding) return false;
    return keyboardBottom > 0 || _inputMode == InputMode.emoji;
  }

  void attach({
    required TextEditingController controller,
    required FocusNode focusNode,
    VoidCallback? onConfirm,
    String scene = '',
    bool obscureText = false,
    String hint = '',
    BlurWithoutConfirmPolicy? blurPolicy,
    VoidCallback? onBlurWithoutConfirm,
  }) {
    _binding = KeyboardInputBinding(
      controller: controller,
      focusNode: focusNode,
      onConfirm: onConfirm,
      scene: scene,
      obscureText: obscureText,
      hint: hint,
      blurPolicy: blurPolicy ?? resolveBlurPolicyForScene(scene),
      onBlurWithoutConfirm: onBlurWithoutConfirm,
    );
    _snapshotText = controller.text;
    _draftText = controller.text;
    _inputMode = InputMode.keyboard;
    _confirmed = false;
    notifyListeners();
  }

  void updateDraft(String text) {
    if (_binding == null) return;
    if (_draftText == text) return;
    _draftText = text;
    notifyListeners();
  }

  void setInputMode(InputMode mode) {
    if (_binding == null || _inputMode == mode) return;
    _inputMode = mode;
    if (mode == InputMode.emoji) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    } else {
      _binding!.focusNode.requestFocus();
    }
    notifyListeners();
  }

  void toggleInputMode() {
    setInputMode(_inputMode == InputMode.keyboard ? InputMode.emoji : InputMode.keyboard);
  }

  void insertAtCursor(String text) {
    final binding = _binding;
    if (binding == null || text.isEmpty) return;
    final controller = binding.controller;
    final value = controller.value;
    final selection = value.selection;
    final start = selection.start >= 0 ? selection.start : value.text.length;
    final end = selection.end >= 0 ? selection.end : value.text.length;
    final newText = value.text.replaceRange(start, end, text);
    final newOffset = start + text.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    updateDraft(newText);
  }

  void insertNewlineAtSelection() {
    if (!canInsertNewline) return;
    insertAtCursor('\n');
  }

  void _applyBlurPolicy() {
    final binding = _binding;
    if (binding == null) return;
    switch (binding.blurPolicy) {
      case BlurWithoutConfirmPolicy.discardRestoreSnapshot:
        binding.controller.value = TextEditingValue(
          text: _snapshotText,
          selection: TextSelection.collapsed(offset: _snapshotText.length),
        );
      case BlurWithoutConfirmPolicy.softSyncDraft:
        final text = _draftText;
        if (binding.controller.text != text) {
          binding.controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      case BlurWithoutConfirmPolicy.defaultPolicy:
        break;
    }
  }

  void detach({TextEditingController? controller}) {
    final binding = _binding;
    if (binding == null) return;
    if (controller != null && binding.controller != controller) return;

    if (!_confirmed) {
      _applyBlurPolicy();
      binding.onBlurWithoutConfirm?.call();
    }

    _binding = null;
    _draftText = '';
    _snapshotText = '';
    _inputMode = InputMode.keyboard;
    _confirmed = false;
    notifyListeners();
  }

  void confirm() {
    final binding = _binding;
    if (binding == null) return;
    _confirmed = true;
    final text = _draftText;
    final controller = binding.controller;
    if (controller.text != text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    binding.onConfirm?.call();
    if (binding.focusNode.hasFocus) {
      binding.focusNode.unfocus();
    }
    detach(controller: controller);
  }
}

final keyboardInputBridgeController = KeyboardInputBridgeController();

class KeyboardInputConfirmBarOverlay extends StatelessWidget {
  const KeyboardInputConfirmBarOverlay({super.key});

  static const double _emojiPanelHeight = 220;
  static const int _draftMaxLines = 5;

  Future<void> _showNewlineMenu(BuildContext context, Offset position) async {
    final bridge = keyboardInputBridgeController;
    if (!bridge.canInsertNewline) return;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: const [
        PopupMenuItem<String>(value: 'newline', child: Text('换行')),
      ],
    );
    if (selected == 'newline') {
      bridge.insertNewlineAtSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: keyboardInputBridgeController,
      builder: (context, _) {
        final bridge = keyboardInputBridgeController;
        final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
        bridge.noteKeyboardInset(keyboardBottom);
        final visible = bridge.overlayVisible(keyboardBottom);
        final emojiMode = bridge.inputMode == InputMode.emoji;

        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            offset: visible ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: visible ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: emojiMode ? MediaQuery.paddingOf(context).bottom : keyboardBottom),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 8,
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      minimum: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (bridge.isUcgScene) ...[
                                IconButton(
                                  tooltip: emojiMode ? '键盘' : '表情',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: bridge.toggleInputMode,
                                  icon: Icon(emojiMode ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: _DraftMirror(
                                  maxLines: _draftMaxLines,
                                  onLongPress: bridge.canInsertNewline
                                      ? (position) => _showNewlineMenu(context, position)
                                      : null,
                                ),
                              ),
                              if (kIsWeb && bridge.canInsertNewline) ...[
                                IconButton(
                                  tooltip: '换行',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: bridge.insertNewlineAtSelection,
                                  icon: const Icon(Icons.wrap_text_rounded),
                                ),
                              ],
                              const SizedBox(width: 4),
                              FilledButton(
                                onPressed: bridge.confirm,
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                          if (emojiMode)
                            SizedBox(
                              height: _emojiPanelHeight,
                              child: GridView.builder(
                                padding: const EdgeInsets.only(top: 8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                ),
                                itemCount: kUcgCommonEmojis.length,
                                itemBuilder: (context, index) {
                                  final emoji = kUcgCommonEmojis[index];
                                  return InkWell(
                                    onTap: () => bridge.insertAtCursor(emoji),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Center(
                                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DraftMirror extends StatelessWidget {
  const _DraftMirror({
    required this.maxLines,
    this.onLongPress,
  });

  final int maxLines;
  final void Function(Offset position)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final bridge = keyboardInputBridgeController;
    final text = bridge.showsHintPlaceholder ? bridge.hint : bridge.visibleText;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: bridge.showsHintPlaceholder
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        );

    final child = Container(
      constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Text(
          text,
          maxLines: maxLines,
          style: style,
        ),
      ),
    );

    if (onLongPress == null) return child;

    return GestureDetector(
      onLongPressStart: (details) => onLongPress!(details.globalPosition),
      child: child,
    );
  }
}
