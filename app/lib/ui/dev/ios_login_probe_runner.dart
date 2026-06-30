import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exceptions.dart';
import '../../api/gateway_json.dart';
import '../../data/event_catalog_store.dart';
import '../../data/history_list_page.dart';
import '../../data/notify_banner_repository.dart';
import '../../providers/authorized_api_client_provider.dart';
import '../../ucg/data/ucg_api_client.dart';
import '../../ucg/data/ucg_models.dart';
import 'ios_login_probe_items.dart';
import 'ios_login_probe_real_mounts.dart';
import 'ios_login_probe_transports.dart';

class ProbeRunResult {
  const ProbeRunResult({
    required this.label,
    required this.ok,
    required this.elapsedMs,
    this.detail,
    this.skipped = false,
  });

  final String label;
  final bool ok;
  final int elapsedMs;
  final String? detail;
  final bool skipped;
}

class IosLoginProbeRunner {
  IosLoginProbeRunner({
    required this.ref,
    required this.transports,
    required this.deviceNo,
    required this.version,
    required this.wxBound,
    required this.forceChatWs,
    required this.logoCount,
    required this.logoConcurrency,
    this.realMounts,
    this.onRealMountChanged,
  });

  final WidgetRef ref;
  final IosLoginProbeTransports transports;
  final IosLoginProbeRealMounts? realMounts;
  final VoidCallback? onRealMountChanged;
  final String deviceNo;
  final String version;
  final bool wxBound;
  final bool forceChatWs;
  final int logoCount;
  final int logoConcurrency;

  Future<List<ProbeRunResult>> runPollutionHttpCheck() async {
    return [
      await _runOne(HomeProbeItem.versionCheck),
      await _runOne(HomeProbeItem.notifyBanner),
    ];
  }

  Future<List<ProbeRunResult>> runParallel(Set<HomeProbeItem> selected) async {
    final items = selected.where((i) => !i.isDelayOnly).toList();
    if (items.isEmpty) return const [];
    return Future.wait(items.map(_runOne));
  }

  /// 复刻 Home **真实重叠**：initState 旁路（UCG/Voice）与 gate 并行；logo 不 await；2s 后再 history WS。
  Future<List<ProbeRunResult>> runHomeActualBurst(Set<HomeProbeItem> selected) async {
    final out = <ProbeRunResult>[];
    final inflight = <Future<ProbeRunResult>>[];

    for (final item in homeProbeInitBypass) {
      if (selected.contains(item)) inflight.add(_runOne(item));
    }

    for (final item in homeProbeGateSerial) {
      if (!selected.contains(item)) continue;
      out.add(await _runOne(item));
    }

    if (selected.contains(HomeProbeItem.versionCheck)) {
      out.add(await _runOne(HomeProbeItem.versionCheck));
    }

    if (selected.contains(HomeProbeItem.logoDownload)) {
      inflight.add(_runOne(HomeProbeItem.logoDownload));
    }

    final needsDelay = selected.contains(HomeProbeItem.iosDelay2s) ||
        selected.contains(HomeProbeItem.historyWs);
    if (needsDelay && selected.contains(HomeProbeItem.iosDelay2s)) {
      final sw = Stopwatch()..start();
      await Future<void>.delayed(const Duration(seconds: 2));
      out.add(ProbeRunResult(
        label: HomeProbeItem.iosDelay2s.label,
        ok: true,
        elapsedMs: sw.elapsedMilliseconds,
        detail: 'wait 2s (overlap gate/init)',
      ));
    } else if (needsDelay) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (selected.contains(HomeProbeItem.historyWs)) {
      out.add(await _runOne(HomeProbeItem.historyWs));
    }

    if (selected.contains(HomeProbeItem.notifyBanner)) {
      inflight.add(_runOne(HomeProbeItem.notifyBanner));
    }

    if (inflight.isNotEmpty) {
      out.addAll(await Future.wait(inflight));
    }
    return out;
  }

