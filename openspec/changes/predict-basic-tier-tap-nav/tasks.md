## 1. 文案

- [x] 1.1 更新基础版音箱条目：标题「家中音箱 · 免动手」；副标题实体硬件/脱离手机/纯语音记查；保留 demo「可付费开通」

## 2. 行点击与路由

- [x] 2.1 基础版能力行整行可点：先关墙，再按 kind 执行落地表（家庭仅关墙；估算仅关墙）
- [x] 2.2 推送→`/settings/notifications`；小组件→`/widgets/showcase`；趋势→`/trends`；音箱→`/settings/xiaozhi-speaker`
- [x] 2.3 demo 保持 IgnorePointer，点击落在行上

## 3. 投屏与语音球桥

- [x] 3.1 抽出预测页投屏确认+锁横屏为可复用流程；增加 request provider，墙 tap landscapeCast 关墙后触发
- [x] 3.2 `EdgeDockController` 增加 `showEngaged`（不触发 onPullBusiness）；语音球 listen request，peek→贴边 engaged
- [x] 3.3 已 floating 时 engage 请求 no-op

## 4. 校验

- [x] 4.1 `dart analyze` 相关文件无新增 error
- [ ] 4.2 手测：八条落地符合表；投屏确认；语音球贴边全圆可点且不自动听写；设置页仍可称小智
- [x] 4.3 Android 原生未改：**N/A** release APK
