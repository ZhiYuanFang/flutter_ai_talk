## 1. Provider：手动 daily 与日限

- [x] 1.1 为「今日已手动成功刷新」增加上海日 + deviceNo 持久化读写（prefs/store）
- [x] 1.2 调整 `PredictionCareAlertNotifier`：暴露手动刷新 API；成功写日限；保留 single-flight
- [x] 1.3 移除 `predictionCareAlertProvider` 跨日自动 `force` ensure 及其它自动 daily 触发
- [x] 1.4 从 `UcgHomeShell` 去掉进预测 / fetchAllowed listen 触发的 daily ensure（eligibility 勿误伤）
- [x] 1.5 从 `home_widget_sync`（及同类路径）去掉为 tip/展示而调用的 care-alert daily ensure；grep 确认无残留自动 daily

## 2. 预测页入口

- [x] 2.1 移除智能预测热态「值得留意」`_CareAlertPanel` 分支（游客滑动引导可留）
- [x] 2.2 `_NextThreeHoursTimeline`：去掉展开/收起，正文全量展示
- [x] 2.3 标题行右侧增加独立手势圆角「AI分析」，整卡其余区域仍进喂养

## 3. AI 分析页

- [x] 3.1 新增分析页 UI：喂养记录分析 + 成长轨迹浅占位；颜色走 `AppColor`
- [x] 3.2 喂养模块：资格进度 / 开通引导 / 列表；进页可 ensure eligibility+catalog，不自动 daily
- [x] 3.3 「AI智能分析」/「正在思考中」/ 成功 Toast 与日限藏按钮 / 失败可重试
- [x] 3.4 列表项导航既有 `/prediction/alert`；`app_router` 注册分析页路由

## 4. 桌面小组件 tip 与 large×6

- [x] 4.1 Flutter payload/sync：不再填充展示用 tip；large recent `count` 改为 6（排除 hero 逻辑保持）
- [x] 4.2 Android `widget_pangbao_large.xml` 增加第二行 recent 槽 3..5；medium tip 区隐藏策略对齐
- [x] 4.3 `PangbaoWidgetRenderer.kt` 绑定/隐藏扩到 0..5；tip section 无文案时 GONE
- [x] 4.4 更新 `home_widget_large_preview`（及 showcase 若展示 tip/3 槽）与两行 6 候选一致
- [x] 4.5 确认陪伴 tip 桥接：无缓存不注入、不为桥接拉 tip/daily

## 5. 验收

- [x] 5.1 手工路径：预测页无留意卡 → AI分析 → 门闸 → 思考中 → 成功 Toast 日限 → 详情；失败可重试
- [x] 5.2 因改动 `app/android/**`，本地执行 `flutter build apk --release` 通过；若 R8 报 Missing class，按 `project.md` 更新 `proguard-rules.pro`
- [x] 5.3 `openspec validate ai-analysis-care-alert-relocate --strict` 通过

## 6. 补齐 iOS + payload 缺口

- [x] 6.1 `buildHomeWidgetPayload` recent `count` 4→6，且排除 hero
- [x] 6.2 `widget_interactivity` 跳过重建不再回填 tip
- [x] 6.3 iOS `PangbaoWidget.swift`：去掉 medium/large tip；large 两行×最多 6

## 7. 喂养分析解释条

- [x] 7.1 标题下增加折中话术说明（小字 + 圆角底），各门闸态均展示

## 8. 开通引导心跳

- [x] 8.1 合格未开通文案：ScaleTransition 心跳（~900ms，0.96–1.04）+ primary 强调
