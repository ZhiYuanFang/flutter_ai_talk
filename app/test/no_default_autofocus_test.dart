import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pangbao_app/ui/widgets/app_glass_overlay.dart';

void main() {
  testWidgets('glass text confirm dialog should not autofocus input by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  showGlassTextConfirmDialog(
                    context,
                    title: '确认',
                    message: '请输入内容',
                    expectedText: '确定',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editable.focusNode.hasFocus, isFalse);
  });
}
