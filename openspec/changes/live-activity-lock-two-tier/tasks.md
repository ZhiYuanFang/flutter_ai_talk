## 1. 锁屏中文到分钟 helper

- [x] 1.1 在 `PredictLiveActivityViews.swift`（或同 Extension 共享文件）实现分钟粒度文案：Timing「已过去h时m分钟」/`h=0`→「已过去m分钟」；Imminent「预计m分钟后」；不足 1 分钟按 1；Imminent 过期返回空
- [x] 1.2 用 `TimelineView` 按分钟档（或等价）驱动锁屏时间刷新，锁屏路径不再依赖 `timerInterval` 秒级展示

## 2. 锁屏双层布局

- [x] 2.1 Imminent / Timing 锁屏 content 改为 VStack：上层圆形 BrandLogo +「胖宝」（事件提亮色）；下层事件 logo + 既有标题函数 + Spacer + 中文时间（过期 Imminent 不渲染时间位）
- [x] 2.2 下层事件 logo / 标题 / 时间相对现状约放大一倍；时间靠右；标题语义保持 `lockTitle` / `timingLockTitle`
- [x] 2.3 删除锁屏「已过时」展示路径

## 3. 灵动岛 hh:mm:ss

- [x] 3.1 Imminent / Timing 的 compact trailing 与 expanded trailing 改为自格式化零填充 `hh:mm:ss`（不足 1h 仍含时）；仍包在 `CompactIslandTimeSlot` 内
- [x] 3.2 Imminent 过期时 Island 时间位不展示「已过时」或其它时间维文案；compact 三字名与胶囊宽度策略保持不变

## 4. 文档与目视

- [x] 4.1 更新 `LIVE_ACTIVITY.md`：锁屏双层、中文到分钟、Island `hh:mm:ss`、过期无时间文案（不改推送字段表）
- [x] 4.2 真机/模拟器目视：双层锁屏、中文规则、过期无右侧时间、Island 始终 `hh:mm:ss` 且 compact 不拉满宽
