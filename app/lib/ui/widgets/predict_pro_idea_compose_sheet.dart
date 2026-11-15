import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/predict_pro_idea_provider.dart';
import '../../providers/toast_bus.dart';
import '../../theme/app_color.dart';
import 'app_modal_glass_panel.dart';
import 'app_toast.dart';

/// 打开底浮玻璃作曲 Sheet；成功提交返回 true。
///
/// 键盘弹出时整张 Sheet 跟 [MediaQuery.viewInsets] 上移（不改两档墙结构）。
Future<bool?> showPredictProIdeaComposeSheet(
  BuildContext context, {
  Color? accent,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => _PredictProIdeaComposeSheet(accent: accent),
  );
}

class _PredictProIdeaComposeSheet extends ConsumerStatefulWidget {
  const _PredictProIdeaComposeSheet({this.accent});

  final Color? accent;

  @override
  ConsumerState<_PredictProIdeaComposeSheet> createState() =>
      _PredictProIdeaComposeSheetState();
}

class _PredictProIdeaComposeSheetState
    extends ConsumerState<_PredictProIdeaComposeSheet> {
  // Sheet State 持有输入，dispose 时释放（弹框 controller 约定）
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok =
        await ref.read(predictProIdeaListProvider.notifier).submit(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      ref.showApiToast('已提交想法', tone: AppToastTone.success);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final accent = widget.accent ?? AppColor.primary(context);
    final canSend = _controller.text.trim().isNotEmpty && !_sending;

    // 整张 Sheet 跟键盘上移
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: AppModalGlassPanel(
            eventAccent: accent,
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '说说你的想法',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textOnModal(context),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLength: 200,
                  maxLines: 4,
                  minLines: 2,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: TextStyle(
                    color: AppColor.textOnModal(context),
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: '具备什么功能，你愿意付费开通？',
                    hintStyle: TextStyle(
                      color: AppColor.textOnModal(context)
                          .withValues(alpha: 0.45),
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColor.contentCard(context)
                        .withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accent.withValues(alpha: 0.28),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: canSend ? _send : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColor.onPrimary(context),
                      disabledBackgroundColor:
                          accent.withValues(alpha: 0.35),
                    ),
                    child: _sending
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColor.onPrimary(context),
                            ),
                          )
                        : const Text(
                            '发送',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
