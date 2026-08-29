import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ucg/data/ucg_force_models.dart';
import '../ucg/providers/ucg_providers.dart';

/// 原力积分流水（首屏 limit=50）。
final ucgForceLedgerProvider =
    FutureProvider.autoDispose<UcgForceLedgerPage>((ref) {
  return ref.read(ucgRepositoryProvider).fetchForceLedger();
});
