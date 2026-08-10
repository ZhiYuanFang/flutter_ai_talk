## 1. 共享飞入与落点抽象

- [x] 1.1 抽出 LandingTarget（prepare / measureGlobalCenter）与共享 Fly Overlay（由 HomeEventRecordFlyOverlay 泛化，无锚点则不启动动画）
- [x] 1.2 增加可见页门闸的飞入请求编排（读当前 home PageView 页；feeding/prediction 才 requestFly；全变动触发，去掉 isNew/awaiting 门槛）

## 2. 喂养页接线

- [x] 2.1 FeedingLanding 包装既有 HomeHistoryScroll 滚底与 record logo 测锚
- [x] 2.2 HomeScreen 改用共享编排 + FeedingLanding；清理 _awaitingWsFlyIds 飞入门槛逻辑

## 3. 预测页接线

- [x] 3.1 预测卡为当前展示 EventLogo 槽挂 GlobalKey；PredictionLanding 按 root eventId 映射并 ensureVisible 后测锚
- [x] 3.2 SmartPredictionScreen 在可见且收到飞入请求时挂同一套 Overlay

## 4. 验收

- [x] 4.1 手动确认：预测/喂养可见时 create 与 update 可飞；删除无锚点不飞；预测离屏卡先滚再飞；UCG 不飞；连播以最新为准
