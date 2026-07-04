## Context

- **v2.0.3 基线**：`HomeScreen` 记录喂养事件；`HistoryRecord` 经 WS + 分页 API 同步；`HomeHistoryStore` 按 `deviceNo` 落盘（升序 items）；`EventCatalogStore` 提供事件名/色；`BabyProfile.birthDate` 存 SharedPreferences；进行中计时判定见 `isActiveTimingRecord` / `activeTimingStartAt`。
- **现状**：无间隔预测模块；无 `home_widget`；iOS 工程存在但无 Widget Extension / App Group。
- **约束**：见 `openspec/project.md`——小组件不得 WS/副作用 HTTP；预拉须 single-flight + 熔断；Android 原生改动须 release 构建 + proguard；Debug 新 tag 三联改；不新增 `*_test.dart`。

## Goals / Non-Goals

**Goals:**

- 纯 Dart 预测模块：分时段桶 + 加权中位数 + 月龄半衰期 → `nextAt`。
- Android + iOS 标准 small/medium/large 小组件；假玻璃马卡龙视觉；头部 `{昵称} · {n}个月啦`。
- 四态 payload：`loading` / `empty` / `ready` + 相对文案 native 渲染。
- 首次启用预拉历史深度；历史/登录/宝宝资料变更时 `updateWidget`。
- 登出写 empty payload，避免泄露旧数据。

**Non-Goals:**

- Web 桌面小组件；后端新 API；widget 内一键记事件（可后续 deep link 仅打开 App）。
- 真 `BackdropFilter` 磨砂（性能与原生限制）；用户自选事件子集（全局 nextAt 排序）。
- 自动化 widget 测试。

## Decisions

### 1. 依赖：`home_widget`

- **决策**：使用社区包 `home_widget` 作 Flutter ↔ 原生数据桥与 `updateWidget` API。
- **理由**：双端维护成本低于自研 Platform Channel；iOS 仍需 SwiftUI Extension，但读写 UserDefaults/App Group 有成熟范例。
- **备选**：纯 Platform Channel —— 工作量大，无显著收益。

### 2. 预测算法

- **发生时刻**：`one`/`number` 用 `startTime ?? createdAt`；已结束 `time` 用 `endTime`；进行中 `time` 不参与间隔、单独 active 行。
- **噪声过滤**：相邻间隔 `< 15min` 丢弃。
- **分时段**：6 桶（0–6, 6–9, 9–12, 12–15, 15–18, 18–24）；锚点桶权重 1.0，相邻 0.6，其余 0.2。
- **时间衰减**：`recencyWeight = exp(-ln(2) * ageDays / halfLifeDays)`。
- **月龄半衰期**：

  | 月龄 | halfLifeDays |
  |------|----------------|
  | 0–2 | 7 |
  | 2–4 | 10 |
  | 4–6 | 14 |
  | 6–12 | 21 |
  | 12+ | 30 |

  birthDate 无效/placeholder → 默认 14 天。

- **聚合**：加权中位数；候选 `< 2` 则放宽为全桶仅 recency；仍 `< 2` → 不可预测。
- **nextAt**：`lastAt + predictedInterval`；`nextAt < now` → overdue。

### 3. 小组件行编排

```
activeRows = 所有 isActiveTimingRecord，按 startAt 升序
predictRows = 可预测且非 active 的 event，按 nextAt 升序
slots: small=1, medium=3, large=6
content = activeRows.take(maxActive) + predictRows.take(slots - active占用)
```

Type 1：有 active 则仅 1 条 active；否则 top-1 predict。

### 4. Payload schema（`home_widget` 共享 JSON）

```json
{
  "state": "loading|empty|ready",
  "message": "正在准备数据…|打开胖宝记录|null",
  "widgetKind": "small|medium|large",
  "header": {
    "nickname": "宥宥",
    "birthDate": "2026-01-04",
    "displayLine": "宥宥 · 6个月啦"
  },
  "visual": {
    "shellGradientStart": "#B8DFF2",
    "shellGradientEnd": "#E8F4FC",
    "glassFillTop": "#F7FCFF",
    "glassFillBottom": "#EEF6FB",
    "borderColor": "#FFFFFFD1",
    "textPrimary": "#3D454C",
    "textSecondary": "#7A8690",
    "cornerRadius": 18,
    "rowRadius": 12
  },
  "rows": [
    {
      "kind": "active",
      "eventId": "12",
      "name": "睡眠",
      "startAt": "2026-07-04T01:00:00+08:00",
      "color": "#5BA3E8"
    },
    {
      "kind": "predict",
      "eventId": "3",
      "name": "喂奶",
      "nextAt": "2026-07-04T03:00:00+08:00",
      "status": "overdue|upcoming",
      "color": "#E88BB0"
    }
  ],
  "updatedAt": "2026-07-04T03:07:00+08:00"
}
```

