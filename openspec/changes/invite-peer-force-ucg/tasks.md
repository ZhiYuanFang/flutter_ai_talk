## 1. 数据层

- [x] 1.1 模型/repository：invite mine/invitees、force ledger、catalog `totalActivatableCount`
- [x] 1.2 开通中心/预测：解析永久 allowedCount；VIP 不作为「已全部激活」

## 2. UCG 个人中心

- [x] 2.1 「我的」展示邀请码入口 + 邀请详情页（说明 + 列表）
- [x] 2.2 等级图标可点 + 积分详情（当前分、流水、距升级、获取方式）

## 3. 开通中心与预测

- [x] 3.1 预测卡：已激活 X / 已全部激活；价签「现价+删除线原价/个」+ 输入邀请码；未满始终显示（含 VIP）
- [x] 3.2 月卡底栏悬浮 + 有效期文案
- [x] 3.3 预测页锁：永久条数 OR VIP；文案去「激活码全开」预期

## 4. 验收

- [x] 4.1 与 Go 契约联调清单自检
- [x] 4.2 `openspec validate invite-peer-force-ucg --strict`
