/// UCG / 产品表面编译期功能开关。
///
/// 宝藏入口：首版临时关闭，下版上线时改回 `true`。
const kUcgTreasureEnabled = false;

/// 主壳 PageView 是否含 UCG 广场页。
/// 商业化重开（commercial-ucg-feature-unlock）：三页主壳喂养 | 预测 | UCG。
///
/// 开通 UCG 且需要「动态距离」定位时，务必恢复 geolocator：
/// 1) pubspec 加回 geolocator；2) 还原 ucg_location 真实现；
/// 3) Manifest LOCATION + 隐私/用途披露；4) 扫包确认 SDK 有意进包。
/// （android-store-compliance：上架期剔除定位 SDK。）
const kUcgHomePagerEnabled = false;

/// 历史编辑「同步广场」开关与 UCG 发帖/改帖/删帖副作用。
const kHistorySquareSyncEnabled = false;

/// 预测页横屏语音助手（KWS 唤醒 / 监听 chip / chat / 字幕）。
/// 默认开启；翻 `false` 可紧急关闭横屏入口。
/// 竖屏语音入口为「去记录」长按 PTT（见 PredictionGoRecordFab），不再使用贴边球 flag。
const kPredictionLandscapeVoiceEnabled = true;
