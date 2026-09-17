import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// 共享 AI 思考正文区：默认跟底；上翻暂停；仅回底钮恢复跟滚。
///
/// 凡可滚动展示 agent 流式/展开思考正文的 UI MUST 使用本组件（见 project.md）。
class AiThinkingPane extends StatefulWidget {
  const AiThinkingPane({
    super.key,
    required this.text,
    this.style,
    this.accentColor,
    this.maxHeightFactor = 0.4,
    this.maxHeight,
  });

  /// 思考正文（可含流式增量）。
  final String text;

  /// 正文字体；为空则用 13/1.4 默认样式并由调用方色写入 [style]。
  final TextStyle? style;

  /// 回底钮功能色；为空则 [ColorScheme.primary]。
  final Color? accentColor;

  /// 相对屏高上限（[maxHeight] 未设时生效）。
  final double maxHeightFactor;

  /// 绝对高度上限；优先于 [maxHeightFactor]。
  final double? maxHeight;

  @override
  State<AiThinkingPane> createState() => _AiThinkingPaneState();
}

class _AiThinkingPaneState extends State<AiThinkingPane> {
  /// 离底超过该距离视为用户上翻，暂停跟滚。
  static const _pauseThreshold = 80.0;

  final _scrollController = ScrollController();

  /// 为 true 时 text 增长自动滚到底。
  var _followLatest = true;

  /// 程序 jumpTo 期间忽略 scroll listener，避免误判为上翻。
  var _programmaticScroll = false;

  /// 是否有可滚动溢出（用于决定是否画回底钮）。
  var _canScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onUserScroll);
    // 首帧布局后若需跟底则滚一次
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFollow());
  }

  @override
  void didUpdateWidget(AiThinkingPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFollow());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onUserScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserScroll() {
    if (_programmaticScroll) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final distanceFromBottom = pos.maxScrollExtent - pos.pixels;
    // 仅上翻暂停；近底不自动恢复 follow
    if (_followLatest && distanceFromBottom > _pauseThreshold) {
      setState(() => _followLatest = false);
    }
    final canScroll = pos.maxScrollExtent > 0.5;
    if (canScroll != _canScroll) {
      setState(() => _canScroll = canScroll);
    }
  }

  void _maybeFollow() {
    if (!mounted || !_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final canScroll = max > 0.5;
    if (canScroll != _canScroll) {
      setState(() => _canScroll = canScroll);
    }
    if (!_followLatest || max <= 0) return;
    _jumpToBottom();
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    _programmaticScroll = true;
    _scrollController.jumpTo(max);
    // 下一帧再放开门闩，避免 listener 吃到程序滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _programmaticScroll = false;
    });
  }

  void _onJumpButtonPressed() {
    setState(() => _followLatest = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpToBottom();
      setState(() {}); // 刷新藏钮
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final maxH = widget.maxHeight ?? screenH * widget.maxHeightFactor;
    final scheme = Theme.of(context).colorScheme;
    // 回底钮填充：功能色优先，否则主题主色
    final fill = widget.accentColor ?? scheme.primary;
    final onFill = widget.accentColor == null
        ? AppColor.onPrimary(context)
        : (ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
            ? Colors.white
            : const Color(0xFF1A1A1A));
    final textStyle = widget.style ??
        TextStyle(fontSize: 13, height: 1.4, color: scheme.onSurface);

    final showJump = !_followLatest && _canScroll;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 思考正文可滚区域（Stack 高度随内容，上限 maxH）
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Text(widget.text, style: textStyle),
          ),
          // 仅暂停跟滚时悬停回底
          if (showJump)
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: fill.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _onJumpButtonPressed,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: onFill,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