- **相对文案**（overdue / upcoming / elapsed）在 **native 渲染时**由 `startAt`/`nextAt` 与 `now` 计算，不写死字符串。
- **header.displayLine** 为 fallback；native 优先用 `birthDate` 重算月龄（跨日准确）。

### 5. 四态 UX

| state | 头部 | 主体 |
|-------|------|------|
| `loading` | 有宝宝资料则显示 | 「正在准备数据…」 |
| `empty` | 未登录不显示；已登录可有 | 「打开胖宝记录」 |
| `ready` | 显示 | active + predict 行 |

预拉超时 **30s** → 用现有缓存尽力 `ready`/`empty`。

### 6. 历史深度预拉

- **触发**：小组件首次 install 回调；App 内「添加小组件」引导；App 启动检测到 widget 已装且 `widgetHistoryDepthReady != true`。
- **实现**：`ensureWidgetHistoryDepth()` single-flight；循环 `loadMoreHistory` 直到：已覆盖 **30 天**最早记录、或 **15 页**、或 `hasMore==false`。
- **与 UI 合并**：与 `loadMoreHistory` 共用 in-flight；连续 **3 页**失败熔断。
- **完成**：`widgetHistoryDepthReady=true`（SharedPreferences）→ 预测 → `updateWidget`。

### 7. 刷新触发

| 事件 | 动作 |
|------|------|
| 历史增删改 / WS push | 重算 + updateWidget |
| persistToDisk 后 | updateWidget |
| 登录成功 | 预拉 → updateWidget |
| 登出 | empty payload |
| 宝宝资料 save | 重算（半衰期+头部） |
| 主题 preset 变更 | 更新 visual tokens |

**禁止**：provider `create` 自动预拉或 updateWidget。

### 8. 视觉：假玻璃（非 BackdropFilter）

对齐 `UcgFeedFakeGlassPanel` / `BabyProfileClayTheme`：马卡龙底 `#B8DFF2`、半透白渐变、白描边、软阴影、圆角 18；事件行左侧 3dp 色条。Android Glance / iOS SwiftUI 用 payload `visual` 常量实现。

### 9. iOS 架构

- 新建 **Widget Extension** target `PangbaoWidget`。
- Runner + Extension 共享 App Group（如 `group.com.fzy.pangbao.widget`）。
- `home_widget` 写 Group UserDefaults；Timeline Provider 按 `nextAt` 排 refresh entry。

### 10. Android 架构

- 三个 `AppWidgetProvider`（或单 provider + `widgetKind` meta），对应 small/medium/large。
- `AndroidManifest` 注册 + `proguard-rules.pro` `-keep`。
- 合并前 `flutter build apk --release`。

### 11. Deep link

- 点击小组件 → `pangbao://home` 或 `home_widget` 默认 launch URI；未登录路由到登录。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 小组件倒计时不会秒级刷新 | payload 存绝对时间，native 渲染时计算；Timeline 15–30min |
| 历史仅 1 页时预测不准 | 首次预拉 + loading 态 |
| iOS Extension 签名/App Group 配置复杂 | design 附 checklist；TestFlight 验证 |
| 预拉与用户 scroll loadMore 竞态 | single-flight 共用 `loadMoreHistory` |
| 假玻璃无 blur 不够「透」 | 马卡龙渐变 + 白边仍符合产品可爱风 |
| birthDate placeholder 导致月龄/半衰期偏差 | 无效日期回退默认半衰期；头部仍显示「宝宝」 |

## Migration Plan

1. **Phase A**：Dart 预测 + App 内预览列表（无 native）。
2. **Phase B**：`home_widget` bridge + Android 三尺寸。
3. **Phase C**：iOS Extension + App Group。
4. **Phase D**：设置引导、登出 empty、release 验证。
5. **回滚**：移除 manifest/extension 注册；卸载 widget 不影响 App 主流程。

## Open Questions

- （已关闭）预拉目标：30 天或 15 页 ✓
- （已关闭）空态文案：「打开胖宝记录」✓
- （已关闭）loading：「正在准备数据…」✓
- App 内是否单独「小组件设置」页 —— 实现时可在设置加简短引导，非必须独立页。
