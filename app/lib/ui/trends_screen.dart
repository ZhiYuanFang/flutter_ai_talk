import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/repositories.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  List<TrendCatalogItem> _catalog = const [];
  TrendRange _range = TrendRange.today;
  final Map<String, TrendSeries> _cache = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(trendsRepositoryProvider);
    final c = await repo.loadCatalog();
    setState(() => _catalog = c);
    await _loadAllSeries();
  }

  Future<void> _loadAllSeries() async {
    final repo = ref.read(trendsRepositoryProvider);
    _cache.clear();
    for (final item in _catalog) {
      final s = await repo.loadSeries(item.eventKey, _range);
      _cache[item.eventKey] = s;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final needLoginMask = !ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    return Scaffold(
      appBar: AppBar(
        title: const Text('趋势中心'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<TrendRange>(
                segments: const [
                  ButtonSegment(value: TrendRange.today, label: Text('今日')),
                  ButtonSegment(value: TrendRange.week, label: Text('周')),
                  ButtonSegment(value: TrendRange.month, label: Text('月')),
                  ButtonSegment(value: TrendRange.quarter, label: Text('季')),
                ],
                selected: {_range},
                onSelectionChanged: (s) async {
                  setState(() => _range = s.first);
                  await _loadAllSeries();
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _catalog.length,
              itemBuilder: (context, i) {
                final item = _catalog[i];
                final series = _cache[item.eventKey];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _TrendChart(series: series, range: _range),
                              if (needLoginMask)
                                ColoredBox(
                                  color: Colors.black45,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '请登录',
                                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton(
                                          onPressed: () => context.push('/login'),
                                          child: const Text('请登录'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.series, required this.range});

  final TrendSeries? series;
  final TrendRange range;

  static final _dateFmt = DateFormat('MM-dd');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final pts = series?.points ?? const <TrendPoint>[];
    if (pts.isEmpty) {
      final emptyHint = range == TrendRange.today ? '今日暂无数据' : '当前时间范围暂无数据';
      return Center(child: Text(emptyHint));
    }
    final spots = List<FlSpot>.generate(
      pts.length,
      (i) => FlSpot(i.toDouble(), pts[i].value),
    );
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;
    final minY = 0.0;
    final maxVal = pts.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.15).clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
          topTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if ((value - i).abs() > 1e-6) return const SizedBox.shrink();
                if (i < 0 || i >= pts.length) return const SizedBox.shrink();
                if (pts.length > 6) {
                  final mid = pts.length ~/ 2;
                  if (i != 0 && i != mid && i != pts.length - 1) {
                    return const SizedBox.shrink();
                  }
                }
                final d = pts[i].t.toLocal();
                final label = range == TrendRange.today ? _timeFmt.format(d) : _dateFmt.format(d);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Text(
                  value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black26),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1),
          getDrawingVerticalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: true),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
