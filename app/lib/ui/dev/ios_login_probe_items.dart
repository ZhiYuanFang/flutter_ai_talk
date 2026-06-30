/// Home 进房后 pangbao / notify 探针项（不 mount feed/ucg repo）。
enum HomeProbeItem {
  voiceAsrWs,
  ucgChatWs,
  ucgUnreadNotif,
  ucgUnreadConv,
  eventOptions,
  historyList,
  userGet,
  versionCheck,
  logoDownload,
  iosDelay2s,
  historyWs,
  notifyBanner,
  realFeedWatchLatest,
  realUcgRepoMount,
  realLogoDeferredBackground,
  realHomeProviderWatch,
}

extension HomeProbeItemMeta on HomeProbeItem {
  String get label => switch (this) {
        HomeProbeItem.voiceAsrWs => 'WS Voice ASR',
        HomeProbeItem.ucgChatWs => 'WS ucg/chat',
        HomeProbeItem.ucgUnreadNotif => 'HTTP ucg/notifications/comments',
        HomeProbeItem.ucgUnreadConv => 'HTTP ucg/conversations',
        HomeProbeItem.eventOptions => 'HTTP event/options',
        HomeProbeItem.historyList => 'HTTP history/list',
        HomeProbeItem.userGet => 'HTTP user/get',
        HomeProbeItem.versionCheck => 'HTTP version/check',
        HomeProbeItem.logoDownload => 'HTTP logo 下载',
        HomeProbeItem.iosDelay2s => 'iOS 等待 2s（Home WS 前）',
        HomeProbeItem.historyWs => 'WS history',
        HomeProbeItem.notifyBanner => 'HTTP notify banner',
        HomeProbeItem.realFeedWatchLatest => 'REAL feed.watchLatest + history WS',
        HomeProbeItem.realUcgRepoMount => 'REAL ucgRepository + chat WS',
        HomeProbeItem.realLogoDeferredBackground => 'REAL runDeferredLogoDownloads（不 await）',
        HomeProbeItem.realHomeProviderWatch => 'REAL watch homeHistory + catalog',
      };

  String get phaseTitle => switch (this) {
        HomeProbeItem.voiceAsrWs ||
        HomeProbeItem.ucgChatWs ||
        HomeProbeItem.ucgUnreadNotif ||
        HomeProbeItem.ucgUnreadConv =>
          'A · initState / _init 旁路',
        HomeProbeItem.eventOptions ||
        HomeProbeItem.historyList ||
        HomeProbeItem.userGet =>
          'B · GatewayBootstrapGate',
        HomeProbeItem.versionCheck => 'C · postLogin',
        HomeProbeItem.logoDownload => 'D · iOS deferred logo',
        HomeProbeItem.iosDelay2s || HomeProbeItem.historyWs => 'E · iOS WS 延迟 + history',
        HomeProbeItem.notifyBanner => 'F · notify（独立 host）',
        HomeProbeItem.realFeedWatchLatest ||
        HomeProbeItem.realUcgRepoMount ||
        HomeProbeItem.realLogoDeferredBackground ||
        HomeProbeItem.realHomeProviderWatch =>
          'R · real Home providers',
      };

  bool get requiresWx => switch (this) {
        HomeProbeItem.ucgChatWs ||
        HomeProbeItem.ucgUnreadNotif ||
        HomeProbeItem.ucgUnreadConv ||
        HomeProbeItem.realUcgRepoMount =>
          true,
        _ => false,
      };

  bool get isWebSocket => switch (this) {
        HomeProbeItem.voiceAsrWs ||
        HomeProbeItem.ucgChatWs ||
        HomeProbeItem.historyWs =>
          true,
        _ => false,
      };

  bool get isRealProviderMount => switch (this) {
        HomeProbeItem.realFeedWatchLatest ||
        HomeProbeItem.realUcgRepoMount ||
        HomeProbeItem.realLogoDeferredBackground ||
        HomeProbeItem.realHomeProviderWatch =>
          true,
        _ => false,
      };

  bool get isNotifyHost => this == HomeProbeItem.notifyBanner;

  bool get isDelayOnly => this == HomeProbeItem.iosDelay2s;

  int slotWeight({required int logoConcurrency}) => switch (this) {
        HomeProbeItem.voiceAsrWs ||
        HomeProbeItem.ucgChatWs ||
        HomeProbeItem.historyWs =>
          1,
        HomeProbeItem.logoDownload => logoConcurrency,
        HomeProbeItem.iosDelay2s => 0,
        HomeProbeItem.notifyBanner => 0,
        HomeProbeItem.realFeedWatchLatest ||
        HomeProbeItem.realUcgRepoMount ||
        HomeProbeItem.realLogoDeferredBackground ||
        HomeProbeItem.realHomeProviderWatch =>
          0,
        _ => 1,
      };
}

/// Home 已登录进房时序（wx 用户含 UCG 旁路）。
const homeProbeTimeline = <List<HomeProbeItem>>[
  [
    HomeProbeItem.voiceAsrWs,
    HomeProbeItem.ucgChatWs,
    HomeProbeItem.ucgUnreadNotif,
    HomeProbeItem.ucgUnreadConv,
  ],
  [
    HomeProbeItem.eventOptions,
    HomeProbeItem.historyList,
    HomeProbeItem.userGet,
  ],
  [HomeProbeItem.versionCheck],
  [HomeProbeItem.logoDownload],
  [HomeProbeItem.iosDelay2s, HomeProbeItem.historyWs],
  [HomeProbeItem.notifyBanner],
];

/// logo 数量：0 = catalog 全量（与 Home `runDeferredLogoDownloads` 一致）。
const kProbeLogoCountAll = 0;

/// logo 并发：0 = 不限制（worker 数 = logo 事件数，复刻改前 Home 6 并发时可选手动选 6）。
const kProbeLogoConcurrencyUnlimited = 0;

/// 改前 Home iOS logo 并发上限。
const kProbeLogoConcurrencyHomeLegacy = 6;

const homeProbeInitBypass = [
  HomeProbeItem.voiceAsrWs,
  HomeProbeItem.ucgChatWs,
  HomeProbeItem.ucgUnreadNotif,
  HomeProbeItem.ucgUnreadConv,
];

const homeProbeGateSerial = [
  HomeProbeItem.eventOptions,
  HomeProbeItem.historyList,
  HomeProbeItem.userGet,
];

Set<HomeProbeItem> homeProbeWxPreset() => {
      HomeProbeItem.voiceAsrWs,
      HomeProbeItem.ucgChatWs,
      HomeProbeItem.ucgUnreadNotif,
      HomeProbeItem.ucgUnreadConv,
      HomeProbeItem.eventOptions,
      HomeProbeItem.historyList,
      HomeProbeItem.userGet,
      HomeProbeItem.versionCheck,
      HomeProbeItem.logoDownload,
      HomeProbeItem.iosDelay2s,
      HomeProbeItem.historyWs,
      HomeProbeItem.notifyBanner,
    };
