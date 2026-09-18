## 1. 文案替换

- [x] 1.1 `feature_unlock_hub_screen.dart`：底栏标题 / 按钮 / 副文「月卡」→「VIP」
- [x] 1.2 `vip_purchase_screen.dart`：「月卡包含的更多功能」→「VIP 包含的更多功能」
- [x] 1.3 `feature_unlock_models.dart`：`featureUnlockMethodLabel` 的 `vip` 分支返回「VIP」

## 2. 验收

- [x] 2.1 开通中心未 VIP：无「月卡」字样，引导与按钮为 VIP
- [x] 2.2 仅 VIP 解锁的功能卡：开通方式标签映射为「VIP」（`featureUnlockMethodLabel`）
- [x] 2.3 VIP 购买页区块标题为 VIP 命名
- [x] 2.4 无新建 test；未改 Android 原生
