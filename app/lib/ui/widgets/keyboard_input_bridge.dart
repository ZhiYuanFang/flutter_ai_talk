import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_dismiss_scope.dart';
import 'keyboard_lift.dart';
import 'ucg_emoji_data.dart';

enum InputTarget { keyboard, emoji }

/// Legacy alias (specs / external readers).
typedef InputMode = InputTarget;

/// Derived bottom UI from [InputTarget] + raw viewInsets (read-only).
enum BottomSurface {
  none,
  emojiPanel,
  keyboardPending,
  systemKeyboard,
}

enum BlurWithoutConfirmPolicy {
  defaultPolicy,
  discardRestoreSnapshot,
  softSyncDraft,
}

/// Shared overlay layout constants (Android/iOS identical logical px).
abstract final class KeyboardOverlayMetrics {
  static const double accessoryBarHeight = 44;
  static const double editorMinHeight = 36;
  static const double editorMaxHeight = 72;
  static const int editorMaxLines = 2;
  static const double barPaddingH = 8;
  static const double barPaddingV = 4;
  static const double emojiPanelMinHeight = 200;
  static const double emojiGridCrossCount = 8;
  static const double emojiFontSize = 22;
  static const double mediaStripHeight = 56;
  static const double confirmMinWidth = 52;
  static const double confirmHeight = 36;
  static const double iconButtonSize = 36;

  static double emojiPanelHeight(double lastKeyboardInset) {
    return math.max(emojiPanelMinHeight, lastKeyboardInset - accessoryBarHeight);
  }
}

class KeyboardOverlayConfig {
  const KeyboardOverlayConfig({
    this.showEmoji = false,
    this.showMultimedia = false,
    this.showInputField = false,
    this.showConfirmButton = false,
    this.confirmLabel = '确定',
  });

  final bool showEmoji;
  final bool showMultimedia;
  final bool showInputField;
  final bool showConfirmButton;
  final String confirmLabel;

  bool get anyEnabled =>
      showEmoji || showMultimedia || showInputField || showConfirmButton;

  static const none = KeyboardOverlayConfig();
}

KeyboardOverlayConfig resolveOverlayConfig(String scene) {
  switch (scene) {
    case 'ucg.chat':
    case 'login.account':
    case 'login.password':
    case 'register.account':
    case 'register.password':
    case 'register.confirm-password':
    case 'change-password.old':
    case 'change-password.new':
    case 'baby-bind.device-id':
    case 'baby-bind.nickname':
    case 'baby-profile.nickname':
      return KeyboardOverlayConfig.none;
    case 'ucg.compose.body':
    case 'home.history-edit.remark':
    case 'home.number.remark':
      return const KeyboardOverlayConfig(showEmoji: true);
    case 'ucg.post.comment':
    case 'home.text':
    case 'ucg.profile.nickname':
    case 'ucg.profile.bio':
      return KeyboardOverlayConfig.none;
  }
  if (scene.startsWith('login.') ||
      scene.startsWith('register.') ||
      scene.startsWith('change-password.') ||
      scene.startsWith('baby-bind.') ||
      scene == 'baby-profile.nickname') {
    return KeyboardOverlayConfig.none;
  }
  return const KeyboardOverlayConfig(
    showInputField: true,
    showConfirmButton: true,
  );
}

