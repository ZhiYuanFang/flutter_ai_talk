import 'ws_connection_phase.dart';
import '../data/feed_repository.dart';

HistoryWsPhase historyWsPhaseFromShared(WsConnectionPhase phase) {
  return switch (phase) {
    WsConnectionPhase.ready => HistoryWsPhase.ready,
    WsConnectionPhase.autoReconnecting => HistoryWsPhase.autoReconnecting,
    WsConnectionPhase.gaveUp => HistoryWsPhase.gaveUp,
    WsConnectionPhase.disconnected => HistoryWsPhase.disconnected,
  };
}
