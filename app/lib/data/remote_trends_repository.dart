import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/toast_bus.dart';
import '../api/gateway_json.dart';
import 'event_catalog_store.dart';
import 'models.dart';
import 'history_hourly_dual_day.dart';
import 'trend_point_mapper.dart';
import '../config/trends_date_range_store.dart';
import 'trend_series_bucket.dart';
import 'repositories.dart' show TrendsRepository;

/// 事件目录：`GET /device/history/api/event/options`；序列：`GET /device/history/api/piece`。
class RemoteTrendsRepository implements TrendsRepository {
  RemoteTrendsRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(authorizedApiClientProvider);

  String? get _deviceNo => _ref.read(deviceNoNotifierProvider).asData?.value;

  void _toast(String m) => _ref.showApiToastError(m);

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
  Future<TrendPieceBundle> loadPieceBundle(
    String eventKey,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dn = _deviceNo;
    if (dn == null || dn.isEmpty) {
      return TrendPieceBundle.empty(eventKey);
    }
    final eventId = int.tryParse(eventKey) ?? 0;
    if (eventId <= 0) {
      return TrendPieceBundle.empty(eventKey);
    }
    final start = TrendsDateRangeLogic.dateOnly(startDate);
    final end = TrendsDateRangeLogic.dateOnly(endDate);
    final bounds = TrendsDateRangeLogic.toUnixBounds(start, end);
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
        return TrendPieceBundle.empty(eventKey);
      }
      final list = data['list'] as List<dynamic>? ?? const [];
      final pts = <TrendPoint>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final pt = trendPointFromPieceJson(e);
        if (pt != null) pts.add(pt);
      }
      pts.sort((a, b) => a.t.compareTo(b.t));
      // 近 N 日图恒按日分桶（即使 raw 为空也补齐日期轴便于选柱）。
      final daily = fillTrendBucketsDaily(
        raw: pts,
        startSec: bounds.$1,
        endSec: bounds.$2,
      );
      return TrendPieceBundle(eventKey: eventKey, raw: pts, daily: daily);
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return TrendPieceBundle.empty(eventKey);
    }
  }

  @override
  Future<HourlyDualDaySeries> loadPieceHourlyDualDay(String eventKey) async {
    final dn = _deviceNo;
    if (dn == null || dn.isEmpty) {
      return HourlyDualDaySeries.empty();
    }
    final eventId = int.tryParse(eventKey) ?? 0;
    if (eventId <= 0) {
      return HourlyDualDaySeries.empty();
    }
    final bounds = hourlyDualDayPieceBounds();
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
        return HourlyDualDaySeries.empty();
      }
      final list = data['list'] as List<dynamic>? ?? const [];
      final rows = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) rows.add(e);
      }
      return hourlyDualDayFromPieceRecords(rows, eventKey);
    } on ApiBusinessException catch (e) {
      _toast(e.message);
      return HourlyDualDaySeries.empty();
    }
  }
}
