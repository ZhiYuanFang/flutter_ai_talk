import 'package:flutter/foundation.dart';

import 'event_definition.dart';

@immutable
class EventCatalogState {
  const EventCatalogState({
    this.items = const [],
    this.isRefreshing = false,
    this.remoteLoadAttempted = false,
  });

  final List<EventDefinition> items;
  final bool isRefreshing;
  final bool remoteLoadAttempted;

  bool get isEmpty => items.isEmpty;

  EventCatalogState copyWith({
    List<EventDefinition>? items,
    bool? isRefreshing,
    bool? remoteLoadAttempted,
  }) {
    return EventCatalogState(
      items: items ?? this.items,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      remoteLoadAttempted: remoteLoadAttempted ?? this.remoteLoadAttempted,
    );
  }
}
