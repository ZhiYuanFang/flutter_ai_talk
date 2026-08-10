## 1. 门闸状态

- [x] 1.1 增加登录/绑定 Dialog 可见状态（及可选 gate kind）；**不**引入永久 dismissed
- [x] 1.2 按优先级计算当前门闸：未登录 > 未绑定 > 量身定做；互斥关闭其它 Dialog

## 2. UI 与交互

- [x] 2.1 登录引导 Dialog（文案 + CTA → `/login`）；遮罩软关；非头像再弹
- [x] 2.2 绑定引导 Dialog（文案 + CTA → `/settings/bind-baby`）；遮罩软关；非头像再弹
- [x] 2.3 头像保持进 `/settings`（未登录先登录），不触发再弹
- [x] 2.4 底层保持冷态骨架 + 假留意

## 3. 条件解除与验收

- [x] 3.1 listen 登录/deviceNo：条件解除停对应 Dialog；登录后仍未绑定则切绑定引导
- [x] 3.2 `openspec validate prediction-auth-bind-dialog --strict`；手工冒烟未登录/未绑定/绑定成功/与量身定做互斥
- [x] 3.3 软关后再弹改为 tap（GestureDetector.onTap），禁止 pointerDown 误弹
