import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pangbao_app/ui/widgets/keyboard_input_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyboardInputBridgeController', () {
    test('confirm should write back to controller and invoke callback', () {
      final bridge = KeyboardInputBridgeController();
      final textController = TextEditingController(text: 'old');
      final focusNode = FocusNode();
      var confirmed = false;

      bridge.attach(
        controller: textController,
        focusNode: focusNode,
        onConfirm: () => confirmed = true,
        scene: 'test.scene',
      );
      bridge.updateDraft('new value');

      bridge.confirm();

      expect(textController.text, 'new value');
      expect(confirmed, isTrue);
      expect(bridge.hasBinding, isFalse);
    });

    test('visibleText should be masked in obscure mode', () {
      final bridge = KeyboardInputBridgeController();
      final textController = TextEditingController(text: 'secret');
      final focusNode = FocusNode();

      bridge.attach(
        controller: textController,
        focusNode: focusNode,
        scene: 'test.password',
        obscureText: true,
      );

      expect(bridge.visibleText, '••••••');

      bridge.updateDraft('abcd1234');
      expect(bridge.visibleText, '••••••••');
    });
  });
}
