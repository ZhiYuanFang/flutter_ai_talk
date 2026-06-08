## Context

`ucg-moments-compose-redesign` 已实现 compose 业务逻辑（9 宫格拖拽、草稿三选、AI 润笔、入口分流）。当前 compose 使用 `UcgSurfaceCard` + `UcgImmersiveHeader`（含 title/subtitle），入口 sheet 为 Material 默认样式，相册路径在 `ucg_compose_entry_sheet.dart` 中二次弹出图片/视频选择后调用 `image_picker`。

喂养模块已有可复用玻璃组件：

- `HistoryEditGlassPanel` — 磨砂 blur + 渐变 + 微光描边（`home_history_edit_glass_panel.dart`）
- `showGlassAdaptiveBottomSheet` / `showGlassDialog` / `showGlassConfirmDialog`（`app_glass_overlay.dart`）

`ucg-minimal-visual-system` 规定 UCG 内联 UI 禁止玻璃，但产品已接受 **发布动线单独可爱玻璃分叉**。

## Goals / Non-Goals

**Goals:**

- 发布动线全链路玻璃拟态：入口 sheet、拍摄子 sheet、自建相册页、compose 单块 glass panel、退出三选 glass dialog。
- 微信式 compose 顶栏（取消 | 发表），无标题；发表按钮 `ColorScheme.primary`。
- 自建相册页 + 选择侧 photo/video 互斥（最多 9 图 / 1 视频）。
- 九宫格 glass 圆角 cell；拖拽删除底部浮层保留微信红条。
- Web 相册降级路径。

**Non-Goals:**

- go_ai_talk 任何 API/DB/Admin 变更。
- 广场/消息/我的 Tab 内联 UI 玻璃化。
- 自定义相机 UI（拍摄仍用 `image_picker` camera + 玻璃子 sheet）。
- 相册内多相册切换、iCloud 全量能力（首版默认 Recent/全部）。
- 自动化测试文件。

## Decisions

### 1. 玻璃范围 = 发布动线临时 route

仅以下 surface 使用 `HistoryEditGlassPanel` / glass overlay：

```
入口 sheet → [相册页] → compose → 退出 dialog
     └── 拍摄子 sheet
```

Tab 内联（feed 卡片、消息列表等）仍用 `UcgSurfaceCard`。

**理由**：避免与 `ucg-minimal-visual-system` 全面冲突；动线结束即回到简约 shell。

### 2. Compose 布局

```
Scaffold(shellColor + 可选 primary 轻渐变)
├── 顶栏 Row: TextButton「取消」 | Spacer | FilledButton「发表」(primary, StadiumBorder)
└── SingleChildScrollView
    └── HistoryEditGlassPanel(eventAccent: primary)
        ├── ManagedKeyboardTextField (hint: 这一刻的想法…)
        ├── UcgComposeImageGrid (glass cells)
        └── AI润笔 TextButton (条件显示)
```

移除 `UcgImmersiveHeader` title/subtitle。键盘 bridge 行为不变（`ucg.compose.body`）。

### 3. 自建相册页架构

**Route**：`Navigator.push` 全屏 `UcgAlbumPickerScreen`（非 bottom sheet，更接近微信相册）。

**依赖**：`photo_manager` + `permission_handler`。

**选择状态机**（`UcgAlbumSelectionController`）：

| 状态 | 规则 |
|------|------|
| `idle` | 图片/视频均可选 |
| `photoMode` | 已选 1–9 图；video cells `disabled` |
| `videoMode` | 已选 1 视频；photo cells `disabled` |

**完成**：读取 `AssetEntity` file → 现有 `ucgUploadBytes` / compress → `UcgComposeInitialMedia` → pop。

**顶栏**：取消 | 已选 N/9 或「已选 1 个视频」| 完成（primary 胶囊，无选中时 disabled）。

### 4. 入口 sheet 变更

- `showUcgComposeEntrySheet` 改用 `showGlassAdaptiveBottomSheet`。
- 「从手机相册选择」→ `Navigator.push(UcgAlbumPickerScreen)`，**删除** 59–79 行图片/视频二次 sheet。
- 「拍摄」→ 玻璃子 sheet（拍照/录像）保持不变。

### 5. 退出 dialog

扩展 `showGlassDialog` 为三按钮：**放弃** | **取消** | **保存草稿**（或等效布局），替换 compose 内 `AlertDialog`。

空内容仍直接 pop，不弹窗。

### 6. 九宫格视觉

- 图片 cell：`BorderRadius.circular(12)` + `Border.all(white 0.15)`，无 per-cell BackdropFilter（性能）。
- 「+」cell：`HistoryEditGlassTapField` 风格半透明白底。
- 拖拽删除：现有 `UcgComposeDeleteOverlay` 保留。

### 7. Web 降级

```dart
if (kIsWeb) {
  // pickMultipleMedia(limit: 9) → classify mime → reject mixed with toast
} else {
  // UcgAlbumPickerScreen
}
```

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| `photo_manager` 权限被拒 | 空态 + 引导打开设置 |
| 大相册首屏卡顿 | 分页 80 条 + thumbnailDataWithSize(200) |
| iOS Limited Photos | 首版仅展示已授权范围；后续可加「管理授权」 |
| 玻璃 blur Web 性能 | compose 单 panel；cell 不用 blur |
| 与 minimal visual spec 冲突 | OpenSpec MODIFIED 发布动线例外 |
| 新依赖体积 | 仅 compose 动线引用，Accept |

## Migration Plan

1. 添加 `photo_manager`、`permission_handler` 及平台权限文案。
2. 实现 `UcgAlbumPickerScreen` + 互斥 controller。
3. 玻璃化 entry/capture sheet 与 exit dialog。
4. 重构 `UcgComposeScreen` 顶栏与 glass panel。
5. 更新九宫格 cell 样式。
6. 手工 QA：iOS/Android 相册互斥、compose 玻璃、Web 降级。

**Rollback**：feature 可逐文件回退；无后端 migration。

## Open Questions

- 相册页是否在 shell 上加极浅 primary 渐变底（建议：是，增强可爱感）。
- iOS Limited Photos 管理入口是否首版必做（建议：否，Phase 2）。
