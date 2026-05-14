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
  String? _selectedKey;
  TrendSeries? _series;
  var _loadingSeries = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final repo = ref.read(trendsRepositoryProvider);
    final c = await repo.loadCatalog();
    if (!mounted) return;
    setState(() {
      _catalog = c;
      if (_selectedKey == null && c.isNotEmpty) {
        _selectedKey = c.first.eventKey;
      } else if (_selectedKey != null && !c.any((e) => e.eventKey == _selectedKey)) {
        _selectedKey = c.isEmpty ? null : c.first.eventKey;
      }
    });
    await _loadSeriesForSelection();
  }

  Future<void> _loadSeriesForSelection() async {
    final key = _selectedKey;
    if (key == null) {
      if (mounted) setState(() => _series = null);
      return;
    }
    setState(() => _loadingSeries = true);
    final repo = ref.read(trendsRepositoryProvider);
    final s = await repo.loadSeries(key, _range);
    if (!mounted) return;
    setState(() {
      _series = s;
      _loadingSeries = false;
    });
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_catalog.isEmpty)
                  Text(
                    '暂无事件目录，请稍后再试或检查网络',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedKey,
                      hint: const Text('选择事件'),
                      items: [
                        for (final e in _catalog)
                          DropdownMenuItem(value: e.eventKey, child: Text(e.title)),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedKey = v);
                        await _loadSeriesForSelection();
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                SingleChildScrollView(
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
                      await _loadSeriesForSelection();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingSeries
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        _TrendLineAndBar(series: _series, range: _range),
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
          ),
        ],
      ),
    );
  }
}

class _TrendLineAndBar extends StatelessWidget {
  const _TrendLineAndBar({required this.series, required this.range});

  final TrendSeries? series;
  final TrendRange range;

  static final _dateFmt = DateFormat('MM-dd');
  static final _timeFmt = DateFormat('HH:mm');

  static String _fmtYAxis(double value) {
    if (value == 0) return '0';
    if (value.abs() < 1) return value.toStringAsFixed(2);
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  SideTitles _bottomSideTitles(List<TrendPoint> pts) {
    return SideTitles(
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
          child: Text(label, style: const TextStyle(fontSize: 10)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pts = series?.points ?? const <TrendPoint>[];
    if (pts.isEmpty) {
      final emptyHint = range == TrendRange.today ? '今日暂无数据' : '当前时间范围暂无数据';
      return Center(child: Text(emptyHint, style: Theme.of(context).textTheme.bodyLarge));
    }
    final spots = List<FlSpot>.generate(pts.length, (i) => FlSpot(i.toDouble(), pts[i].value));
    final barGroups = List<BarChartGroupData>.generate(
      pts.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pts[i].value,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;
    final minY = 0.0;
    final maxVal = pts.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.15).clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '纵轴：计时类为小时(h)，计数类为次数',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text('趋势', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Expanded(
          flex: 5,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                topTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                bottomTitles: AxisTitles(sideTitles: _bottomSideTitles(pts)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        _TrendLineAndBar._fmtYAxis(value),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26)),
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
          ),
        ),
        const SizedBox(height: 12),
        Text('量柱', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Expanded(
          flex: 4,
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 4,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                topTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                bottomTitles: AxisTitles(sideTitles: _bottomSideTitles(pts)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        _TrendLineAndBar._fmtYAxis(value),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26)),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
