## Context

可见推送已由 `go_ai_talk` 的 `PushByBizType` 按 `ucg_alert` / `predict_imminent` / `ucg_silent_badge` 扇出。APNs 根 JSON 已含 `bizType`；华为写在 `android.data`，且 `click_action` 默认为 type=3（只打开应用）。小米可见消息未写 `payload`，而 `china_push` 点击只读 `getContent()`。vivo、oppo 没有 Sender，register 白名单也只有 `apns`、`hms`、`mipush`。

客户端只注册 token，未调用 `ChinaPush.setOnClickNotification`，iOS 也未把通知点击交给 Flutter。主壳默认停在预测页；UCG 消息列表不是路由，而是 `UcgShell` 消息 Tab（下标 3），且壳在第一次进入 UCG 页时才挂载。资格未过时整页是 `FeatureLockOverlay`。

本变更跨 Flutter 与兄弟仓 `go_ai_talk`。小米、vivo、oppo 尚未上架，真实下发不在验收范围内。

## Goals / Non-Goals

**Goals:**

- 点击可见通知（冷启动、后台、前台横幅）后先到 `/home`，由主页按 `bizType` 分流。
- `ucg_alert` 且已登录：切到 UCG 页，壳挂上后调用与点消息 Tab 相同的逻辑。
- `predict_imminent`：切到预测主页，不进 UCG。
- 未登录、缺字段、未知类型：不再跳转，不弹登录。
- 华为与 APNs 的点击数据里能解析出 `bizType`。
- vivo、oppo 仅代码占位。

**Non-Goals:**

- 不进入某一条私信、某一条动态或某一张预测卡片。
- 不实现 vivo、oppo 的厂商 REST，不把它们加入 register 白名单，客户端不为它们 `register`。
- 小米 `payload` 可顺手写入，不作为验收。
- 不处理 `ucg_silent_badge`（无通知条）。
- 不新增 Debug tag；点击日志复用 `AppDebugLog.ucgPush`。
- 不改预测 pending API，不把推送注册重新绑回 UCG 会话。

## Decisions

### D1. 点击只暂存，主页再分流

点击回调（Android `setOnClickNotification`、iOS `didReceive` / 冷启动 `userInfo`）只写入「最后一次 `bizType`」。若当前不在 `/home`，先 `go('/home')`。主页在路由已是 `/home` 且 `session` 已可知时消费，不等预测列表、历史或未读接口。

后一次点击覆盖尚未消费的值，不排队。

未知、空、以及 `ucg_silent_badge`：消费后不发切页请求。

### D2. 分流表

| 条件 | 动作 |
| --- | --- |
| 未登录 | 停在预测主页，不调用消息 Tab（避免现有 Tab 逻辑弹登录） |
| `predict_imminent` | `homePagerRequestProvider.requestPage(HomePagerPage.prediction)` |
| `ucg_alert` 且已登录 | `requestPage(HomePagerPage.ucg)`，壳已挂载后选中消息 Tab |
| 其它 | 无额外切页 |

资格未过不在主页分叉。照样切到 UCG 页并选中消息 Tab；锁层挡住可见内容。资格稍后变为通过时，底下已是消息列表。

「壳已挂载」指 `UcgShell` 已构建，不是会话接口完成。人已经在 UCG 页时直接选 Tab，不再等一轮加载。

### D3. 消息 Tab 复用现有点击处理

不模拟手势（锁层会吃掉点击）。抽出或直接调用 `UcgShell` 里点消息 Tab 的路径（当前下标 3：刷新会话、互动、未读）。未登录分支已在 D2 排除，此处不再弹登录。

### D4. 冷启动不丢点击

Dart 在首帧前绑定 Android 点击监听。iOS 在 channel 就绪前把启动 `userInfo` 留在原生，Dart 主动拉取一次。若 Android 在监听绑定前丢弃点击，再在原生暂存最后一次点击供 Dart 拉取；不要靠用户再点一次。

### D5. 点击载荷只认 `bizType`

客户端从 Map 或 JSON 字符串中读取 `bizType`（顶层，或某个字符串值再解析一层 JSON，以覆盖华为 `android.data` 整包）。只认 `ucg_alert` 与 `predict_imminent`。

华为：可见通知的点击必须把 `bizType` 放进 `china_push` 会遍历的 Intent extras。不依赖 type=3 是否透传 `android.data`；若现网 type=3 点开没有该字段，改为打开 `MainActivity` 且 extras 含 `bizType` 的 click intent。APNs 继续放在根 JSON；补 `willPresent` 展示前台横幅，以及点击转发。

vivo、oppo：dispatcher 增加占位 Sender，`Send` 打日志并跳过，不访问厂商 API。`validPushChannels` 仍只有 `apns`、`hms`、`mipush`。小米可见消息建议把 `{"bizType":...}` 写入 `payload`，失败不影响本变更完成。

### D6. 解析失败等于未知类型

普通启动若被华为/oppo 的 extras 误报为点击，但没有可识别的 `bizType`，按 D2「其它」处理，不得切到 UCG。

## Risks / Trade-offs

- [Risk] 华为 type=3 点开没有 `bizType` → 按 D5 改 click intent，并用真机点一次确认仍能打开 `MainActivity`。
- [Risk] 冷启动 MethodChannel 丢消息 → D4 的原生暂存；验收包含杀进程后点击。
- [Risk] 资格仍在加载时 `isQualified` 为 false，锁层先闪一下 → 接受；不把分流堵在资格接口上。
- [Risk] 与 `android-china-push-predict-imminent` 的「不做深链 / 不做 vivo oppo Sender」字面冲突 → 本变更的深链仅为两档主页分流；vivo/oppo 仍是空实现，不推翻该变更的 register 与 `china_push` 取 token 约定。
- [Trade-off] 未上架通道不能联调 → 验收只覆盖华为与 iOS。

## Migration Plan

1. Go：APNs/HMS 点击载荷，vivo/oppo 占位。
2. Flutter：暂存、主页分流、消息 Tab。
3. 真机：杀进程、后台、前台横幅各点一次 UCG 与预测通知；未登录与缺字段各一次。
4. 回滚：去掉点击监听与主页消费即可恢复「只打开 App」；Go 多带的 `bizType` 对旧客户端无行为。

## Open Questions

- （已关闭）未登录留在预测页；资格未过停在锁页；未知类型不跳；前台横幅同样跳；先主页再 UCG 再消息 Tab；vivo/oppo/小米真实下发不验收。
