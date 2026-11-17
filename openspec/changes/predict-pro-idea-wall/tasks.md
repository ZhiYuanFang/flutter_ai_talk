## 1. 数据层

- [x] 1.1 模型 + repository：list / submit / like / unlike（对齐 Go）
- [x] 1.2 Riverpod：进墙 single-flight 拉 list；提交/点赞后更新
- [x] 1.3 若新增 Debug tag：三联改 `app_debug_log` / `logcat_api_http.ps1` / README

## 2. Pro 墙想法区

- [x] 2.1 Catalog MD 不变；卡外脚保持「敬请期待/正在使用」
- [x] 2.2 空态：底对齐圆形「我有想法」心跳 + 付费意愿小字
- [x] 2.3 有数据：约定标题/热度/采纳小字；卡片布局；火赞；`isMine` 高亮；「我有更多想法」+ 小字

## 3. 作曲 Sheet

- [x] 3.1 新建底浮玻璃 Sheet（不改墙 dialog 结构）；State 持有 controller
- [x] 3.2 键盘：整张 Sheet 跟 `viewInsets` 上移
- [x] 3.3 发送成功 → pop → 刷新墙内想法

## 4. 验收

- [ ] 4.1 联调 Go：空态→提交→列表高亮本人→赞/取消→Admin 改文案/删除
- [x] 4.2 确认无支付/trial；采纳仅文案；排序新在前
