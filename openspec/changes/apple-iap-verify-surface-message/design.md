## Context

`VipPaymentService` 在 Apple 验单失败时已：

```dart
} on ApiBusinessException catch (e) {
  return VipPaymentOutcome(success: false, message: e.message);
}
```

`XiaozhiMcpPaymentService` / `FeaturePaymentService` 在 `verifyApple` 外层使用 `catch (_)` 或 `catch (e)` 后写死「验单失败，请稍后重试」，导致 cash 返回的跨 wx 拒绝文案无法展示。

基线参考：`openspec/specs/v2.1.3.md` 能力 `cash-vip-client`（含 iOS Apple verify）。小智 MCP 支付尚未进该基线能力名，本变更以新能力统一三条支付路径的验单错误透传。

## Goals / Non-Goals

**Goals:**

- 三条 Apple 验单路径对 `ApiBusinessException` 均透传非空 `message`。
- 保留通用 fallback，避免空文案。
- 失败路径打 `AppDebugLog`（可用既有 tag，如 `cashVip` / `featureUnlock`）。

**Non-Goals:**

- 不改建单、StoreKit 调起、`appAccountToken` 传递。
- 不改后端错误码/文案（由 `go_ai_talk` `apple-iap-cross-wx-reject` 负责）。
- 不新增测试文件；不改 Android 支付宝文案策略。

## Decisions

### 1. 对齐 VIP：`on ApiBusinessException` + fallback

- **选择**：`catch` 拆成 `on ApiBusinessException`（展示 `e.message`，空则 fallback）与其它 `catch`（固定「验单失败，请稍后重试」）。
- **理由**：与 VIP 一致，改动面最小；`ApiClient` 已把 `{code,message}` 转成该异常。
- **备选**：UI 层统一解析异常 → 改动面更大，否决。

### 2. 小智与功能两处都改

- **选择**：两文件对称修改；VIP 已符合则只加日志核对或不动。
- **理由**：用户复现路径是小智；功能同样硬编码，一并修避免下一轮再踩。

### 3. 不新增 Debug tag

- **选择**：沿用现有 `AppDebugLog.featureUnlock` / `AppDebugLog.cashVip`（或小智侧已有 tag）。
- **理由**：避免三联改 tag 白名单；本变更仅为透传 message。

## Risks / Trade-offs

- [Risk] 服务端 message 过长或含内部信息 → **Mitigation**：cash 已固定短中文；客户端原样展示即可。
- [Risk] 非 `ApiBusinessException` 仍显示通用文案 → **可接受**（网络/超时）。

## Migration Plan

1. 合并 Flutter 改动并发版（TestFlight / 内测包）。
2. 与已部署的 cash-service 联调：换号复购应看到「一个 Apple 账号仅支持开通一个胖宝账号」。
3. 回滚：回退 App 版本即可（行为退回硬编码文案）。

## Open Questions

- 无。
