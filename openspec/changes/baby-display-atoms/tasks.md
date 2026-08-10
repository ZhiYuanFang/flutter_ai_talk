## 1. L1 原子

- [x] 1.1 在 `baby_age.dart`（或同级）新增 `displayBabyNickname` / `displayBabyAgeText` / `displayBabyIdentityLine` / `displayBabyId` / `displayBabySex`，复用既有 `formatBabyAgeText`，并注释与小组件截断 API 的分流

## 2. 调用方迁移

- [x] 2.1 喂养沉浸头接线改为展示原子（含合成行或分字段）
- [x] 2.2 预测顶栏昵称/月龄/头像入参改为展示原子
- [x] 2.3 喂养空历史「还没有为 {name} 记录」改用 `displayBabyNickname`

## 3. 验收

- [x] 3.1 静态核对：无资料/空白昵称回退一致；设置「待设置」与小组件截断未误改；`dart analyze` 相关文件无新增 error
