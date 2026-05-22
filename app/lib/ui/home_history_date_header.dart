import 'package:flutter/material.dart';

/// 主页历史列表：按自然日的分块标题行（配合 Sliver 吸顶）。
class HomeHistoryDateHeader extends StatelessWidget {
  const HomeHistoryDateHeader({super.key, required this.label});

  final String label;

  static const double height = 30;
  /// 与历史记录行 [HomeHistoryScroll] 横向 padding 一致，仅作用于文字，背景仍通栏。
  static const double labelHorizontalPadding = 12;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: labelHorizontalPadding),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeHistoryDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  HomeHistoryDateHeaderDelegate({required this.label});

  final String label;

  @override
  double get minExtent => HomeHistoryDateHeader.height;

  @override
  double get maxExtent => HomeHistoryDateHeader.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return HomeHistoryDateHeader(label: label);
  }

  @override
  bool shouldRebuild(covariant HomeHistoryDateHeaderDelegate oldDelegate) {
    return oldDelegate.label != label;
  }
}
