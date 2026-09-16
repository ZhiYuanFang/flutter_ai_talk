## 1. Go：权益模型与 Catalog

- [x] 1.1 新增 `feature_user_trial`（或等价）表：`(wx_id, feature_id)` 唯一，记录 unused/used 与 used_at
- [x] 1.2 care `activation_subject` 改为 user；Activate/Access 只读 `feature_user_entitlement`；支付 SKU 改为 30 天（无永久）
- [x] 1.3 growth 保持 user；确认支付 30d / 邀请 7d 种子与 Admin 一致
- [x] 1.4 catalog 合成下发 `trialAvailable`、`inviteAvailable`；VIP/已开通时 `trialAvailable=false`
- [x] 1.5 从 feature_def / unlock_methods / 履约路径移除 ad；停用或下线 `prediction_unlock` 商品与 allowed_count 履约

## 2. Go：邀请码瘦身

- [x] 2.1 删除同宝宝（同 device_no）拒绝逻辑与 `InviteOncePerDevice` 读写
- [x] 2.2 `InviteOncePerUser` 扩展到 care + growth；人×功能邀请成功一次后不可再兑
- [x] 2.3 保留：不可自用、人×码×功能不重复；兑换成功仍走 ActivateFeature 邀请 7d

## 3. Go：试用 claim 与访问门闸

- [x] 3.1 Access：`VIP || 用户权益未过期 || trial unused`（care 另保留喂养达标）
- [x] 3.2 在 care / growth **首次成功落库**路径原子 claim：trial→used + ActivateFeature(channel=trial, 24h)
- [x] 3.3 试用窗允许多次生成（受日限）；失败不 claim；claim 后走普通权益

## 4. Go：日额度与结果隔离

- [x] 4.1 care：取消 device 日缓存短路；改为 wxId 日限默认 5、每次成功刷新最新结果
- [x] 4.2 care / growth latest 存储与读取键改为 `(wx_id, device_no)`
- [x] 4.3 GET latest / 进详情拉缓存路径不消耗日额度；生成成功才 INCR

## 5. Flutter：契约与权益辅助

- [x] 5.1 `FeatureCatalogItem` 增加 `trialAvailable` / `inviteAvailable`；解析 catalog；废弃 ad 驱动 CTA
- [x] 5.2 更新 `isFeatureEffectivelyUnlocked` 与槽位相关 helper：删除或恒放开 prediction slot 门闸
- [x] 5.3 删除/停用广告开通 repository 调用与开通中心广告确认流

## 6. Flutter：开通中心与弹窗

- [x] 6.1 开通中心：去「看广告」；按 `inviteAvailable` 显示邀请；`trialAvailable` 时最右侧「免费体验」+ 一次机会确认弹窗 → 进详情
- [x] 6.2 过滤或不再展示 `prediction_unlock` 槽位商品卡
- [x] 6.3 替换 `openCareAlert/Growth…InviteUnlockDialog`：功能介绍、无输入框、主按钮标价支付、「其它方式开通」→ `/features/unlock`

## 7. Flutter：AI Hub / 详情 / 设置

- [x] 7.1 Hub 喂养卡未达标：确认弹窗后再跳喂养；取消则停留
- [x] 7.2 喂养分析详情：将「AI智能分析」与说明移到正文下方横向居中；文案对齐日 5 次
- [x] 7.3 详情进页自动加载该用户该宝宝 latest；生成成功后刷新 catalog（领取试用态）
- [x] 7.4 设置：登录后宝宝卡下「功能开通」卡片 → `/features/unlock`；移除头像下开通摘要入口

## 8. Flutter：删除预测槽位死代码

- [x] 8.1 智能预测页：移除基于 `allowedCount` 的锁浮层与满额邀码开槽流程
- [x] 8.2 清理 `prediction_unlock` 相关 UI/文案/常量引用（开通中心、dialog brand、howto 槽位话术等）

## 9. 联调与验收

- [ ] 9.1 双端联调：试用 A 路径（多次生成、首次成功 claim 24h）、邀请一次、支付 30d、日 5 次、换账号结果隔离
- [ ] 9.2 手工验收 proposal 中 1–9 UX/规则条目；确认无广告、无槽位、设置入口正确
- [x] 9.3 本变更无 `app/android/**` 原生改动则不强制 release APK；若触及原生再补 `flutter build apk --release` 与 proguard
