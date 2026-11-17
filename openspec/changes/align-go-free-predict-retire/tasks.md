## 1. 核对 Go 契约与支付语义

- [x] 1.1 确认功能单/小智继续 `POST /cash/app/api/vip/apple/verify`（历史兼容路径；body 不变）；保留服务端 `message` 展示；成功后改刷 catalog/小智 unlock，去掉 `vip/status` 刷新；验单从 VIP repository 语义迁出（或注释标明非 VIP）
- [x] 1.2 接线 `GET /cash/app/api/predict-pro/eligibility`（single-flight、失败熔断；不挡免费预测/进度）
- [x] 1.3 更新 README 支付/验单说明：标明 `vip/apple/verify` 为历史路径、履约功能/小智；去掉 VIP product/status/orders 主路径描述

## 2. 单轨亲和与卡上进度

- [x] 2.1 删除展示/静默双轨与 `predictDisplayEntitled` / basic∨pro∨VIP helper；tip、预测卡、3h、widget、pending 统一亲和 `nextAt`
- [x] 2.2 实现按 `predictionBucketKey` 的有效发生计数（≥15min、目标 `kMinSamplesForPrediction+1`）与进度 helper
- [x] 2.3 预测卡原倒计时区：无 nextAt 显示横条进度 +「再有 x 条真实{事件名}记录后…」；有 nextAt 恢复预测 UI
- [x] 2.4 调整回忆种子：不再强制展示预测；亲和可独立产出时可清种子；评估 interval sheet 文案（不承诺付费开通算法）

## 3. 免费 / Pro 两档 chrome

- [x] 3.1 将 3h 后缀与全屏墙从三档（间隔/基础/Pro+VIP）改为两档（免费版/Pro版）；去掉 VIP→基础版映射
- [x] 3.2 删除 `predict_capability_basic` 试用/支付/Hub 卡路径；Hub 仅保留 Pro 壳与其它仍存活项
- [x] 3.3 去掉预测页对 VIP settle 的 await；同步占位仅覆盖 catalog/Pro eligibility（若需要）

## 4. 删除 VIP / care / growth / clinic / AI 分析

- [x] 4.1 删除 VIP repository/provider/购页/sticky/底部月卡入口及 `isVip` OR 覆盖；清理 bootstrap VIP 预热
- [x] 4.2 删除 care-alert、成长轨迹、诊疗/陪伴、喂养分析、AI 分析 Hub 的路由、UI、provider 与 API 客户端
- [x] 4.3 去掉预测页「AI分析」「值得留意」入口；修正开通中心对已删功能的导航与 eligibility 预热
- [x] 4.4 清理 debug 日志 tag / `logcat_api_http.ps1` / README Debug 表中已删表面条目（三联一致）

## 5. 收尾校验

- [x] 5.1 手工路径：未购 Pro 可见亲和预测或进度；Pro 后缀/墙/eligibility；iOS 功能或小智验单不打 VIP verify
- [x] 5.2 确认无残留对已删 VIP/care/growth/clinic/ai-analysis 路由的可达入口
- [x] 5.3 若本变更改动 `app/android/**` 或原生 SDK：跑 `flutter build apk --release` 并按需更新 `proguard-rules.pro`
