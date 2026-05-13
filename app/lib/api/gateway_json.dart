/// 网关业务 JSON 使用 **lowerCamelCase** 键名（与 `deviceNo` 风格一致）。
///
/// **出站（当前客户端已审）**  
/// - `POST .../device_login`：`deviceNo`  
/// - WebSocket 鉴权首帧：`type`、`accessToken`、`deviceNo`  
/// - 登录/聊天等：`jsCode`、`deviceNo`、`transcript`、…  
///
/// **入站**  
/// 优先读 camelCase；`snakeKey` 仅作旧网关兼容。网关全量 camel 后可删 snake 分支（见 OpenSpec `api-json-camelcase-fields`）。TODO(api-camelcase): 移除 [readGatewayStr] 的 snake 回退。
library;

/// 从 `data` Map 读取字符串：先试 [camelKey]，再试 [snakeKey]。
String? readGatewayStr(Map<String, dynamic> map, String camelKey, String snakeKey) {
  for (final key in [camelKey, snakeKey]) {
    final v = map[key];
    if (v == null) continue;
    if (v is String) {
      if (v.isNotEmpty) return v;
      continue;
    }
    final t = v.toString();
    if (t.isNotEmpty) return t;
  }
  return null;
}
