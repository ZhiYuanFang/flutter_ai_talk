import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/baby_age.dart';
import '../../data/event_branding.dart';
import '../../data/event_definition.dart';
import '../../data/event_next_predictor.dart';
import '../../home_widget/format_widget_relative_time.dart';
import '../../home_widget/home_widget_constants.dart';
import '../../home_widget/home_widget_payload.dart';
import '../../home_widget/home_widget_sync.dart';
import '../../home_widget/widget_row_builder.dart';
import '../../home_widget/widget_row_enrich.dart';
import '../../home_widget/widget_theme_visual.dart';
import '../../home_widget/widget_tip_cache.dart';
import '../../providers/event_catalog_notifier.dart';
import '../../providers/forecast_toggle_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_baby.dart';
import '../../theme/app_color.dart';
import '../event_logo.dart';
import '../startup_branding.dart';

/// Flutter 对标桌面 large：头 / tip / hero(logo) / 横向 recent(logo)。
class HomeWidgetLargePreview extends ConsumerStatefulWidget {
  const HomeWidgetLargePreview({super.key});

  @override
  ConsumerState<HomeWidgetLargePreview> createState() =>
      _HomeWidgetLargePreviewState();
}

class _PreviewBundle {
  const _PreviewBundle({
    required this.header,
    required this.visual,
    this.tip,
    this.hero,
    this.recent = const [],
    this.emptyMessage,
  });

  final String header;
  final HomeWidgetVisualPayload visual;
  final HomeWidgetTipPayload? tip;
  final HomeWidgetRowPayload? hero;
  final List<HomeWidgetRowPayload> recent;
  final String? emptyMessage;
}

