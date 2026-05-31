import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../home_history_edit_glass_panel.dart';
import 'app_glass_overlay.dart';

/// 弹出出生日期滚轮 Sheet；色调跟随 Material [ColorScheme.primary]。
Future<DateTime?> showBabyBirthPickerSheet(
  BuildContext context, {
  required DateTime initialValue,
  String? title,
}) {
  return showGlassAdaptiveBottomSheet<DateTime>(
    context: context,
    scrollable: false,
    bodyBuilder: (ctx) => _BabyBirthPickerSheetBody(
      initialValue: initialValue,
      title: title,
    ),
  );
}

class _BabyBirthPickerSheetBody extends StatefulWidget {
  const _BabyBirthPickerSheetBody({
    required this.initialValue,
    this.title,
  });

  final DateTime initialValue;
  final String? title;

  @override
  State<_BabyBirthPickerSheetBody> createState() => _BabyBirthPickerSheetBodyState();
}

class _BabyBirthPickerSheetBodyState extends State<_BabyBirthPickerSheetBody> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialValue;
  }

  void _confirm() => Navigator.pop(context, _selectedDate);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: glassText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: primary,
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: glassText,
                    ),
                pickerTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: glassLabel,
                    ),
              ),
            ),
            child: SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime(2000),
                maximumDate: DateTime.now().subtract(const Duration(minutes: 1)), // 限制只能选今天以前（包括今天，规避毫秒误差）
                onDateTimeChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _confirm,
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
