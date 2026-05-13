import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controller.dart';

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final c = SessionController();
  ref.onDispose(c.dispose);
  return c;
});
