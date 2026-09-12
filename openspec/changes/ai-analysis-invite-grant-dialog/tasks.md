## 1. 服务端 DDL 与授予逻辑（go_ai_talk）

- [x] 1.1 `feature_def` 增加 `invite_duration_days` / `ad_duration_days`，回填自 `duration_days`
- [x] 1.2 `ActivateFeature`：invite 读 `invite_duration_days`，ad 读 `ad_duration_days`
- [x] 1.3 Admin 读写两新列（旧 `durationDays` 双写或同步）；清 feature_def 缓存

## 2. 服务端 Catalog 下发（go_ai_talk）

- [x] 2.1 `FeatureCatalogItem` / `CashFeatureCatalogItem` 增加 `inviteDurationDays` / `adDurationDays`
- [x] 2.2 `GetFeatureCatalog` 从定义行填入两字段；controller 映射完整

## 3. 客户端模型

- [x] 3.1 `FeatureCatalogItem` 解析 `inviteDurationDays` / `adDurationDays`
- [x] 3.2 禁止邀请文案回落 `products[].durationDays`；缺字段弱化天数

## 4. AI 分析开通弹框

- [x] 4.1 合格未开通：`showInviteCodeDialog`（标题智能分析、confirm 开通、正文含邀请天数折中话术）
- [x] 4.2 HowTo → invite-howto；空码 → `/features/unlock`；有码 redeem care-alert + refresh + 留页
- [x] 4.3 弹框 TextEditingController 继续由弹层 State 持有（复用既有组件）

## 5. 校验

- [x] 5.1 `openspec validate ai-analysis-invite-grant-dialog --strict`
- [ ] 5.2 手测：合格未开通弹框 / 空码进开通中心 / 有码开通后分析页门闸翻转

## 6. 开通中心文案对齐

- [x] 6.1 邀请弹框非预测项展示 `inviteDurationDays`（缺字段弱化）；正文用「功能标题」而非「此功能」
- [x] 6.3 AppBar 标题改为「功能开通」
