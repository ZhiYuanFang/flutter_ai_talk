import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/invite_provider.dart';
import '../../theme/app_visual_tokens.dart';
import 'widgets/ucg_visual_widgets.dart';

/// UCG「我的」邀请码详情：用途说明 + 已邀请用户列表。
class UcgInviteDetailScreen extends ConsumerStatefulWidget {
  const UcgInviteDetailScreen({super.key});

  @override
  ConsumerState<UcgInviteDetailScreen> createState() =>
      _UcgInviteDetailScreenState();
}

class _UcgInviteDetailScreenState extends ConsumerState<UcgInviteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(inviteMineProvider);
      ref.invalidate(inviteInviteesProvider);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(inviteMineProvider);
    ref.invalidate(inviteInviteesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  void _copyCode(String code) {
    if (code.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: code.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('邀请码已复制')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).extension<AppVisualTokens>()?.onShell ??
        Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final mineAsync = ref.watch(inviteMineProvider);
    final inviteesAsync = ref.watch(inviteInviteesProvider);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return UcgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcgImmersiveHeader(
            title: '我的邀请码',
            subtitle: '分享给好友，助力开通预测等功能',
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
                        Text(
                          '邀请码',
                          style: TextStyle(
                            fontSize: 13,
                            color: fg.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        mineAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, __) => Text(
                            '加载失败，下拉重试',
                            style: TextStyle(color: fg.withValues(alpha: 0.65)),
                          ),
                          data: (mine) => Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  mine.code.isEmpty ? '—' : mine.code,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: fg,
                                  ),
                                ),
                              ),
                              if (mine.code.isNotEmpty)
                                IconButton(
                                  tooltip: '复制',
                                  onPressed: () => _copyCode(mine.code),
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    size: 20,
                                    color: primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '好友在「开通更多功能」中输入你的邀请码，'
                          '可为预测等事项永久 +1 条开通额度。'
                          '每成功邀请 1 位用户，你还可获得 100 原力积分。',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: fg.withValues(alpha: 0.72),
                          ),
                        ),
                        mineAsync.maybeWhen(
                          data: (mine) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '已成功邀请 ${mine.redeemedCount} 人',
                              style: TextStyle(
                                fontSize: 12,
                                color: fg.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '已邀请用户',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 10),
                  inviteesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (_, __) => UcgSurfaceCard(
                      child: Text(
                        '列表加载失败，下拉重试',
                        style: TextStyle(color: fg.withValues(alpha: 0.65)),
                      ),
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return const UcgEmptyState(
                          icon: Icons.group_outlined,
                          title: '还没有好友使用你的邀请码',
                          subtitle: '分享邀请码，一起开通更多预测事项',
                        );
                      }
                      return Column(
                        children: [
                          for (final item in list) ...[
                            UcgSurfaceCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.nickname.isEmpty
                                          ? '用户 ${item.wxId}'
                                          : item.nickname,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: fg,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.redeemedAt > 0
                                        ? fmt.format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              item.redeemedAt * 1000,
                                            ).toLocal(),
                                          )
                                        : '—',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: fg.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      );
                    },
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
