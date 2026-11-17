## 1. 权益模型与 trial API

- [x] 1.1 在 `feature_unlock_models.dart` 增加 `predict_capability_basic` / `predict_capability_pro` 常量
- [x] 1.2 `FeatureUnlockRepository` 实现 `POST /cash/app/api/feature/trial/start`；成功/业务错误打 `AppDebugLog`（新 tag 则三联改）
- [x] 1.3 增加 `isPredictDisplayEntitled`（basic∨pro 有效 ∨ settled isVip）及按 featureId 读 catalog 辅助；副作用路径 await 共享 VIP settle

## 2. 双轨预测与种子门闸

- [x] 2.1 在 `buildSmartPredictionBundle`（或紧邻层）拆分静默亲和轨与展示轨；未 entitle 强制种子 nextAt
- [x] 2.2 `smartPendingPredictionsProvider` / imminent sync 只消费静默轨；rows / tip / 3 小时 / 小组件只消费展示轨
- [x] 2.3 修改 `predictionRecallSeedsActiveProvider` 清种子逻辑：对齐「未 entitle 保留；已 entitle 且亲和可独立产出才 drop；禁止仅 raw 样本门槛 drop」
- [x] 2.4 验证按根并存：A 种子展示 + B 亲和，互不误清

## 3. 首次提醒与点试用弹窗

- [x] 3.1 宝宝维（deviceNo）「算法就绪已提醒」本地 store；纳入 `wipeAccountLocalState`
- [x] 3.2 预测页检测：静默轨任一非预约根亲和就绪 ∧ 未 entitle ∧ 未提醒 → 玻璃弹窗（绿底白勾 √、取消/立即体验）；一展示即写已提醒
- [x] 3.3 「立即体验」直接 trial/start(basic)；成功刷新 catalog + 成功弹窗（x 天到期 + 回退固定间隔小字）；失败提示

## 4. 能力卡与调间隔

- [x] 4.1 在接下来3小时与事件列表之间增加预测能力卡（文案优先级：pro→basic→VIP→基础版待开通→固定间隔）；点击进开通页
- [x] 4.2 展示轨为种子 nextAt 的行：预测时刻旁调间隔小按钮，复用 interval picker + upsertSeed

## 5. 开通中心

- [x] 5.1 开通中心展示 basic/pro catalog 卡；basic 支付/邀请/免费体验走既有或 trial/start
- [x] 5.2 Pro 支付/邀请/试用点击统一「功能尚未上线」，不建单、不兑码、不 trial/start

## 6. 验收

- [ ] 6.1 手工：未开通时卡/tip/3h/小组件为种子，pending 日志或抓包为亲和；开通后展示切亲和
- [ ] 6.2 手工：弹窗只出一次；取消后再进不弹；立即体验成功切展示；已 VIP/basic 不弹
- [ ] 6.3 手工：修并存 bug——他根算法就绪后，本根种子仍可预测且可调间隔
- [x] 6.4 本变更无 `app/android/**` 原生改动则跳过 release/R8；若触及则补 `flutter build apk --release` 与 proguard
