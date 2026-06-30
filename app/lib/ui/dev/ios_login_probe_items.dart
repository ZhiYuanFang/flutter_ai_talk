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
      };

  bool get requiresWx => switch (this) {
        HomeProbeItem.ucgChatWs ||
        HomeProbeItem.ucgUnreadNotif ||
        HomeProbeItem.ucgUnreadConv =>
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
