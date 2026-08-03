## 1. 呈现 polish

- [x] 1.1 顶部居中胖宝平拍圆（`kStartupIconAsset`）；去掉卡内 `ScrollView`
- [x] 1.2 「关闭」「对话」改为不透明实色/tonal 默认底

## 2. 拖动与四边最小化

- [x] 2.1 展开态拖动平移；未过半松手回弹居中
- [x] 2.2 过半宽/高松手 → morph 为圆并吸入该边（左/右/上/下）；docked 保留 tip 内容
- [x] 2.3 docked 点圆（或拖出）→ expanded；与输入 mode dock 沿边错开 along
- [x] 2.4 listen `presentationGeneration`：若 docked 则强制居中 expanded 并再播弹性入场

## 3. 验收

- [ ] 3.1 手工：顶标/实色按钮/无滚动；四边吸入与点圆展开；关闭仍销毁
- [ ] 3.2 手工：docked 时再添加 → 强制居中弹性再弹；尽量不与输入球完全重叠
- [x] 3.3 未改 `app/android/**` 则无需 release APK
