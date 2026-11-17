## Context

Pro 商业路径今天分叉：设置「功能开通」与墙底栏「立即开通」都进 `FeatureUnlockHubScreen`，Hub 内再支付/邀请/试用。墙已能直调 Pro `trial/start`。产品决定：**删 Hub 与设置开通卡**；**付费只在 3h 两档墙内**；**不接邀请码**；清历史媒体缓存保留。

## Goals / Non-Goals

**Goals:**

- 用户可达开通面仅剩：3h 卡 → 两档墙（试用 + 墙内付费）。
- 删除 Hub 路由与设置开通入口；死链回退。
- Pro 无邀请码 CTA。
- 支付确认 UX 对齐 Hub 既有确认弹窗（价/天数/功能色），Web 不可真付。

**Non-Goals:**

- 不删「清除历史媒体缓存」；切号不强制清 `EventMediaLocalStore`。
- 不改小智 MCP 开通页。
- 不改 Go 邀请/支付 API 契约（客户端少调邀请）。
- 不回退整卡开墙 / `Icons.upgrade`。
- 不重做 deviceNo 媒体分桶。

## Decisions

1. **墙内付费替换 openHub 跳转**  
   - `PredictTierFooterKind.openHub`（或重命名 `payInWall`）在可付费且 eligibility 通过时：确认弹窗 → `featurePaymentService.purchase(defaultProduct)` → toast → `featureCatalogStateProvider.refresh`；成功后底栏应变「已开通」。  
   - 资格不足：沿用「暂未开放」或 toast 服务端 message（与 Hub 一致）。  
   - 备选：删「立即开通」只留试用 → 否决（产品要收银）。

2. **硬删 Hub**  
   - 删除/停用 `FeatureUnlockHubScreen`；`app_router` 去掉 `/features/unlock`（或 redirect → `/home`）。  
   - 设置去掉「功能开通」tile。  
   - `/features/invite-howto`：若仅 Hub 引用则可删路由；Pro 路径不得再链到它。  
   - 备选：保留空壳 Hub → 否决（产品要砍）。

3. **邀请码**  
   - 墙与设置 **不得** 出现 Pro 邀请入口；不调用 `redeemInviteCode` 于 Pro 开通路径。  
   - `showInviteCodeDialog` 代码可暂留（防其它功能），本变更 Pro 零调用。

4. **清媒体缓存**  
   - 明确 Non-Goal：入口与 `clearAll` 行为不变；wipe 仍不清媒体。

## Risks / Trade-offs

- [旧书签进 Hub] → 路由 redirect `/home`，避免白屏。  
- [嵌套 dialog：墙全屏 + 支付确认] → 确认用 glass overlay 叠在墙之上，关确认不关墙；与 Hub 叠层一致。  
- [catalog 仍标 inviteAvailable] → 客户端忽略，不展示。  
- [ai_analysis_unlock 死链] → 删除跳转或整文件若已无引用。

## Migration Plan

- 纯客户端发版；无需数据迁移。  
- 回滚：恢复 Hub 路由与设置卡、墙改回 `push` Hub。

## Open Questions

- （无）邀请不接、墙内直付、保留清媒体已锁定。
