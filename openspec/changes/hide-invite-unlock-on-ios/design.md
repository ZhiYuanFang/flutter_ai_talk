## Context

功能开通中心按 catalog 的 `unlockMethods` / `inviteAvailable` 经 `FeatureCatalogItem.supportsInviteCode` 决定是否展示「输入邀请码激活」。模块侧介绍弹窗已无邀请输入框，点「其它方式」进开通中心。预测槽位满额邀码产品能力已下线，但预测页仍残留对 `invite_code_dialog` 的 import，且 `v2.1.2` 基线中 `prediction-toggle-slot-gate` 仍含与「槽位商业已删除」相冲突的旧 Requirement。

产品目标：规避 iOS 审核——原生 iOS App 不得提供非付费的邀请码开通；Android 与 Web 保留。

## Goals / Non-Goals

**Goals:**

- 原生 iOS App 上 `supportsInviteCode` 恒为 false，无视后台配置。
- Android / Web 行为不变（仍认 catalog）。
- 清理预测页死 import；规格删除槽位满额邀码过时需求，共享弹窗文案不再绑定 slot-full。

**Non-Goals:**

- 不隐藏免费体验、支付、VIP。
- 不隐藏广场「我的邀请码」发码。
- 不在客户端或服务端硬挡 `invite-codes/redeem`（本次仅 UI/闸门语义）。
- 不要求后台按平台拆分 `unlockMethods`。

## Decisions

### 1. 唯一闸门：`supportsInviteCode`

- **选择**：在 `feature_unlock_models.dart` 的 getter 上叠加平台条件。
- **理由**：开通中心已唯一依赖该 getter；未来新入口若跟同一语义可自动生效。
- **替代方案**：仅在 Hub UI `if` —— 易漏；服务端按平台下发 —— 审核仍可能被旧包/缓存绕过，且产品要求「不管后台如何配置」。

### 2. 平台判定：`!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS`

- **选择**：用 `foundation` 的 `kIsWeb` + `defaultTargetPlatform`，不用 `dart:io`。
- **理由**：Web 必须可展示邀请码；若仅用 `defaultTargetPlatform == iOS`，iPhone Safari 上的 Web 会被误伤。与 `vip_payment_service` 等现有平台分支风格一致。
- **替代方案**：`Platform.isIOS` —— 需 `dart:io`，不利于 Web 编译路径进 models。

### 3. 规格清理策略

- **选择**：对 `prediction-toggle-slot-gate` 中仍要求满额邀码 / 槽位闸的旧 Requirement 做 **REMOVED**；保留已存在的「Forecast toggle SHALL not be gated by prediction slot cap」。
- **理由**：基线自相矛盾；归档合并时 REMOVED 比留两套对立 SHALL 更干净。

## Risks / Trade-offs

- **[Risk] iOS 上某功能仅配置 invite、无 payment** → 卡上无邀请 CTA，可能只剩体验或空白。  
  **Mitigation**：运营保证 iOS 可见付费能力带 payment SKU；本 change 不改支付展示逻辑。

- **[Risk] 审核员通过其它路径发现 redeem 仍可用** → UI 隐藏通常足够；本次不做 API 硬挡。  
  **Mitigation**：若审核仍失败，后续再加 iOS redeem 拒绝或服务端按 client platform 拒兑。

- **[Trade-off] Web 在 iOS 浏览器仍可邀码** → 符合产品「web 也可」；App Store 审的是原生包。

## Migration Plan

- 纯客户端行为变更，无数据迁移。
- 回滚：还原 `supportsInviteCode` 与规格 delta。

## Open Questions

- （无）探索阶段已确认：仅原生 iOS 隐藏；Web/Android 保留；改 getter 即可；槽位邀码规格删除。
