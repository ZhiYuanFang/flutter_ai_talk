## 1. 依赖与档位模型

- [x] 1.1 `pubspec.yaml` 增加 `carousel_slider` 并 `flutter pub get`
- [x] 1.2 抽出当前预测档枚举/映射（syncing / 间隔 / 基础 / Pro；VIP→基础标题）供 3h 与墙共用

## 2. 接下来3小时

- [x] 2.1 去掉整卡进喂养；保留 AI分析
- [x] 2.2 标题行加粗同字号 `·` 后缀；ready 可点开墙；syncing 占位不可点
- [x] 2.3 移除 `PredictCapabilityStatusCard` 挂载（可删文件或留未引用）

## 3. 全屏三档墙

- [x] 3.1 全屏壳 + 右上关闭；`carousel_slider` 中卡放大两侧露出；`initialPage`=当前档
- [x] 3.2 间隔卡：主题色玻璃文案、无图、底栏当前节奏/VIP已开通
- [x] 3.3 基础/Pro 卡：catalog 色 + logo（有则展示）+ 描述；底栏按态表
- [x] 3.4 非 VIP 基础「开通试用」墙内 `trial/start`；成功刷新 catalog；Pro「暂未开放」；无 trial 资格时可「立即开通」进 Hub

## 4. 验收

- [ ] 4.1 手工：无独立能力卡；后缀与 VIP/pro/basic/间隔映射正确
- [ ] 4.2 手工：仅后缀与 AI分析可点；正文不进喂养
- [ ] 4.3 手工：墙滑动、VIP 底栏、基础试用、Pro 暂未开放