  Future<List<ProbeRunResult>> runHomeTimeline(Set<HomeProbeItem> selected) async {
    final out = <ProbeRunResult>[];
    for (final phase in homeProbeTimeline) {
      final phaseItems = phase.where(selected.contains).toList();
      if (phaseItems.isEmpty) continue;

      final delays = phaseItems.where((i) => i.isDelayOnly).toList();
      final runnable = phaseItems.where((i) => !i.isDelayOnly).toList();

      if (delays.isNotEmpty) {
        for (final _ in delays) {
          final sw = Stopwatch()..start();
          await Future<void>.delayed(const Duration(seconds: 2));
          out.add(ProbeRunResult(
            label: HomeProbeItem.iosDelay2s.label,
            ok: true,
            elapsedMs: sw.elapsedMilliseconds,
            detail: 'wait 2s',
          ));
        }
      }

      if (runnable.isEmpty) continue;

      final isParallelPhase = phase.length > 1 &&
          phase.first.phaseTitle == HomeProbeItem.voiceAsrWs.phaseTitle &&
          runnable.every((i) => i.phaseTitle == HomeProbeItem.voiceAsrWs.phaseTitle);

      if (isParallelPhase) {
        out.addAll(await Future.wait(runnable.map(_runOne)));
      } else {
        for (final item in runnable) {
          out.add(await _runOne(item));
        }
      }
    }
    return out;
  }

  Future<ProbeRunResult> _runOne(HomeProbeItem item) async {
    if (item.requiresWx && !wxBound && !(item == HomeProbeItem.ucgChatWs && forceChatWs)) {
      return ProbeRunResult(
        label: item.label,
        ok: true,
        elapsedMs: 0,
        detail: 'skipped: no wxId',
        skipped: true,
      );
    }

    final sw = Stopwatch()..start();
    try {
      switch (item) {
        case HomeProbeItem.voiceAsrWs:
          final o = await transports.connectVoiceAsr(deviceNo: deviceNo);
          return _wsToResult(item.label, o, sw);
        case HomeProbeItem.ucgChatWs:
          final o = await transports.connectChat(ref: ref, forceIgnoreWxId: forceChatWs);
          return _wsToResult(item.label, o, sw);
        case HomeProbeItem.historyWs:
          final o = await transports.connectHistory(ref: ref, deviceNo: deviceNo);
          return _wsToResult(item.label, o, sw);
        case HomeProbeItem.ucgUnreadNotif:
          await _runUcgUnreadNotif();
        case HomeProbeItem.ucgUnreadConv:
          await _runUcgUnreadConv();
        case HomeProbeItem.eventOptions:
          await _runEventOptions();
        case HomeProbeItem.historyList:
          await _runHistoryList();
        case HomeProbeItem.userGet:
          await _runUserGet();
        case HomeProbeItem.versionCheck:
          await _runVersionCheck();
        case HomeProbeItem.logoDownload:
          await _runLogoDownloads();
        case HomeProbeItem.notifyBanner:
          await _runNotifyBanner();
        case HomeProbeItem.realFeedWatchLatest:
          realMounts?.mountFeedWatchLatest(ref);
          return ProbeRunResult(
            label: item.label,
            ok: true,
            elapsedMs: sw.elapsedMilliseconds,
            detail: 'feedRepository mounted · watchLatest + ensureHistoryWebSocketConnected',
          );
        case HomeProbeItem.realUcgRepoMount:
          if (item.requiresWx && !wxBound) {
            return ProbeRunResult(
              label: item.label,
              ok: true,
              elapsedMs: 0,
              detail: 'skipped: no wxId',
              skipped: true,
            );
          }
          realMounts?.mountUcgRepo(ref);
          return ProbeRunResult(
            label: item.label,
            ok: true,
            elapsedMs: sw.elapsedMilliseconds,
            detail: 'ucgRepository mounted · mountUcgHomeTransportsIfEligible',
          );
        case HomeProbeItem.realLogoDeferredBackground:
          realMounts?.startLogoDeferredUnawaited(ref);
          return ProbeRunResult(
            label: item.label,
            ok: true,
            elapsedMs: sw.elapsedMilliseconds,
            detail: 'runDeferredLogoDownloads unawaited (background)',
          );
        case HomeProbeItem.realHomeProviderWatch:
          realMounts?.enableHomeProviderWatch();
          onRealMountChanged?.call();
          return ProbeRunResult(
            label: item.label,
            ok: true,
            elapsedMs: sw.elapsedMilliseconds,
            detail: 'ref.watch homeHistory + eventCatalog enabled in probe build',
          );
        case HomeProbeItem.iosDelay2s:
          break;
      }
      return ProbeRunResult(label: item.label, ok: true, elapsedMs: sw.elapsedMilliseconds);
    } on ApiHttpException catch (e) {
      return ProbeRunResult(
        label: item.label,
        ok: false,
        elapsedMs: sw.elapsedMilliseconds,
        detail: 'HTTP ${e.statusCode}',
      );
    } on ApiBusinessException catch (e) {
      return ProbeRunResult(
        label: item.label,
        ok: false,
        elapsedMs: sw.elapsedMilliseconds,
        detail: 'code=${e.code} ${e.message}',
      );
    } catch (e) {
      return ProbeRunResult(
        label: item.label,
        ok: false,
        elapsedMs: sw.elapsedMilliseconds,
        detail: e.toString(),
      );
    }
  }

