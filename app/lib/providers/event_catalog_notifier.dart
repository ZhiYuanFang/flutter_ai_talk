import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_catalog_store.dart';
import '../data/event_catalog_sync.dart';
import '../data/event_definition.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';

class EventCatalogNotifier extends StateNotifier<List<EventDefinition>> {
  EventCatalogNotifier(this._ref) : super(const []);

  final Ref _ref;

  EventDefinition? lookupByEventId(Object? eventId) {
    if (eventId == null) return null;
    final key = eventId.toString().trim();
    if (key.isEmpty) return null;
    for (final e in state) {
      if (e.id == key) return e;
    }
    return null;
  }

  EventDefinition? lookupByName(String eventName) {
    final name = eventName.trim();
    if (name.isEmpty) return null;
    EventDefinition? match;
    for (final e in state) {
      if (e.name.trim() == name) {
        if (match != null) return null;
        match = e;
      }
    }
    return match;
  }

  Future<void> loadFromDisk() async {
    final cached = await EventCatalogStore.loadFromDisk();
    state = cached;
  }

  Future<void> refreshFromRemote() async {
    final loggedIn = _ref.read(sessionProvider).isLoggedIn;
    if (!loggedIn) return;
    final dn = _ref.read(deviceNoNotifierProvider).asData?.value;
    if (dn == null || dn.isEmpty) return;

    final sync = EventCatalogSync(_ref.read(authorizedApiClientProvider));
    final updated = await sync.refreshAndPersist();
    if (updated != null) {
      state = updated;
    }
  }
}

final eventCatalogProvider =
    StateNotifierProvider<EventCatalogNotifier, List<EventDefinition>>((ref) {
  return EventCatalogNotifier(ref);
});
