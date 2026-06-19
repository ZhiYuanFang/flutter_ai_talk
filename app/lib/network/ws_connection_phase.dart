/// WebSocket 连接阶段（喂养历史与 UCG 聊天共用）。
enum WsConnectionPhase {
  ready,
  autoReconnecting,
  gaveUp,
  disconnected,
}
