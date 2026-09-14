import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/client_usage_events.dart';
import '../data/client_usage_repository.dart';
import 'authorized_api_client_provider.dart';
import 'session_provider.dart';

final clientUsageRepositoryProvider = Provider<ClientUsageRepository>((ref) {
  return ClientUsageRepository(ref.watch(authorizedApiClientProvider));
});

/// 已登录才上报；未登录 no-op。供 `unawaited` 调用。
final clientUsageReporterProvider = Provider<ClientUsageReporter>((ref) {
  return ClientUsageReporter(ref);
});

class ClientUsageReporter {
  ClientUsageReporter(this._ref);

  final Ref _ref;

  Future<void> report(String featureId, String description) async {
    if (!_ref.read(sessionProvider).isLoggedIn) return;
    await _ref.read(clientUsageRepositoryProvider).report(featureId, description);
  }

  Future<void> reportEvent(ClientUsageEvent event) =>
      report(event.featureId, event.description);
}

/// 页挂载后首帧上报一次展示事件（KeepAlive 再次挂载会再报）。
class ClientUsageShowOnce extends ConsumerStatefulWidget {
  const ClientUsageShowOnce({
    super.key,
    required this.event,
    required this.child,
  });

  final ClientUsageEvent event;
  final Widget child;

  @override
  ConsumerState<ClientUsageShowOnce> createState() =>
      _ClientUsageShowOnceState();
}

class _ClientUsageShowOnceState extends ConsumerState<ClientUsageShowOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(clientUsageReporterProvider).reportEvent(widget.event));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
