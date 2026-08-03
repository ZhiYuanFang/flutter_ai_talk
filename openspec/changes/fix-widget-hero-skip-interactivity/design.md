## Context

- `widget-hero-skip-next` 已实现：Dart 回调、Android skip PendingIntent、iOS Button+AppIntent。
- 插件 `home_widget` 的 library Manifest **不**自带 Background Receiver/Service；example 与官方文档要求宿主声明。
- 当前 App Manifest 仅有三个 Widget Provider → Android 点跳过 Broadcast 无接收方。
- iOS 侧已有 `WidgetBackgroundIntent`、`ForegroundContinuableIntent`、`AppDelegate.setPluginRegistrantCallback`；CI ruby 尝试双 target 加入 Intent 源文件。Extension 是否链接 `home_widget`/Flutter 生成插件包仍需核对（SPM/CI 路径）。

## Goals / Non-Goals

**Goals:**

- Android「跳过」能进入 Dart `homeWidgetInteractiveCallback` 并刷新 hero。
- iOS 交互接线无「同类缺注册」缺口；文档化验收清单。
- release 构建通过。

**Non-Goals:**

- 不改 S1 / hero-only 过滤 / tip 注入。
- 不改为打开 App 再 skip 的 deep link 主路径。

## Decisions

1. **Android Manifest 按 example 原文声明**  
   `HomeWidgetBackgroundReceiver`（action `BACKGROUND`）+ `HomeWidgetBackgroundService`（`BIND_JOB_SERVICE`）。  
   **备选**：自写 BroadcastReceiver → 否决（偏离插件契约）。

2. **父级 click**  
   Manifest 修好后若仍「点跳过却开 App」，从 `attachLaunchClick` 去掉 `widget_hero_row` / `widget_hero_section`（保留 logo/name/time 或仅 root 打开），保证 skip 子控件独占。

3. **iOS 核对清单（防同类问题）**  

   | 项 | 现状预期 | 动作 |
   |----|----------|------|
   | AppIntent 源双 target | ruby 已 ensure | 确认 CI/本地 pbx 含 Runner+Extension |
   | ForegroundContinuableIntent | 已有 | 保留 |
   | setPluginRegistrantCallback | AppDelegate 已有 | 保留 |
   | Extension 链接 home_widget | 可能缺口 | CI/README：SPM 加 `FlutterGeneratedPluginSwiftPackage` 或 Podfile extension target |
   | iOS&lt;17 | 无按钮 | 保持 |

4. **callbackHandle**  
   用户重装后须至少冷启一次 App，使 `registerInteractivityCallback` 写入 handle；tasks 写明验收步骤。

## Risks / Trade-offs

- [仅 hot reload 不装原生] → 验收要求完整重装。  
- [Android 12+ 后台限制] → 依赖插件 JobIntentService；失败看 `HomeWidgetService` log。  
- [iOS Extension 未链 home_widget] → 编译失败或按钮无效；CI 补链接。

## Migration Plan

- 纯客户端；回滚即移除 Manifest 两项（跳过再次失效）。

## Open Questions

- （无）
