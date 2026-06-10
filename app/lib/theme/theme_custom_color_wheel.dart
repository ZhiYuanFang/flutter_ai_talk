import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

/// 设置页内嵌 HSV 色盘，支持任意 ARGB 背景色。
class ThemeCustomColorWheel extends StatelessWidget {
  const ThemeCustomColorWheel({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      color: color,
      onColorChanged: onColorChanged,
      onColorChangeEnd: onColorChanged,
      width: 36,
      height: 36,
      borderRadius: 8,
      heading: Text(
        '选择颜色',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subheading: Text(
        '拖动色盘或滑条选择任意背景色',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.both: false,
      },
      enableShadesSelection: false,
      showMaterialName: false,
      showColorName: false,
      showColorCode: true,
      colorCodeHasColor: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: false,
        pasteButton: false,
        longPressMenu: false,
      ),
    );
  }
}