class _HomeWidgetLargePreviewState
    extends ConsumerState<HomeWidgetLargePreview> {
  Object? _sig;
  Future<_PreviewBundle>? _future;

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(sessionProvider).isLoggedIn;
    final babyAsync = ref.watch(settingsBabyProvider);
    final visual = buildHomeWidgetVisualFromRef(ref);
    final inputs = resolveWidgetPredictionInputs(ref);
    final disabled =
        ref.watch(forecastDisabledIdsProvider).asData?.value ?? const <String>{};
    final catalog = ref.watch(eventCatalogProvider).items;
    final now = DateTime.now();

    return babyAsync.when(
      loading: () => _frame(
        visual: visual,
        child: _statusText(visual, HomeWidgetConstants.loadingMessage),
      ),
      error: (_, __) => _frame(
        visual: visual,
        child: _statusText(visual, HomeWidgetConstants.emptyMessage),
      ),
      data: (baby) {
        if (!loggedIn) {
          return _frame(
            visual: visual,
            child: _statusText(visual, HomeWidgetConstants.emptyMessage),
          );
        }
        final enabledActive = {
          for (final k in inputs.activeEventKeys)
            if (!disabled.contains(k)) k,
        };
        final preds = predictAllUpcoming(
          history: inputs.history,
          catalog: inputs.catalog,
          now: now,
          birthDate: baby.birthDate,
          activeEventKeys: enabledActive,
        );
        final header = formatWidgetHeaderLine(baby, now);
        final sig = Object.hash(
          header,
          visual.shellGradientStart,
          inputs.history.length,
          preds.map((p) => '${p.eventId}:${p.nextAt.millisecondsSinceEpoch}').join('|'),
          disabled.length,
          catalog.length,
        );
        if (_sig != sig || _future == null) {
          _sig = sig;
          _future = _loadBundle(
            header: header,
            visual: visual,
            preds: preds,
            historyEmpty: inputs.history.isEmpty,
            catalog: catalog,
            now: now,
          );
        }
        return FutureBuilder<_PreviewBundle>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return _frame(
                visual: visual,
                child: _statusText(visual, HomeWidgetConstants.loadingMessage),
              );
            }
            final b = snap.data!;
            if (b.emptyMessage != null) {
              return _frame(
                visual: b.visual,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(b.visual, b.header),
                    const SizedBox(height: 16),
                    _statusText(b.visual, b.emptyMessage!),
                  ],
                ),
              );
            }
            return _frame(
              visual: b.visual,
              child: _LargeChrome(
                visual: b.visual,
                header: b.header,
                tip: b.tip,
                hero: b.hero,
                recent: b.recent,
                catalog: catalog,
                now: now,
              ),
            );
          },
        );
      },
    );
  }

  Future<_PreviewBundle> _loadBundle({
    required String header,
    required HomeWidgetVisualPayload visual,
    required List<EventNextPrediction> preds,
    required bool historyEmpty,
    required List<EventDefinition> catalog,
    required DateTime now,
  }) async {
    final tip = await loadWidgetTipSnapshotFromPrefs(now: now);
    var hero = buildWidgetHero(predictions: preds, now: now);
    var recent = buildWidgetRecentLast(predictions: preds, count: 3);
    // native large：recent 排除当前 hero
    if (hero != null) {
      recent = recent.where((r) => r.eventId != hero!.eventId).take(3).toList();
      hero = await enrichWidgetRow(hero, catalog);
    }
    if (recent.isNotEmpty) {
      recent = await enrichWidgetRows(recent, catalog);
    }
    if (hero == null && recent.isEmpty) {
      return _PreviewBundle(
        header: header,
        visual: visual,
        tip: tip,
        emptyMessage: historyEmpty
            ? HomeWidgetConstants.emptyMessage
            : HomeWidgetConstants.noPredictionMessage,
      );
    }
    return _PreviewBundle(
      header: header,
      visual: visual,
      tip: tip,
      hero: hero,
      recent: recent,
    );
  }

  Widget _frame({
    required HomeWidgetVisualPayload visual,
    required Widget child,
  }) {
    final radius = visual.cornerRadius.toDouble();
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _hex(visual.shellGradientStart),
              _hex(visual.shellGradientEnd),
            ],
          ),
          border: Border.all(
            color: _hex(visual.borderColor).withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.textPrimary(context).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ColoredBox(
            color: _hex(visual.glassFillTop).withValues(alpha: 0.55),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(HomeWidgetVisualPayload visual, String line) {
    return Row(
      children: [
        Expanded(
          child: Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _hex(visual.textPrimary),
            ),
          ),
        ),
        Image.asset(
          kStartupIconAsset,
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => Icon(
            Icons.apps_rounded,
            size: 22,
            color: _hex(visual.textPrimary).withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _statusText(HomeWidgetVisualPayload visual, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _hex(visual.textSecondary),
          fontSize: 14,
        ),
      ),
    );
  }
}

/// 对齐 `widget_pangbao_large` 信息架构。
class _LargeChrome extends StatelessWidget {
  const _LargeChrome({
    required this.visual,
    required this.header,
    required this.catalog,
    required this.now,
    this.tip,
    this.hero,
    this.recent = const [],
  });

  final HomeWidgetVisualPayload visual;
  final String header;
  final HomeWidgetTipPayload? tip;
  final HomeWidgetRowPayload? hero;
  final List<HomeWidgetRowPayload> recent;
  final List<EventDefinition> catalog;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                header,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _hex(visual.textPrimary),
                ),
              ),
            ),
            Image.asset(
              kStartupIconAsset,
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
        ),
        if (tip != null && tip!.text.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '喂养小贴士',
            style: TextStyle(
              fontSize: 10,
              color: _hex(visual.textSecondary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip!.text.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: _hex(visual.textPrimary),
            ),
          ),
        ],
        if (hero != null) ...[
          const SizedBox(height: 10),
          Text(
            '预测即将发生',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _hex(visual.textSecondary),
            ),
          ),
          const SizedBox(height: 6),
          _HeroRow(
            visual: visual,
            row: hero!,
            catalog: catalog,
            now: now,
          ),
        ],
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '后续留意·上次记录',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _hex(visual.textPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: i < recent.length
                      ? _RecentCell(
                          visual: visual,
                          row: recent[i],
                          catalog: catalog,
                          now: now,
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeroRow extends StatelessWidget {
  const _HeroRow({
    required this.visual,
    required this.row,
    required this.catalog,
    required this.now,
  });

  final HomeWidgetVisualPayload visual;
  final HomeWidgetRowPayload row;
  final List<EventDefinition> catalog;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final next = row.nextAt != null ? DateTime.tryParse(row.nextAt!) : null;
    final overdue = row.status == 'overdue';
    final sub = next == null
        ? ''
        : formatWidgetPredictSubtitle(next, now, overdue: overdue);
    final def = lookupEventById(catalog, row.eventId);
    return Row(
      children: [
        _EventLogoTile(def: def, logoFile: row.logoFile, size: 52),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _hex(visual.textPrimary),
                ),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _hex(visual.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 桌面有「跳过」；预览仅展示文案，不可点
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            '跳过',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentCell extends StatelessWidget {
  const _RecentCell({
    required this.visual,
    required this.row,
    required this.catalog,
    required this.now,
  });

  final HomeWidgetVisualPayload visual;
  final HomeWidgetRowPayload row;
  final List<EventDefinition> catalog;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final last = row.lastAt != null ? DateTime.tryParse(row.lastAt!) : null;
    final sub = formatWidgetLastAt(last, now);
    final def = lookupEventById(catalog, row.eventId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _EventLogoTile(def: def, logoFile: row.logoFile, size: 40),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _hex(visual.textPrimary),
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: _hex(visual.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventLogoTile extends StatelessWidget {
  const _EventLogoTile({
    required this.def,
    required this.size,
    this.logoFile,
  });

  final EventDefinition? def;
  final String? logoFile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    Widget image;
    final path = logoFile?.trim();
    if (!kIsWeb && path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        image = Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => EventLogo(definition: def, size: size),
        );
      } else {
        image = EventLogo(definition: def, size: size);
      }
    } else {
      image = EventLogo(definition: def, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: Colors.white.withValues(alpha: 0.55),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(3),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
    );
  }
}

Color _hex(String hex) {
  var s = hex.replaceFirst('#', '');
  if (s.length == 8) {
    final a = int.tryParse(s.substring(0, 2), radix: 16) ?? 0xFF;
    final rgb = int.tryParse(s.substring(2), radix: 16) ?? 0x5BA3E8;
    return Color((a << 24) | rgb);
  }
  final v = int.tryParse(s, radix: 16) ?? 0x5BA3E8;
  return Color(0xFF000000 | v);
}
