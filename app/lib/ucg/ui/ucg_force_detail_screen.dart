import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/ucg_force_provider.dart';
import '../../theme/app_visual_tokens.dart';
import '../data/ucg_force_models.dart';
import '../providers/ucg_providers.dart';
import 'widgets/ucg_force_tier_icon.dart';
import 'widgets/ucg_visual_widgets.dart';

/// UCG 原力积分详情：当前分、流水、距升级、获取方式。
class UcgForceDetailScreen extends ConsumerStatefulWidget {
  const UcgForceDetailScreen({
    super.key,
    required this.initialForceValue,
    this.initialForceTier,
  });

  final int initialForceValue;
  final String? initialForceTier;

  @override
  ConsumerState<UcgForceDetailScreen> createState() =>
      _UcgForceDetailScreenState();
}

class _UcgForceDetailScreenState extends ConsumerState<UcgForceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(ucgForceLedgerProvider);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(ucgForceLedgerProvider);
    ref.invalidate(ucgMyProfileProvider);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final ledgerAsync = ref.watch(ucgForceLedgerProvider);
    final fmt = DateFormat('MM-dd HH:mm');

    final forceValue = ledgerAsync.maybeWhen(
      data: (page) => page.forceValue,
      orElse: () => widget.initialForceValue,
    );
    final tier = UcgForceTierIcon.tierFromValue(
      forceValue,
      apiTier: widget.initialForceTier,
    );
    final nextLabel = UcgForceTierIcon.nextTierLabel(forceValue);
    final gap = UcgForceTierIcon.pointsToNextTier(forceValue);

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: '原力积分',
            subtitle: '参与辩论与邀请获客，提升社区等级',
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: fg.withValues(alpha: 0.75),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  UcgSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            UcgForceTierIcon(
                              forceValue: forceValue,
                              forceTier: tier,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$forceValue 分',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: fg,
                                    ),
                                  ),
                                  Text(
                                    tier != null
                                        ? '当前档位：${UcgForceTierIcon.tierLabel(tier)}'
                                        : '尚未达到青铜档（500 分）',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: fg.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (nextLabel != null && gap != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '距离 $nextLabel 还需 $gap 分',
                            style: TextStyle(
                              fontSize: 13,
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else if (forceValue >= 2500) ...[
                          const SizedBox(height: 12),
                          Text(
                            '已达最高档位',
                            style: TextStyle(
                              fontSize: 13,
                              color: fg.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  UcgSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '如何获得积分',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _EarnMethodRow(
                          icon: Icons.forum_outlined,
                          title: '参与辩论',
                          subtitle: '在自己发起的辩论帖中自投一票 +1 分',
                          fg: fg,
                        ),
                        const SizedBox(height: 8),
                        _EarnMethodRow(
                          icon: Icons.person_add_alt_1_outlined,
                          title: '邀请获客',
                          subtitle: '好友使用你的邀请码成功开通 +100 分',
                          fg: fg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '积分流水',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ledgerAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (_, __) => UcgSurfaceCard(
                      child: Text(
                        '流水加载失败，下拉重试',
                        style: TextStyle(color: fg.withValues(alpha: 0.65)),
                      ),
                    ),
                    data: (page) => _LedgerList(page: page, fmt: fmt, fg: fg),
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

class _EarnMethodRow extends StatelessWidget {
  const _EarnMethodRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fg,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: fg.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: fg.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerList extends StatelessWidget {
  const _LedgerList({
    required this.page,
    required this.fmt,
    required this.fg,
  });

  final UcgForceLedgerPage page;
  final DateFormat fmt;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    if (page.list.isEmpty) {
      return const UcgEmptyState(
        icon: Icons.receipt_long_outlined,
        title: '暂无积分流水',
        subtitle: '参与辩论或邀请好友后这里会显示记录',
      );
    }
    return Column(
      children: [
        for (final item in page.list) ...[
          UcgSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.reasonLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                      if (item.createdAt > 0)
                        Text(
                          fmt.format(
                            DateTime.fromMillisecondsSinceEpoch(
                              item.createdAt * 1000,
                            ).toLocal(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: fg.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  item.delta >= 0 ? '+${item.delta}' : '${item.delta}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: item.delta >= 0
                        ? Theme.of(context).colorScheme.primary
                        : fg.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