  ProbeRunResult _wsToResult(String label, ProbeWsOutcome o, Stopwatch sw) {
    if (o.skipped) {
      return ProbeRunResult(
        label: label,
        ok: true,
        elapsedMs: o.elapsedMs,
        detail: 'skipped: ${o.detail}',
        skipped: true,
      );
    }
    return ProbeRunResult(
      label: label,
      ok: o.ok,
      elapsedMs: o.elapsedMs > 0 ? o.elapsedMs : sw.elapsedMilliseconds,
      detail: o.detail,
    );
  }

  Future<void> _runEventOptions() async {
    final api = ref.read(authorizedApiClientProvider);
    await api.getEnvelope(
      '/device/history/api/event/options',
      query: {'deviceNo': deviceNo},
      withAuthorization: true,
    );
  }

  Future<void> _runHistoryList() async {
    final api = ref.read(authorizedApiClientProvider);
    await api.getEnvelope(
      '/device/history/api/list',
      query: {
        'deviceNo': deviceNo,
        'page': '1',
        'pageSize': '$kHomeHistoryPageSize',
      },
      withAuthorization: true,
    );
  }

  Future<void> _runUserGet() async {
    final api = ref.read(authorizedApiClientProvider);
    await api.getEnvelope(
      '/device/app/api/user/get',
      query: {'deviceNo': deviceNo},
      withAuthorization: true,
    );
  }

  Future<void> _runVersionCheck() async {
    final api = ref.read(authorizedApiClientProvider);
    await api.getEnvelope(
      '/device/app/api/version/check',
      query: {'currentVersion': version},
      withAuthorization: false,
    );
  }

  Future<void> _runUcgUnreadNotif() async {
    final ucg = UcgApiClient(ref.read(authorizedApiClientProvider));
    await ucg.get(
      '/notifications/comments',
      query: UcgApiClient.pageQuery(page: 1, pageSize: kUcgPageSize),
    );
  }

  Future<void> _runUcgUnreadConv() async {
    final ucg = UcgApiClient(ref.read(authorizedApiClientProvider));
    await ucg.get(
      '/conversations',
      query: UcgApiClient.pageQuery(page: 1, pageSize: kUcgPageSize),
    );
  }

  Future<void> _runNotifyBanner() async {
    await const NotifyBannerRepository().fetchBanner();
  }

  Future<void> _runLogoDownloads() async {
    final api = ref.read(authorizedApiClientProvider);
    final data = await api.getEnvelope(
      '/device/history/api/event/options',
      query: {'deviceNo': deviceNo},
      withAuthorization: true,
    );
    final list = envelopeListOrEmpty(data);
    final allWithLogo = parseEventOptionsList(list)
        .where((e) => e.logoUrl != null && e.logoUrl!.isNotEmpty)
        .toList();
    final events = logoCount <= kProbeLogoCountAll
        ? allWithLogo
        : allWithLogo.take(logoCount).toList();
    if (events.isEmpty) return;

    var index = 0;
    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= events.length) return;
        final event = events[i];
        await EventCatalogStore.downloadLogoIfNeeded(event, {event.id: event});
      }
    }

    final workers = logoConcurrency <= kProbeLogoConcurrencyUnlimited
        ? events.length
        : logoConcurrency.clamp(1, events.length);
    await Future.wait(List.generate(workers, (_) => worker()));
  }
}