BlurWithoutConfirmPolicy resolveBlurPolicyForScene(String scene) {
  switch (scene) {
    case 'ucg.profile.nickname':
    case 'ucg.profile.bio':
      return BlurWithoutConfirmPolicy.discardRestoreSnapshot;
    case 'ucg.post.comment':
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
    required this.overlayConfig,
    this.onBlurWithoutConfirm,
    this.anchorKey,
    this.inputFormatters,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onConfirm;
  final String scene;
  final bool obscureText;
  final String hint;
  final BlurWithoutConfirmPolicy blurPolicy;
  final KeyboardOverlayConfig overlayConfig;
  final VoidCallback? onBlurWithoutConfirm;
  final GlobalKey? anchorKey;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
}

class KeyboardInputBridgeController extends ChangeNotifier {
  KeyboardInputBinding? _binding;
  String _draftText = '';
  String _snapshotText = '';
  InputTarget _target = InputTarget.keyboard;
  bool _confirmed = false;
  /// 当前 binding 内见过的最大键盘高度，切换 emoji 时作占位，不在动画中回落。
  double _peakKeyboardInset = 0;

  KeyboardInputBinding? get binding => _binding;
  bool get hasBinding => _binding != null;
  String get draftText => _draftText;
  InputTarget get target => _target;
  InputMode get inputMode => _target;
  double get lastKeyboardInset => _peakKeyboardInset;
  double get peakKeyboardInset => _peakKeyboardInset;
  KeyboardOverlayConfig? get overlayConfig => _binding?.overlayConfig;

  bool get canInsertNewline {
    final binding = _binding;
    if (binding == null) return false;
    if (binding.obscureText) return false;
    if (binding.scene == 'ucg.profile.nickname') return false;
    return binding.scene.startsWith('ucg.') || binding.scene == 'home.text';
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

  double get accessoryChromeHeight {
    final config = _binding?.overlayConfig;
    if (config == null || !config.anyEnabled) return 0;
    var height = KeyboardOverlayMetrics.accessoryBarHeight + KeyboardOverlayMetrics.barPaddingV * 2;
    if (config.showMultimedia) {
      height += KeyboardOverlayMetrics.mediaStripHeight;
    }
    return height;
  }

  double get overlayChromeHeight => accessoryChromeHeight;

  /// emoji 模式占位高度：binding 内键盘峰值，避免切换/动画中高度震荡。
  double get emojiPanelSlotHeight {
    if (_peakKeyboardInset > 0) return _peakKeyboardInset;
    return KeyboardOverlayMetrics.emojiPanelMinHeight;
  }

  void noteKeyboardInset(double keyboardBottom) {
    if (keyboardBottom > _peakKeyboardInset) {
      _peakKeyboardInset = keyboardBottom;
    }
  }

  /// 由用户意图 + 原始 inset 推导当前底部展示面（只读）。
  BottomSurface bottomSurface(double rawKeyboardBottom) {
    final binding = _binding;
    if (binding == null) return BottomSurface.none;
    if (!binding.overlayConfig.showEmoji) {
      if (_target == InputTarget.emoji) {
        if (rawKeyboardBottom <= 0) return BottomSurface.emojiPanel;
        return BottomSurface.keyboardPending;
      }
      return rawKeyboardBottom > 0 ? BottomSurface.systemKeyboard : BottomSurface.none;
    }
    if (_target == InputTarget.emoji) {
      if (rawKeyboardBottom <= 0) return BottomSurface.emojiPanel;
      return BottomSurface.keyboardPending;
    }
    if (rawKeyboardBottom > 0) return BottomSurface.systemKeyboard;
    if (_peakKeyboardInset > 0) return BottomSurface.keyboardPending;
    return BottomSurface.none;
  }

  /// 底部正在展示 emoji 面板（网格可见）。
  bool isEmojiPanelDisplayed(double rawKeyboardBottom) {
    return bottomSurface(rawKeyboardBottom) == BottomSurface.emojiPanel;
  }

  /// 左上角展示「键盘」图标：底部非系统键盘（emoji 或 pending 占位）。
  bool accessoryShowsKeyboardIcon(double rawKeyboardBottom) {
    if (!hasBinding) return false;
    if (!_binding!.overlayConfig.showEmoji) {
      return bottomSurface(rawKeyboardBottom) == BottomSurface.emojiPanel;
    }
    return bottomSurface(rawKeyboardBottom) != BottomSurface.systemKeyboard;
  }

  /// 左上角展示「表情」图标：系统键盘已弹出。
  bool accessoryShowsEmojiIcon(double rawKeyboardBottom) {
    if (!hasBinding || !_binding!.overlayConfig.showEmoji) return false;
    return bottomSurface(rawKeyboardBottom) == BottomSurface.systemKeyboard;
  }

  /// 当前为系统键盘输入态（只读，用于布局/占位）。
  bool isKeyboardInputDisplayed(double rawKeyboardBottom) {
    if (!hasBinding || !_binding!.overlayConfig.showEmoji) {
      return rawKeyboardBottom > 0;
    }
    return bottomSurface(rawKeyboardBottom) == BottomSurface.systemKeyboard;
  }

  /// emoji / 键盘切换时用峰值 inset 占位，防止 Sheet 高度震荡。
  double effectiveViewInsetBottom(double rawViewInsetBottom) {
    if (!hasBinding || _peakKeyboardInset <= 0) return rawViewInsetBottom;
    final config = _binding!.overlayConfig;
    if (!config.showEmoji) return rawViewInsetBottom;

    final surface = bottomSurface(rawViewInsetBottom);
    if (surface == BottomSurface.emojiPanel || surface == BottomSurface.keyboardPending) {
      return math.max(rawViewInsetBottom, _peakKeyboardInset);
    }
    if (rawViewInsetBottom < _peakKeyboardInset - 0.5) {
      return _peakKeyboardInset;
    }
    return rawViewInsetBottom;
  }

  bool holdsKeyboardSlot(double rawKeyboardBottom) {
    if (!hasBinding) return false;
    if (!_binding!.overlayConfig.showEmoji || _peakKeyboardInset <= 0) return false;
    final surface = bottomSurface(rawKeyboardBottom);
    if (surface == BottomSurface.emojiPanel || surface == BottomSurface.keyboardPending) {
      return true;
    }
    return rawKeyboardBottom < _peakKeyboardInset - 0.5;
  }

  bool overlayVisible(double keyboardBottom) {
    final config = _binding?.overlayConfig;
    if (!hasBinding || config == null || !config.anyEnabled) return false;
    final surface = bottomSurface(keyboardBottom);
    if (surface != BottomSurface.none) return true;
    if (keyboardBottom > 0) return true;
    if (holdsKeyboardSlot(keyboardBottom)) return true;
    // 页面内可编辑 + 仅 emoji 浮层：聚焦期间始终显示 accessory。
    if (config.showEmoji) {
      return _binding!.focusNode.hasFocus;
    }
    return false;
  }

  bool shouldSkipDetachOnFocusLoss(TextEditingController controller) {
    if (_binding?.controller != controller) return false;
    final raw = readRawViewInsetBottom(
      _binding!.anchorKey?.currentContext ?? _binding!.focusNode.context,
    );
    final surface = bottomSurface(raw);
    if (surface == BottomSurface.keyboardPending || surface == BottomSurface.emojiPanel) {
      return true;
    }
    if (_target == InputTarget.emoji) return true;
    return false;
  }

  bool get shouldApplyBlurOnDetach {
    final config = _binding?.overlayConfig;
    if (config == null) return true;
    if (!config.showConfirmButton && !config.showInputField) return false;
    return true;
  }

  void _releaseInputFocus(KeyboardInputBinding binding) {
    if (binding.focusNode.hasFocus) {
      binding.focusNode.unfocus();
    }
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
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
    KeyboardOverlayConfig? overlayConfig,
    GlobalKey? anchorKey,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
  }) {
    final config = overlayConfig ?? resolveOverlayConfig(scene);
    final existing = _binding;
    if (existing != null &&
        existing.controller == controller &&
        existing.focusNode == focusNode &&
        existing.scene == scene) {
      refreshBindingCallbacks(
        onConfirm: onConfirm,
        onBlurWithoutConfirm: onBlurWithoutConfirm,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
      );
      if (anchorKey != null && existing.anchorKey != anchorKey) {
        _binding = KeyboardInputBinding(
          controller: existing.controller,
          focusNode: existing.focusNode,
          onConfirm: onConfirm ?? existing.onConfirm,
          scene: existing.scene,
          obscureText: existing.obscureText,
          hint: existing.hint,
          blurPolicy: existing.blurPolicy,
          overlayConfig: existing.overlayConfig,
          onBlurWithoutConfirm: onBlurWithoutConfirm ?? existing.onBlurWithoutConfirm,
          anchorKey: anchorKey,
          inputFormatters: inputFormatters ?? existing.inputFormatters,
          textInputAction: textInputAction ?? existing.textInputAction,
        );
      }
      return;
    }
    _binding = KeyboardInputBinding(
      controller: controller,
      focusNode: focusNode,
      onConfirm: onConfirm,
      scene: scene,
      obscureText: obscureText,
      hint: hint,
      blurPolicy: blurPolicy ?? resolveBlurPolicyForScene(scene),
      overlayConfig: config,
      onBlurWithoutConfirm: onBlurWithoutConfirm,
      anchorKey: anchorKey,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
    );
    _snapshotText = controller.text;
    _draftText = controller.text;
    _target = InputTarget.keyboard;
    _peakKeyboardInset = 0;
    _confirmed = false;
    notifyListeners();
  }

  /// overlay-primary：确保浮层 TextField 获焦；仅当 target 为 keyboard 时才弹 IME。
  void activateOverlayEditor() {
    ensureBindingEditorFocus();
    final binding = _binding;
    if (binding == null || _target != InputTarget.keyboard) return;
    _showSystemKeyboard(binding);
  }

  /// overlay-primary：浮层 TextField 挂载后确保 binding focus 与 IME 连接。
  void ensureBindingEditorFocus() {
    final binding = _binding;
    if (binding == null || !binding.overlayConfig.showInputField) return;
    if (!binding.focusNode.hasFocus) {
      binding.focusNode.requestFocus();
    }
  }

  /// @deprecated Use [ensureBindingEditorFocus].
  void requestOverlayFocus() => ensureBindingEditorFocus();

  /// 键盘 pending 过渡期间，忽略外部点击 dismiss（配合 pointerDown 追踪）。
  bool shouldSuppressOutsideDismissFor(double rawKeyboardBottom) {
    if (_target == InputTarget.emoji) return true;
    return bottomSurface(rawKeyboardBottom) == BottomSurface.keyboardPending;
  }

  bool get shouldSuppressOutsideDismiss {
    return shouldSuppressOutsideDismissFor(readRawViewInsetBottom(null));
  }

  void refreshBindingCallbacks({
    VoidCallback? onConfirm,
    VoidCallback? onBlurWithoutConfirm,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
  }) {
    final binding = _binding;
    if (binding == null) return;
    _binding = KeyboardInputBinding(
      controller: binding.controller,
      focusNode: binding.focusNode,
      onConfirm: onConfirm ?? binding.onConfirm,
      scene: binding.scene,
      obscureText: binding.obscureText,
      hint: binding.hint,
      blurPolicy: binding.blurPolicy,
      overlayConfig: binding.overlayConfig,
      onBlurWithoutConfirm: onBlurWithoutConfirm ?? binding.onBlurWithoutConfirm,
      anchorKey: binding.anchorKey,
      inputFormatters: inputFormatters ?? binding.inputFormatters,
      textInputAction: textInputAction ?? binding.textInputAction,
    );
  }

  void liftAnchor(BuildContext context) {
    final binding = _binding;
    if (binding == null) return;

    final keyboardBottom = readRawViewInsetBottom(context);
    final overlayChrome =
        overlayVisible(keyboardBottom) ? accessoryChromeHeight.toDouble() : 0.0;

    scheduleKeyboardLift(
      context: context,
      focusNode: binding.focusNode,
      anchorKey: binding.anchorKey,
      keyboardOverlayChrome: overlayChrome,
    );
  }

  void updateDraft(String text) {
    if (_binding == null) return;
    if (_draftText == text) return;
    _draftText = text;
    final binding = _binding!;
    if (binding.controller.text != text) {
      binding.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    notifyListeners();
  }

  /// 点输入框：切 keyboard 并弹出系统键盘。
  void revealSystemKeyboardFromFieldTap() {
    if (_binding == null) return;
    final raw = readRawViewInsetBottom(
      _binding!.anchorKey?.currentContext ?? _binding!.focusNode.context,
    );
    if (_target == InputTarget.keyboard &&
        bottomSurface(raw) == BottomSurface.systemKeyboard &&
        _binding!.focusNode.hasFocus) {
      return;
    }
    requestKeyboard();
  }

  void requestEmoji() {
    if (_binding == null) return;
    final binding = _binding!;
    if (_target == InputTarget.emoji) {
      final raw = readRawViewInsetBottom(
        binding.anchorKey?.currentContext ?? binding.focusNode.context,
      );
      if (bottomSurface(raw) == BottomSurface.emojiPanel) return;
    }
    _target = InputTarget.emoji;
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    notifyListeners();
    _scheduleLiftAfterModeChange(binding);
    // 页面内 composer：收起键盘后保持 focus，避免 dismiss/detach 导致 emoji 面板不出现。
    if (!binding.overlayConfig.anyEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_binding?.focusNode != binding.focusNode) return;
        if (!binding.focusNode.hasFocus) {
          binding.focusNode.requestFocus();
        }
        notifyListeners();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_binding == null || _target != InputTarget.emoji) return;
        notifyListeners();
      });
    }
  }

  void requestKeyboard() {
    if (_binding == null) return;
    final binding = _binding!;
    _target = InputTarget.keyboard;
    notifyListeners();
    _showSystemKeyboard(binding);
    _scheduleLiftAfterModeChange(binding);
  }

  /// @deprecated Use [requestKeyboard].
  void showKeyboardInput() => requestKeyboard();

  /// @deprecated Use [requestEmoji].
  void showEmojiPanel() => requestEmoji();

  /// 点击左上角图标：根据当前 bottomSurface 切换到另一种输入。
  void onAccessoryIconPressed([double? rawKeyboardBottom]) {
    final raw = rawKeyboardBottom ?? readRawViewInsetBottom(null);
    if (accessoryShowsKeyboardIcon(raw)) {
      requestKeyboard();
      return;
    }
    requestEmoji();
  }

  void _showSystemKeyboard(KeyboardInputBinding binding) {
    if (!binding.focusNode.hasFocus) {
      binding.focusNode.requestFocus();
    }
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_binding == null) return;
      if (_target != InputTarget.keyboard) return;
      if (!binding.focusNode.hasFocus) {
        binding.focusNode.requestFocus();
      }
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  void _scheduleLiftAfterModeChange(KeyboardInputBinding binding) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = binding.anchorKey?.currentContext ?? binding.focusNode.context;
      if (ctx != null && ctx.mounted) {
        liftAnchor(ctx);
      }
    });
  }

  /// 窗口 inset 变化时同步峰值并刷新浮层（overlay 可能尚未读到键盘高度）。
  void onWindowInsetsChanged() {
    if (!hasBinding) return;
    final bottom = readRawViewInsetBottom(null);
    final prevPeak = _peakKeyboardInset;
    noteKeyboardInset(bottom);
    if (bottom != prevPeak ||
        bottom > 0 ||
        bottomSurface(bottom) != BottomSurface.none) {
      notifyListeners();
    }
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
    if (!shouldApplyBlurOnDetach) return;
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

  void detach({TextEditingController? controller, bool force = false}) {
    final binding = _binding;
    if (binding == null) return;
    if (controller != null && binding.controller != controller) return;
    if (!force && _target == InputTarget.emoji) return;

    if (force) {
      _releaseInputFocus(binding);
    }

    if (!_confirmed) {
      _applyBlurPolicy();
      binding.onBlurWithoutConfirm?.call();
    }

    _binding = null;
    _draftText = '';
    _snapshotText = '';
    _target = InputTarget.keyboard;
    _peakKeyboardInset = 0;
    _confirmed = false;
    notifyListeners();
  }

  void dismiss({TextEditingController? controller}) {
    final binding = _binding;
    if (binding == null) return;
    if (controller != null && binding.controller != controller) return;
    detach(controller: controller, force: true);
  }

  void confirm() {
    final binding = _binding;
    if (binding == null) return;
    _confirmed = true;
    final text = _committedDraftText(binding);
    _draftText = text;
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
    detach(controller: controller, force: true);
  }

  String _committedDraftText(KeyboardInputBinding binding) {
    return binding.controller.text;
  }
}

