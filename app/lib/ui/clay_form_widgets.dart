import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'baby_profile_clay_theme.dart';

/// 黏土拟态主卡片容器。
class ClayProfileCard extends StatelessWidget {
  const ClayProfileCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BabyProfileClayTheme.cardColor,
        borderRadius: BorderRadius.circular(BabyProfileClayTheme.cardRadius),
        boxShadow: BabyProfileClayTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: child,
      ),
    );
  }
}

/// 分区标签（可选左侧装饰图标）。
class ClaySectionLabel extends StatelessWidget {
  const ClaySectionLabel({
    super.key,
    required this.text,
    this.leadingIcon,
  });

  final String text;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: BabyProfileClayTheme.textSecondary),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: BabyProfileClayTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// 内凹圆角输入区。
class ClayInsetField extends StatelessWidget {
  const ClayInsetField({
    super.key,
    required this.child,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
  });

  final Widget child;
  final Widget? leading;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BabyProfileClayTheme.insetFill,
        borderRadius: BorderRadius.circular(BabyProfileClayTheme.fieldRadius),
        border: Border.all(color: BabyProfileClayTheme.insetBorder, width: 1),
        boxShadow: BabyProfileClayTheme.insetShadow,
      ),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// 性别等双色可选胶囊。
class ClayChoiceChip extends StatelessWidget {
  const ClayChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fillColor,
    required this.borderColor,
    this.leadingDotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color fillColor;
  final Color borderColor;
  final Color? leadingDotColor;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? fillColor : BabyProfileClayTheme.insetFill;
    final border = selected ? borderColor : BabyProfileClayTheme.insetBorder;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BabyProfileClayTheme.chipRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(BabyProfileClayTheme.chipRadius),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
            boxShadow: selected ? BabyProfileClayTheme.insetShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingDotColor != null) ...[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: leadingDotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: BabyProfileClayTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 生日区内嵌 Cupertino 日期滚轮。
class ClayBirthDateWheel extends StatelessWidget {
  const ClayBirthDateWheel({
    super.key,
    required this.value,
    required this.minimumDate,
    required this.maximumDate,
    required this.onChanged,
    this.height = 168,
  });

  final DateTime value;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClayInsetField(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: BabyProfileClayTheme.accentBlue,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                fontSize: 18,
                color: BabyProfileClayTheme.textPrimary,
              ),
            ),
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: value,
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            onDateTimeChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
