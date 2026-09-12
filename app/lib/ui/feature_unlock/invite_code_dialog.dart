import 'package:flutter/material.dart';

import '../home_history_edit_glass_panel.dart';
import '../widgets/app_glass_overlay.dart';

/// 共享邀请码弹窗结果：获取方式页 / 确认提交的码（可为空串）。
sealed class InviteCodeDialogResult {
  const InviteCodeDialogResult();
}

/// 用户点击「获取邀请码」。
final class InviteCodeDialogHowTo extends InviteCodeDialogResult {
  const InviteCodeDialogHowTo();
}

/// 用户点击确认；[code] 已 trim，允许空串由调用方解释。
final class InviteCodeDialogSubmitted extends InviteCodeDialogResult {
  const InviteCodeDialogSubmitted(this.code);
  final String code;
}

/// 展示共享邀请码玻璃弹窗；屏障关闭返回 null。
Future<InviteCodeDialogResult?> showInviteCodeDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = '兑换',
}) {
  return showGlassDialog<InviteCodeDialogResult>(
    context: context,
    contentBuilder: (ctx) => _InviteCodeDialogBody(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
    ),
  );
}

/// 邀请码输入体：controller 生命周期绑定 State。
class _InviteCodeDialogBody extends StatefulWidget {
  const _InviteCodeDialogBody({
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;

  @override
  State<_InviteCodeDialogBody> createState() => _InviteCodeDialogBodyState();
}

class _InviteCodeDialogBodyState extends State<_InviteCodeDialogBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 弹层 State 持有输入，避免 await show* 后 dispose 与退场动画竞态。
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: glassText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.body,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4, color: glassLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          style: TextStyle(color: glassText),
          decoration: InputDecoration(
            hintText: '请输入邀请码',
            hintStyle: TextStyle(color: glassLabel.withValues(alpha: 0.7)),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              // 获取邀请码：进入如何获取页
              onPressed: () =>
                  Navigator.pop(context, const InviteCodeDialogHowTo()),
              style: TextButton.styleFrom(
                foregroundColor: glassLabel,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('获取邀请码'),
            ),
            const Spacer(),
            FilledButton(
              // 确认：pop 修剪后的码（空串由调用方决定静默或跳转）
              onPressed: () => Navigator.pop(
                context,
                InviteCodeDialogSubmitted(_controller.text.trim()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: const StadiumBorder(),
              ),
              child: Text(widget.confirmLabel),
            ),
          ],
        ),
      ],
    );
  }
}
