import 'package:flutter/cupertino.dart';

/// 用量滚轮档位（与添加事件 Sheet 一致）。
final List<int> kHomeEventNumberPickerValues = [
  for (var v = 5; v <= 500; v += 5) v,
];

const double kHomeEventNumberPickerItemExtent = 36.0;
const double kHomeEventNumberPickerHeight = 160.0;

/// 主页事件用量 Cupertino 滚轮（5–500，步进 5）。
class HomeEventNumberPicker extends StatelessWidget {
  const HomeEventNumberPicker({
    super.key,
    required this.controller,
    this.onSelected,
    this.enabled = true,
  });

  final FixedExtentScrollController controller;
  final ValueChanged<int>? onSelected;
  final bool enabled;

  static int valueAtIndex(int index) {
    return kHomeEventNumberPickerValues[index.clamp(0, kHomeEventNumberPickerValues.length - 1)];
  }

  static int indexForValue(int value) {
    final idx = kHomeEventNumberPickerValues.indexOf(value);
    if (idx >= 0) return idx;
    var nearest = 0;
    var best = (value - kHomeEventNumberPickerValues.first).abs();
    for (var i = 1; i < kHomeEventNumberPickerValues.length; i++) {
      final d = (value - kHomeEventNumberPickerValues[i]).abs();
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kHomeEventNumberPickerHeight,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: kHomeEventNumberPickerItemExtent,
            onSelectedItemChanged: enabled
                ? (i) => onSelected?.call(valueAtIndex(i))
                : null,
            children: kHomeEventNumberPickerValues
                .map((v) => Center(child: Text('$v')))
                .toList(),
          ),
        ),
      ),
    );
  }
}
