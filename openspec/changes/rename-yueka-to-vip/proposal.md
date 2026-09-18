## Why

用户可见文案仍混用「月卡」与「VIP」：已开通态多为「VIP · 剩余…」，未开通引导与开通方式标签仍称「月卡」，品牌与沟通不一致。产品要求展示统一为 VIP；计费 / `isVip` / 购买接口不变。

## What Changes

- 开通中心底栏、按钮、过期副文、VIP 购买页区块标题、`unlockMethod=vip` 展示标签中的「月卡」改为「VIP」对应文案。
- 不改 productCode、支付链路、有效天数履约或代码标识符（`isVip`、`CashVip*` 等可保留）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `feature-unlock-hub`：开通中心与开通方式标签用户文案「月卡」→「VIP」。
- `vip-purchase-ux`：VIP 购买页「月卡包含…」→「VIP 包含…」（若基线以该能力描述购买页；否则并入 `feature-unlock-hub` / 等价 VIP 购买表面）。

## Impact

- Flutter：`feature_unlock_hub_screen.dart`、`vip_purchase_screen.dart`、`feature_unlock_models.dart`（`displayUnlockMethod`）。
- OpenSpec 既有 change 文档中的「月卡」可不改（历史记录）；合并基线经本 change delta 更新。
- 无 Android / Go / 测试文件变更。