final keyboardInputBridgeController = KeyboardInputBridgeController();

/// 读取系统原始 viewInsets（不受 [KeyboardOverlayInsetSync] 合成影响）。
double readRawViewInsetBottom(BuildContext? context) {
  final view = context != null ? View.maybeOf(context) : null;
  final target = view ?? WidgetsBinding.instance.platformDispatcher.implicitView;
  if (target == null) return 0;
  return MediaQueryData.fromView(target).viewInsets.bottom;
}

/// 手动 attach 页面（登录/注册等）的统一 focus 处理。
void handleBridgeFocusChange({
  required BuildContext context,
  required FocusNode focusNode,
  required TextEditingController controller,
  required String scene,
  VoidCallback? onConfirm,
  String hint = '',
  bool obscureText = false,
  GlobalKey? anchorKey,
}) {
  if (focusNode.hasFocus) {
    keyboardInputBridgeController.attach(
      controller: controller,
      focusNode: focusNode,
      onConfirm: onConfirm,
      scene: scene,
      hint: hint,
      obscureText: obscureText,
      anchorKey: anchorKey,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = keyboardInputBridgeController.overlayConfig;
      if (config?.showInputField ?? false) {
        keyboardInputBridgeController.ensureBindingEditorFocus();
      }
      keyboardInputBridgeController.liftAnchor(context);
    });
  } else {
    if (keyboardInputBridgeController.shouldSkipDetachOnFocusLoss(controller)) {
      return;
    }
    keyboardInputBridgeController.detach(controller: controller, force: true);
  }
}

