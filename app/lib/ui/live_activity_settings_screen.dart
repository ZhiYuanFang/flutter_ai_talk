import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/app_push_registration_provider.dart';
import '../push/live_activity_registration_status.dart';
import '../theme/app_color.dart';
import 'widgets/settings_glass_panel.dart';

/// iOS 锁屏 Live Activity 注册显态与手动重试（登录可进）。
class LiveActivitySettingsScreen extends ConsumerStatefulWidget {
  const LiveActivitySettingsScreen({super.key});

  @override
  ConsumerState<LiveActivitySettingsScreen> createState() =>
      _LiveActivitySettingsScreenState();
}

class _LiveActivitySettingsScreenState
    extends ConsumerState<LiveActivitySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refresh());
    });
  }

  Future<void> _refresh() async {
    final la = ref.read(liveActivityRegistrationServiceProvider);
    await la.refreshSystemStatus();
  }

  Future<void> _onRetry() async {
    final la = ref.read(liveActivityRegistrationServiceProvider);
    await la.forceRetryPushToStart();
  }

  String _headline(LiveActivityRegistrationStatus s) {
    if (s.retrying) return '正在开通…';
    if (!s.pushToStartSupported) return '系统版本不支持';
    if (s.systemAuth == LiveActivitySystemAuth.disabled) {
      return '系统未允许锁屏实况';
    }
    if (s.isFullyEnabled) return '已开通';
    if (s.imminentPushToStartOk || s.timingPushToStartOk) {
      return '部分开通';
    }
    if (s.listening) return '等待系统 token / 未完成上报';
    return '未开通';
  }

  String _kindLine({
    required String label,
    required bool seen,
    required bool ok,
  }) {
    final seenText = seen ? '已见事件' : '未见事件';
    final okText = ok ? '已上报' : '未上报';
    return '$label：$seenText / $okText';
  }

  String _subtitle(LiveActivityRegistrationStatus s) {
    if (s.retrying) return '正在重新监听并上报 Push-to-Start';
    if (!s.pushToStartSupported) {
      return '需要 iOS 17.2 及以上';
    }
    if (s.systemAuth == LiveActivitySystemAuth.disabled) {
      return '请在系统设置中允许本 App 的实时活动';
    }
    if (s.isFullyEnabled) {
      return '即将发生与计时中的锁屏 token 均已上报';
    }
    return [
      _kindLine(
        label: '即将发生',
        seen: s.imminentPtsEventSeen,
        ok: s.imminentPushToStartOk,
      ),
      _kindLine(
        label: '计时中',
        seen: s.timingPtsEventSeen,
        ok: s.timingPushToStartOk,
      ),
    ].join('\n');
  }

  String? _formatAt(DateTime? at) {
    if (at == null) return null;
    final l = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} '
        '${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgStart = AppColor.pageBg(context);
    final bgEnd =
        Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;
    final la = ref.watch(liveActivityRegistrationServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('锁屏通知'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<LiveActivityRegistrationStatus>(
            valueListenable: la.status,
            builder: (context, s, _) {
              final err = s.lastError?.trim();
              final diag = s.diagnosticSummary;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SettingsGlassPanel(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '锁屏实时活动',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary(context),
                        ),
                      ),
                      subtitle: Text(
                        '${_headline(s)}\n${_subtitle(s)}',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColor.textSecondary(context),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: s.retrying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: s.retrying ? null : _onRetry,
                              child: Text(
                                s.isFullyEnabled ? '重新开通' : '开通',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SettingsGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '开启后可在锁屏看到',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '· 事件即将发生时的锁屏提醒\n'
                          '· 事件计时进行中的锁屏展示\n\n'
                          '「开通」表示本机已向服务端上报锁屏推送 token；'
                          '锁屏是否出现内容仍依赖服务端推送，与消息通知开关相互独立。\n'
                          '「已见事件」= 系统已下发 Push-to-Start；「已上报」= register 成功。',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColor.textSecondary(context),
                          ),
                        ),
                        if (s.imminentLastSuccessAt != null ||
                            s.timingLastSuccessAt != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            [
                              if (s.imminentLastSuccessAt != null)
                                '即将发生上次成功：${_formatAt(s.imminentLastSuccessAt)}',
                              if (s.timingLastSuccessAt != null)
                                '计时中上次成功：${_formatAt(s.timingLastSuccessAt)}',
                            ].join('\n'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColor.textSecondary(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (s.systemAuth == LiveActivitySystemAuth.disabled) ...[
                    const SizedBox(height: 12),
                    SettingsGlassPanel(
                      contentPadding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Icon(
                          Icons.settings_outlined,
                          color: scheme.primary,
                        ),
                        title: const Text('打开系统设置'),
                        subtitle: Text(
                          '需允许本 App 的实时活动 / Live Activities',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColor.textSecondary(context),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => openAppSettings(),
                      ),
                    ),
                  ],
                  if (err != null && err.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SettingsGlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '失败信息',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.error,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            err,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: scheme.error,
                            ),
                          ),
                          if (s.errorCategory !=
                              LiveActivityErrorCategory.none) ...[
                            const SizedBox(height: 4),
                            Text(
                              '类别：${s.errorCategoryCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColor.textSecondary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SettingsGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '诊断摘要（可长按复制）',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          diag,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontFamily: 'monospace',
                            color: AppColor.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
