import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/force_ipv4_http_overrides_stub.dart'
    if (dart.library.io) 'bootstrap/force_ipv4_http_overrides.dart' as force_ipv4;
import 'config/env.dart';
import 'web_url_strategy_stub.dart' if (dart.library.html) 'web_url_strategy.dart' as web_url;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    web_url.useAppPathUrlStrategy();
  } else if (AppEnv.forceIpv4) {
    force_ipv4.installForceIpv4HttpOverrides();
  }
  runApp(const ProviderScope(child: PangbaoApp()));
}
