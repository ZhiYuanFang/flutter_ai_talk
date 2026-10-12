## 1. 小智 MCP 支付

- [x] 1.1 修改 `app/lib/services/xiaozhi_mcp_payment_service.dart`：`verifyApple` 的 `catch (_)` 改为 `on ApiBusinessException` 透传非空 `message`，其它异常保留「验单失败，请稍后重试」
- [x] 1.2 失败路径增加 `AppDebugLog`（沿用既有 tag）记录 `err=`，禁止静默吞错

## 2. 功能开通支付

- [x] 2.1 修改 `app/lib/services/feature_payment_service.dart`：同上透传 `ApiBusinessException.message`
- [x] 2.2 确认已有 `AppDebugLog.featureUnlock` 覆盖验单失败（不足则补）

## 3. VIP 核对与验收

- [x] 3.1 核对 `vip_payment_service.dart` 已透传业务 `message`；无需改则跳过代码
- [ ] 3.2 手工验收：换 App 账号复用同一 Apple 交易验单，小智/功能路径展示「一个 Apple 账号仅支持开通一个胖宝账号」（需后端 cash 已部署）
- [x] 3.3 不新增 `*_test.dart`
