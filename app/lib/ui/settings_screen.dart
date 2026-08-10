import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../config/event_media_local_store.dart';
import '../data/models.dart';
import '../data/repositories.dart' show readPackageVersion;
import '../home_widget/home_widget_payload.dart';
import '../providers/repositories.dart' show versionRepositoryProvider;
import '../providers/settings_baby.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
import '../theme/app_color.dart';
import 'account_management_sheet.dart';
import 'version_prompt.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/baby_avatar.dart';
import 'widgets/settings_glass_panel.dart';
import 'home_widget_settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _currentVersion;
  var _checking = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final version = await readPackageVersion();
      if (mounted) setState(() => _currentVersion = version);
    } catch (_) {}
  }

  Future<void> _onCheckUpdateTap() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final version = _currentVersion ?? await readPackageVersion();
      if (!mounted) return;
      if (_currentVersion == null) {
        setState(() => _currentVersion = version);
      }
      final info = await ref.read(versionRepositoryProvider).checkForUpdate(version);
      if (!mounted) return;
      if (info != null) {
        await maybeShowVersionPrompt(
          context: context,
          repo: ref.read(versionRepositoryProvider),
          currentVersion: version,
        );
      } else {
        ref.showApiToast('已是最新版本', tone: AppToastTone.success);
      }
    } catch (_) {
      if (mounted) {
        ref.showApiToast('检查失败，请稍后重试', tone: AppToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final babyAsync = ref.watch(settingsBabyProvider);
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final scheme = Theme.of(context).colorScheme;

    // 背景渐变：页底原子 + primaryContainer
    final bgStart = AppColor.pageBg(context);
    final bgEnd = Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('设置中心'),
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
              if (!loggedIn)
                _buildGlassTile(
                  context,
                  leading: Icons.child_care_outlined,
                  title: '宝宝信息',
                  subtitle: '登录后查看与编辑',
                  onTap: () => context.push('/login'),
                )
              else
                babyAsync.when(
                  data: (baby) {
                    if (baby.id.isEmpty) {
                      return _buildGlassTile(
                        context,
                        leading: Icons.add_link,
                        title: '绑定宝宝',
                        subtitle: '尚未绑定宝宝ID，点击前往绑定',
                        onTap: () => context.push('/settings/bind-baby'),
                      );
                    }
                    return _BabyProfileReadonlyCard(
                      key: ValueKey('${baby.id}-${baby.nickname}-${baby.sex}-${ HomeWidgetRowPayload.isoDateUtc(baby.birthDate)}'),
                      baby: baby,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('加载失败：$e'),
                ),
              const SizedBox(height: 12),
              // 语音识别模块已隐藏；陪伴页仍可读持久化/默认引擎
              // 顺序：反馈(仅登录) → 小组件 → 账号/清缓存 → 隐私 → 检查更新(最底)
              if (loggedIn) ...[
                _buildGlassTile(
                  context,
                  leading: Icons.feedback_outlined,
                  title: '反馈建议',
                  onTap: () => context.push('/settings/feedback'),
                ),
                const SizedBox(height: 12),
              ],
              // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && loggedIn)
              //   const SettingsGlassPanel(
              //     child: Padding(
              //       padding: EdgeInsets.all(14),
              //       child: HomeWidgetSettingsSection(),
              //     ),
              //   ),
              // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && loggedIn)
              //   const SizedBox(height: 12),
              if (loggedIn) ...[
                _buildGlassTile(
                  context,
                  leading: Icons.manage_accounts,
                  title: '账号管理',
                  onTap: () => showAccountManagementSheet(context, ref),
                ),
                const SizedBox(height: 12),
                _buildGlassTile(
                  context,
                  leading: Icons.photo_library_outlined,
                  title: '清除历史媒体缓存',
                  // subtitle: '删除本地复制的历史事件图片与视频',
                  onTap: () => _confirmClearHistoryMediaCache(context),
                ),
                const SizedBox(height: 12),
              ],
              _buildGlassTile(
                context,
                leading: Icons.policy,
                title: '隐私政策',
                onTap: () => context.push(
                  Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
                ),
              ),
              const SizedBox(height: 12),
              _buildGlassTile(
                context,
                leading: Icons.system_update_outlined,
                title: '检查更新',
                subtitle: _currentVersion == null ? '加载中…' : '当前版本 $_currentVersion',
                checking: _checking,
                onTap: _onCheckUpdateTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearHistoryMediaCache(BuildContext context) async {
    final go = await showGlassConfirmDialog(
          context,
          title: '清除历史媒体缓存？',
          message: '将删除本机复制的历史事件图片与视频，不影响已同步到广场的内容。',
          confirmLabel: '清除',
        ) ??
        false;
    if (!go || !context.mounted) return;
    await EventMediaLocalStore.clearAll();
    if (!context.mounted) return;
    ref.showApiToast('已清除历史媒体缓存', tone: AppToastTone.success);
  }

  Widget _buildGlassTile(
    BuildContext context, {
    required IconData leading,
    required String title,
    String? subtitle,
    bool checking = false,
    required VoidCallback onTap,
  }) {
    final onShell = AppColor.textPrimary(context);
    final primary = Theme.of(context).colorScheme.primary;

    return SettingsGlassPanel(
      contentPadding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(leading, color: primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: onShell),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: onShell.withValues(alpha: 0.7)))
            : null,
        trailing: checking
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
              )
            : Icon(Icons.chevron_right, size: 20, color: onShell.withValues(alpha: 0.5)),
        onTap: checking ? null : onTap,
      ),
    );
  }
}

class _BabyProfileReadonlyCard extends ConsumerWidget {
  const _BabyProfileReadonlyCard({super.key, required this.baby});

  final BabyProfile baby;

  static String _sexLabel(BabySex s) => switch (s) {
        BabySex.male => '男',
        BabySex.female => '女',
        BabySex.unknown => '未填',
      };

  static Widget _readonlyRow(BuildContext context, String label, String value) {
    final onShell = AppColor.textPrimary(context);
    final secondary = onShell.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: TextStyle(color: secondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, height: 1.3, color: onShell),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthStr = HomeWidgetRowPayload.isoDateUtc(baby.birthDate);
    final onShell = AppColor.textPrimary(context);

    return SettingsGlassPanel(
      contentPadding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/settings/baby'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 10),
              //   child: Row(
              //     children: [
              //       Text(
              //         '宝宝信息',
              //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
              //               fontWeight: FontWeight.bold,
              //               color: onShell,
              //             ),
              //       ),
              //       const Spacer(),
              //       Text(
              //         '编辑',
              //         style: TextStyle(
              //           color: Theme.of(context).colorScheme.primary,
              //           fontWeight: FontWeight.w500,
              //           fontSize: 13,
              //         ),
              //       ),
              //       Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary, size: 16),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 12),
              // 只读卡同步展示本地头像
              Center(
                child: BabyAvatar(
                  babyId: baby.id,
                  sex: baby.sex,
                  radius: 32,
                ),
              ),
              const SizedBox(height: 10),
              _readonlyRow(
                context,
                '昵称',
                baby.nickname.isEmpty ? '待设置' : baby.nickname,
              ),
              _readonlyRow(context, '性别', _sexLabel(baby.sex)),
              _readonlyRow(context, '生日', birthStr),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ID：${baby.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onShell.withValues(alpha: 0.5),
                            ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: baby.id));
                        if (context.mounted) {
                          ref.showApiToast('ID 已复制');
                        }
                      },
                      icon: Icon(Icons.copy_rounded, size: 14, color: onShell.withValues(alpha: 0.5)),
                      tooltip: '复制 ID',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
