import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'web_url_strategy_stub.dart' if (dart.library.html) 'web_url_strategy.dart' as web_url;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    web_url.useAppPathUrlStrategy();
  }
  runApp(const ProviderScope(child: PangbaoApp()));
}
