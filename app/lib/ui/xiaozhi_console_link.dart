import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/app_toast.dart';

/// 小智控制台智能体列表（外链，系统浏览器打开）。
const kXiaozhiConsoleAgentsUrl = 'https://xiaozhi.me/console/agents';

/// 在系统浏览器中打开小智控制台；失败 toast。
Future<void> openXiaozhiConsoleAgents() async {
  final uri = Uri.parse(kXiaozhiConsoleAgentsUrl);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      showAppToast('无法打开小智控制台', tone: AppToastTone.error);
    }
  } catch (_) {
    showAppToast('无法打开小智控制台', tone: AppToastTone.error);
  }
}

/// 正文中可点的「小智控制台」链接（[TapGestureRecognizer] 由本 State 释放）。
class XiaozhiConsoleLinkedText extends StatefulWidget {
  const XiaozhiConsoleLinkedText({
    super.key,
    required this.leading,
    required this.trailing,
    required this.style,
    this.linkColor,
  });

  /// 「小智控制台」之前的文案。
  final String leading;

  /// 「小智控制台」之后的文案。
  final String trailing;
  final TextStyle style;
  final Color? linkColor;

  @override
  State<XiaozhiConsoleLinkedText> createState() =>
      _XiaozhiConsoleLinkedTextState();
}

class _XiaozhiConsoleLinkedTextState extends State<XiaozhiConsoleLinkedText> {
  late final TapGestureRecognizer _tap;

  @override
  void initState() {
    super.initState();
    _tap = TapGestureRecognizer()..onTap = () => openXiaozhiConsoleAgents();
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkColor = widget.linkColor ?? Theme.of(context).colorScheme.primary;
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: widget.leading),
          TextSpan(
            text: '小智控制台',
            style: widget.style.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: _tap,
          ),
          TextSpan(text: widget.trailing),
        ],
      ),
    );
  }
}
