import 'package:flutter/material.dart';

/// 语音模式统一消息条：实时转写与服务端回复，置于历史与底栏之间。
class HomeVoiceMessageStrip extends StatefulWidget {
  const HomeVoiceMessageStrip({
    super.key,
    required this.text,
    this.expandable = false,
    this.onExpand,
  });

  final String text;

  /// 为 true 且内容在条内溢出可滚动时，可点击 [onExpand]（服务端回复）。
  final bool expandable;

  final VoidCallback? onExpand;

  @override
  State<HomeVoiceMessageStrip> createState() => _HomeVoiceMessageStripState();
}

class _HomeVoiceMessageStripState extends State<HomeVoiceMessageStrip> {
  final _scrollController = ScrollController();
  var _scrollOverflow = false;

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
    _scheduleOverflowCheck();
  }

  @override
  void didUpdateWidget(HomeVoiceMessageStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _scrollToEnd();
    }
    _scheduleOverflowCheck();
  }

  void _scheduleOverflowCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverflow());
  }

  void _updateOverflow() {
    if (!mounted || !_scrollController.hasClients) return;
    final overflow = _scrollController.position.maxScrollExtent > 0.5;
    if (overflow != _scrollOverflow) {
      setState(() => _scrollOverflow = overflow);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) {
        _scrollController.jumpTo(max);
      }
      _updateOverflow();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.30;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.35,
          color: scheme.onSurface,
        );

    final body = SelectableText(
      widget.text,
      style: style,
      textAlign: TextAlign.center,
    );

    final tappable =
        widget.expandable && widget.onExpand != null && _scrollOverflow;

    Widget scrollChild = SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: body,
    );

    if (tappable) {
      scrollChild = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onExpand,
          child: Stack(
            children: [
              scrollChild,
              Positioned(
                right: 8,
                bottom: 6,
                child: Icon(
                  Icons.unfold_more,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: scrollChild,
          ),
        ),
      ),
    );
  }
}