class UcgEmojiPanelGrid extends StatelessWidget {
  const UcgEmojiPanelGrid({
    super.key,
    required this.height,
    required this.onEmojiSelected,
  });

  final double height;
  final ValueChanged<String> onEmojiSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
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
            onTap: () => onEmojiSelected(emoji),
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: KeyboardOverlayMetrics.emojiFontSize)),
            ),
          );
        },
      ),
    );
  }
}

class KeyboardInputConfirmBarOverlay extends StatefulWidget {
  const KeyboardInputConfirmBarOverlay({super.key});

  @override
  State<KeyboardInputConfirmBarOverlay> createState() => _KeyboardInputConfirmBarOverlayState();
}

class _KeyboardInputConfirmBarOverlayState extends State<KeyboardInputConfirmBarOverlay> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    keyboardInputBridgeController.onWindowInsetsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: keyboardInputBridgeController,
      builder: (context, _) {
        final bridge = keyboardInputBridgeController;
        final config = bridge.overlayConfig;
        if (config == null || !config.anyEnabled) {
          return const SizedBox.shrink();
        }

        final keyboardBottom = readRawViewInsetBottom(context);
        bridge.noteKeyboardInset(keyboardBottom);
        final visible = bridge.overlayVisible(keyboardBottom);
        final emojiPanelDisplayed = bridge.isEmojiPanelDisplayed(keyboardBottom);

        if (!visible) {
          return const SizedBox.shrink();
        }

        final panelHeight = bridge.emojiPanelSlotHeight;
        final useBottomSlot = bridge.holdsKeyboardSlot(keyboardBottom);
        final accessoryBottom = useBottomSlot ? panelHeight : keyboardBottom;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (useBottomSlot)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: keyboardDismissExclude(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: emojiPanelDisplayed
                        ? Material(
                            color: Theme.of(context).colorScheme.surface,
                            elevation: 1,
                            child: UcgEmojiPanelGrid(
                              height: panelHeight,
                              onEmojiSelected: bridge.insertAtCursor,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: accessoryBottom,
              child: keyboardDismissExclude(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KeyboardOverlayMetrics.barPaddingH,
                      KeyboardOverlayMetrics.barPaddingV,
                      KeyboardOverlayMetrics.barPaddingH,
                      KeyboardOverlayMetrics.barPaddingV,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (config.showMultimedia) _MultimediaStripPlaceholder(config: config),
                        SizedBox(
                          height: KeyboardOverlayMetrics.accessoryBarHeight,
                          child: _buildAccessoryRow(
                            context,
                            bridge,
                            config,
                            keyboardBottom: keyboardBottom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessoryRow(
    BuildContext context,
    KeyboardInputBridgeController bridge,
    KeyboardOverlayConfig config, {
    required double keyboardBottom,
  }) {
    final showKeyboardIcon = bridge.accessoryShowsKeyboardIcon(keyboardBottom);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (config.showEmoji && showKeyboardIcon) ...[
          _CompactIconButton(
            tooltip: '键盘',
            icon: Icons.keyboard_rounded,
            onPressed: () => bridge.onAccessoryIconPressed(readRawViewInsetBottom(context)),
          ),
          const SizedBox(width: 4),
        ] else if (config.showEmoji) ...[
          _CompactIconButton(
            tooltip: '表情',
            icon: Icons.emoji_emotions_outlined,
            onPressed: () => bridge.onAccessoryIconPressed(readRawViewInsetBottom(context)),
          ),
          const SizedBox(width: 4),
        ],
        if (config.showMultimedia) ...[
          _CompactIconButton(
            tooltip: '多媒体',
            icon: Icons.add_photo_alternate_outlined,
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        if (config.showInputField)
          Expanded(child: _OverlayEditor(config: config))
        else
          const Spacer(),
        if (config.showConfirmButton) ...[
          const SizedBox(width: 4),
          FilledButton(
            onPressed: bridge.confirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                KeyboardOverlayMetrics.confirmMinWidth,
                KeyboardOverlayMetrics.confirmHeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(config.confirmLabel),
          ),
        ],
      ],
    );
  }
}

/// emoji 模式用峰值 inset 合成 viewInsets，避免 Sheet 随键盘 hide / 动画回落。
class KeyboardOverlayInsetSync extends StatefulWidget {
  const KeyboardOverlayInsetSync({required this.child, super.key});

  final Widget child;

  @override
  State<KeyboardOverlayInsetSync> createState() => _KeyboardOverlayInsetSyncState();
}

class _KeyboardOverlayInsetSyncState extends State<KeyboardOverlayInsetSync> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    keyboardInputBridgeController.addListener(_onBridgeChange);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    keyboardInputBridgeController.removeListener(_onBridgeChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onBridgeChange() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() {
    keyboardInputBridgeController.onWindowInsetsChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final raw = MediaQuery.viewInsetsOf(context);
    final effectiveBottom =
        keyboardInputBridgeController.effectiveViewInsetBottom(raw.bottom);
    if ((effectiveBottom - raw.bottom).abs() < 0.5) {
      return widget.child;
    }
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        viewInsets: raw.copyWith(bottom: effectiveBottom),
      ),
      child: widget.child,
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: SizedBox(
        width: KeyboardOverlayMetrics.iconButtonSize,
        height: KeyboardOverlayMetrics.iconButtonSize,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(
            minWidth: KeyboardOverlayMetrics.iconButtonSize,
            minHeight: KeyboardOverlayMetrics.iconButtonSize,
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _MultimediaStripPlaceholder extends StatelessWidget {
  const _MultimediaStripPlaceholder({required this.config});

  final KeyboardOverlayConfig config;

  @override
  Widget build(BuildContext context) {
    if (!config.showMultimedia) return const SizedBox.shrink();
    return SizedBox(
      height: KeyboardOverlayMetrics.mediaStripHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '多媒体缩略图区域',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _OverlayEditor extends StatefulWidget {
  const _OverlayEditor({required this.config});

  final KeyboardOverlayConfig config;

  @override
  State<_OverlayEditor> createState() => _OverlayEditorState();
}

class _OverlayEditorState extends State<_OverlayEditor> {
  @override
  Widget build(BuildContext context) {
    final bridge = keyboardInputBridgeController;
    final binding = bridge.binding;
    if (binding == null || !binding.overlayConfig.showInputField) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final submitOnEnter = binding.scene == 'ucg.profile.nickname' && binding.overlayConfig.showConfirmButton;
    final submitOnSend = binding.textInputAction == TextInputAction.send && binding.onConfirm != null;
    final formatters = <TextInputFormatter>[
      if (binding.scene == 'ucg.profile.nickname')
        FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
      ...?binding.inputFormatters,
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: KeyboardOverlayMetrics.editorMinHeight,
        maxHeight: KeyboardOverlayMetrics.editorMaxHeight,
      ),
      child: Listener(
        onPointerDown: (_) {
          if (bridge.target == InputTarget.emoji) {
            bridge.requestKeyboard();
          }
        },
        child: TextField(
          controller: binding.controller,
          focusNode: binding.focusNode,
          obscureText: binding.obscureText,
          maxLines: binding.scene == 'ucg.profile.nickname'
              ? 1
              : (binding.obscureText ? 1 : KeyboardOverlayMetrics.editorMaxLines),
          minLines: 1,
          textInputAction: binding.textInputAction ??
              (submitOnEnter ? TextInputAction.done : null),
          inputFormatters: formatters.isEmpty ? null : formatters,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.2),
          decoration: InputDecoration(
            isDense: true,
            hintText: binding.hint,
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: bridge.updateDraft,
          onTap: () {
            if (bridge.target == InputTarget.emoji) {
              bridge.requestKeyboard();
            }
          },
          onSubmitted: submitOnEnter || submitOnSend ? (_) => bridge.confirm() : null,
        ),
      ),
    );
  }
}
