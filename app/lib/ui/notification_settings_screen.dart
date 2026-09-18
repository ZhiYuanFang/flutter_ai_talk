import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_notification_preference_provider.dart';
import '../theme/app_color.dart';
import '../ucg/push/ucg_push_native.dart';
import 'widgets/settings_glass_panel.dart';

/// 消息通知说明与总开关（登录可进）。
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _scopeCopy = [
    '事件即将发生时的提醒（如喂养等预测临近）',
    '其它经同一推送通道送达的服务通知（与上方开关一并生效，不可分开关）',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bgStart = AppColor.pageBg(context);
    final bgEnd =
        Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;
    final prefAsync = ref.watch(appNotificationPreferenceProvider);
    final authAsync = ref.watch(osNotificationAuthProvider);
    final prefOn = prefAsync.asData?.value ?? true;
    final auth = authAsync.asData?.value;
    final osGranted = auth == OsNotificationAuth.granted;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('消息通知'),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsGlassPanel(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '接收消息通知',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    prefOn
                        ? (osGranted
                            ? '已开启'
                            : '应用已开启，但系统通知未授权')
                        : '已关闭，将不再注册推送',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.textSecondary(context),
                    ),
                  ),
                  value: prefOn,
                  onChanged: kIsWeb
                      ? null
                      : (v) {
                          unawaited(
                            ref
                                .read(
                                  appNotificationPreferenceProvider.notifier,
                                )
                                .setEnabled(v),
                          );
                        },
                ),
              ),
              const SizedBox(height: 12),
              SettingsGlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '开启后可收到',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final line in _scopeCopy) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '· ',
                              style: TextStyle(
                                color: AppColor.textSecondary(context),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: AppColor.textSecondary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!kIsWeb && prefOn && !osGranted) ...[
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
                    title: const Text('打开系统通知设置'),
                    subtitle: Text(
                      auth == OsNotificationAuth.permanentlyDenied
                          ? '需在系统设置中允许通知'
                          : '授权后即可接收提醒',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.textSecondary(context),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final ok = await ref
                          .read(osNotificationAuthProvider.notifier)
                          .requestOrOpenSettings();
                      if (ok && context.mounted) {
                        // 授权成功后偏好已为 On，resume/setEnabled 路径会 register。
                      }
                    },
                  ),
                ),
              ],
              if (kIsWeb) ...[
                const SizedBox(height: 12),
                Text(
                  '当前平台不支持系统消息通知。',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColor.textSecondary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
