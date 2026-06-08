import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feedback_models.dart';
import '../data/feedback_repository.dart';
import 'authorized_api_client_provider.dart';
import 'toast_bus.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final api = ref.watch(authorizedApiClientProvider);
  return FeedbackRepository(
    api,
    onToastError: (m) => ref.showApiToastError(m),
  );
});

final feedbackListProvider = FutureProvider.autoDispose<List<FeedbackItem>>((ref) {
  return ref.watch(feedbackRepositoryProvider).list();
});
