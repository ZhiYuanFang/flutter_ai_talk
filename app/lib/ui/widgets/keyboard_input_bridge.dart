import 'package:flutter/material.dart';

class KeyboardInputBinding {
  const KeyboardInputBinding({
    required this.controller,
    required this.focusNode,
    required this.onConfirm,
    required this.scene,
    required this.obscureText,
    required this.hint,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onConfirm;
  final String scene;
  final bool obscureText;
  final String hint;
}

class KeyboardInputBridgeController extends ChangeNotifier {
  KeyboardInputBinding? _binding;
  String _draftText = '';

  KeyboardInputBinding? get binding => _binding;
  bool get hasBinding => _binding != null;
  String get draftText => _draftText;

  String get visibleText {
    final b = _binding;
    if (b == null) return '';
    if (!b.obscureText) return _draftText;
    if (_draftText.isEmpty) return '';
    return List<String>.filled(_draftText.runes.length, '•').join();
  }

  String get hint => _binding?.hint ?? '';

  bool get showsHintPlaceholder => visibleText.isEmpty && hint.isNotEmpty;

  void attach({
    required TextEditingController controller,
    required FocusNode focusNode,
    VoidCallback? onConfirm,
    String scene = '',
    bool obscureText = false,
    String hint = '',
  }) {
    _binding = KeyboardInputBinding(
      controller: controller,
      focusNode: focusNode,
      onConfirm: onConfirm,
      scene: scene,
      obscureText: obscureText,
      hint: hint,
    );
    _draftText = controller.text;
    notifyListeners();
  }

  void updateDraft(String text) {
    if (_binding == null) return;
    if (_draftText == text) return;
    _draftText = text;
    notifyListeners();
  }

  void detach({TextEditingController? controller}) {
    final binding = _binding;
    if (binding == null) return;
    if (controller != null && binding.controller != controller) return;
    _binding = null;
    _draftText = '';
    notifyListeners();
  }

  void confirm() {
    final binding = _binding;
    if (binding == null) return;
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: keyboardInputBridgeController,
      builder: (context, _) {
        final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
        final visible = keyboardBottom > 0 && keyboardInputBridgeController.hasBinding;

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
                  padding: EdgeInsets.only(bottom: keyboardBottom),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 8,
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                keyboardInputBridgeController.showsHintPlaceholder
                                    ? keyboardInputBridgeController.hint
                                    : keyboardInputBridgeController.visibleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: keyboardInputBridgeController.showsHintPlaceholder
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : null,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: keyboardInputBridgeController.confirm,
                            child: const Text('确定'),
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
