import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/toast_bus.dart';
import '../api/gateway_json.dart';
import 'event_catalog_store.dart';
import 'models.dart';
import 'trend_point_mapper.dart';
import 'trend_series_bucket.dart';
import 'repositories.dart' show TrendRange, TrendsRepository;

/// 事件目录：`GET /device/history/api/event/options`；序列：`GET /device/history/api/piece`。
class RemoteTrendsRepository implements TrendsRepository {
  RemoteTrendsRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(authorizedApiClientProvider);

  String? get _deviceNo => _ref.read(deviceNoNotifierProvider).asData?.value;

  void _toast(String m) => _ref.read(apiToastProvider.notifier).state = m;

  (int startSec, int endSec) _rangeBounds(TrendRange range) {
    final now = DateTime.now();
    final end = now.millisecondsSinceEpoch ~/ 1000;
    final start = switch (range) {
      TrendRange.today => DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000,
      TrendRange.week => now.subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
      TrendRange.month => now.subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
      TrendRange.quarter => now.subtract(const Duration(days: 90)).millisecondsSinceEpoch ~/ 1000,
    };
    return (start, end);
  }

  @override
  Future<List<TrendCatalogItem>> loadCatalog() async {
    try {
      final data = await _api.getEnvelope('/device/history/api/event/options');
      final list = envelopeListOrEmpty(data);
      final defs = parseEventOptionsList(list);
      return defs
          .map((d) => TrendCatalogItem(eventKey: d.id, title: d.name))
          .toList();
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return const [];
    }
  }

  @override
  Future<TrendSeries> loadSeries(String eventKey, TrendRange range) async {
    final dn = _deviceNo;
    if (dn == null || dn.isEmpty) {
      return TrendSeries(eventKey: eventKey, points: const []);
    }
    final eventId = int.tryParse(eventKey) ?? 0;
    if (eventId <= 0) {
      return TrendSeries(eventKey: eventKey, points: const []);
    }
    final bounds = _rangeBounds(range);
    try {
      final data = await _api.getEnvelope(
        '/device/history/api/piece',
        query: {
          'deviceNo': dn,
          'eventId': '$eventId',
          'startTime': '${bounds.$1}',
          'endTime': '${bounds.$2}',
        },
      );
      if (data == null) {
        return TrendSeries(eventKey: eventKey, points: const []);
      }
      final list = data['list'] as List<dynamic>? ?? const [];
      final pts = <TrendPoint>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final pt = trendPointFromPieceJson(e);
        if (pt != null) pts.add(pt);
      }
      pts.sort((a, b) => a.t.compareTo(b.t));
      final filled = normalizeTrendSeriesForRange(pts, range, bounds.$1, bounds.$2);
      return TrendSeries(eventKey: eventKey, points: filled);
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return TrendSeries(eventKey: eventKey, points: const []);
    }
  }
}
