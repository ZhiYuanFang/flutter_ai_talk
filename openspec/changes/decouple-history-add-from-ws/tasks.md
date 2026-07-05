# Tasks: decouple-history-add-from-ws

1. Implement button-path immediate add
   - Edit `app/lib/ui/home_screen.dart` `_submitEventAdd()`:
     - Remove `if (!feed.isHistoryWebSocketReady) return;`
     - Start background `addHistoryEvent(body)` and handle `HistoryAddPostOutcome` (success / business / transport).
   - Use `homeHistoryProvider.notifier` methods to replace/remove pending rows.
   - Status: ✅ implemented in this change (home_screen.dart updated to always call `addHistoryEvent` and handle failures)

2. Handle transport failures (mixed strategy)
   - Extend or add `HistoryOutboxStore` support for ADD entries (enqueueAdd / peekAdd / removeHeadAdd).
   - On transport failure from `addHistoryEvent`, enqueue ADD outbox entry and remove or mark pending row.

3. Keep voice/text path WS-gated
   - Confirm `sendCommand()` and voice ASR paths remain gated by `isHistoryWebSocketReady` (no changes required unless regression found).

4. Ensure flush path handles ADD outbox
   - Update `flushHistoryOutbox()` to first process pending ADD entries, then UPDATE entries. Ensure single-flight semantics preserved.

5. Tests
   - Unit tests for `_submitEventAdd()` behaviour for success/business/transport outcomes.
   - Integration test: simulate offline + add → outbox entry created → simulate WS ready + flush → server id replacement.

6. Logging & QA
   - Add `AppDebugLog.historyOutbox` statements for ADD enqueue/flush/replace/remove events.
   - QA scenarios: network on/off, delayed WS, duplicate WS/HTTP events, deviceUnbound.

7. Documentation
   - Update `openspec/specs` or `app/README.md` change note summarizing the behavior change and migration notes.

---

Done-by: opsx-propose
