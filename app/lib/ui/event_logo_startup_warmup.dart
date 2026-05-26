import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import 'event_logo.dart';

/// 冷启动阶段将事件 logo 解码进 [ImageCache]，减轻进主页首帧闪烁。
class EventLogoStartupWarmup {
  EventLogoStartupWarmup._();

  static const _maxConcurrent = 6;

  static Future<void> precacheCatalog(
    BuildContext context,
    List<EventDefinition> catalog,
  ) async {
    if (catalog.isEmpty) return;
    final started = DateTime.now();
    var done = 0;
    await _runPool(
      [
        () => precacheImage(const AssetImage(kEventPlaceholderAsset), context),
        ...catalog.map((e) => () => _precacheOne(context, e)),
      ],
      onDone: () => done++,
    );
    if (kDebugMode) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      debugPrint('[EventLogoWarmup] precached $done images in ${ms}ms');
    }
  }

  static Future<void> _precacheOne(BuildContext context, EventDefinition e) async {
    if (!kIsWeb) {
      final local = e.localLogoPath;
      if (local != null && local.isNotEmpty) {
        final file = File(local);
        if (file.existsSync()) {
          await precacheImage(FileImage(file), context);
          return;
        }
      }
    }
    final url = e.logoUrl;
    if (url == null || url.isEmpty) return;
    try {
      await precacheImage(NetworkImage(url), context);
    } catch (_) {}
  }

  static Future<void> _runPool(
    List<Future<void> Function()> tasks, {
    void Function()? onDone,
  }) async {
    if (tasks.isEmpty) return;
    var index = 0;
    Future<void> worker() async {
      while (true) {
        final i = index;
        index++;
        if (i >= tasks.length) return;
        try {
          await tasks[i]();
        } catch (_) {}
        onDone?.call();
      }
    }
    final workers = List.generate(
      tasks.length < _maxConcurrent ? tasks.length : _maxConcurrent,
      (_) => worker(),
    );
    await Future.wait(workers);
  }
}
