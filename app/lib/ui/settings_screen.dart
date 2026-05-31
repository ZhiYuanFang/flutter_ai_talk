import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../data/models.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../providers/session_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/sign_in_channel_provider.dart';
import '../providers/toast_bus.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_visual_tokens.dart';
import '../theme/custom_background_persist.dart';
import '../theme/theme_preset.dart';
import 'home_history_edit_glass_panel.dart';
import 'recording_diagnostics_tile.dart';
import 'widgets/app_glass_overlay.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final babyAsync = ref.watch(settingsBabyProvider);
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final scheme = Theme.of(context).colorScheme;
    final tokens = visualTokensOf(context);

    // 背景渐变：随主色调变化
    final bgStart = tokens?.shellColor ?? scheme.surface;
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
                      key: ValueKey('${baby.id}-${baby.nickname}-${baby.sex}-${baby.birthDate.toIso8601String()}'),
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
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
                const VoiceInputSettingsGroup(),
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
                leading: Icons.swap_horiz,
                title: '切换账号',
                onTap: () async {
                  final ok = await showGlassConfirmDialog(
                        context,
                        title: '切换账号',
                    message: '将清除本地会话、宝宝ID缓存并返回登录页。',
                      ) ??
                      false;
                  if (!ok || !context.mounted) return;
                  await ref.read(authRepositoryProvider).signOut();
                  await ref.read(sessionProvider).signOut();
                  await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
                  await ref.read(signInChannelProvider.notifier).clear();
                  await ref.read(feedRepositoryProvider).clearCache();
                  if (context.mounted) context.go('/home');
                },
              ),
              const SizedBox(height: 12),
              _buildGlassTile(
                context,
                leading: Icons.delete_forever,
                title: '注销账户',
                onTap: () => _confirmDeregister(context, ref),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  '主题',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: tokens?.onShell ?? scheme.onSurface,
                  ),
                ),
              ),
              const _ThemePresetSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTile(
    BuildContext context, {
    required IconData leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final tokens = visualTokensOf(context);
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return _SettingsGlassPanel(
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
        trailing: Icon(Icons.chevron_right, size: 20, color: onShell.withValues(alpha: 0.5)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmDeregister(BuildContext context, WidgetRef ref) async {
    final step1 = await showGlassConfirmDialog(
          context,
          title: '注销账户',
          message: '第一步：确认你了解此操作的风险。该操作不可撤销，你的所有记录将被永久删除。',
          confirmLabel: '继续',
        ) ??
        false;
    if (!step1 || !context.mounted) return;

    final step2 = await showGlassTextConfirmDialog(
          context,
          title: '注销确认',
          message: '第二步：请输入“确定注销”以继续申请。',
          expectedText: '确定注销',
          confirmLabel: '确认注销',
        ) ??
        false;
    if (!step2 || !context.mounted) return;

    try {
      // 1. 调用后端注销接口
      await ref.read(authRepositoryProvider).deactivateAccount();

      // 2. 接口成功后，清理本地所有状态
      await ref.read(sessionProvider).signOut();
      await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
      await ref.read(signInChannelProvider.notifier).clear();
      await ref.read(feedRepositoryProvider).clearCache();

      if (context.mounted) {
        context.go('/home');
        ref.showApiToastError('注销成功'); // 使用 Toast 提示
      }
    } catch (e) {
      if (context.mounted) {
        ref.showApiToastError('注销失败：$e');
      }
    }
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
    final tokens = visualTokensOf(context);
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
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
    final birthStr = baby.birthDate.toIso8601String().split('T').first;
    final tokens = visualTokensOf(context);
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;

    return _SettingsGlassPanel(
      contentPadding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/settings/baby'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Text(
                      '宝宝信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: onShell,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '编辑',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary, size: 16),
                  ],
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

class _ThemePresetSection extends ConsumerWidget {
  const _ThemePresetSection();

  static const _classicSwatch = Color(0xFFF5F5F5);

  Future<void> _applyPreset(WidgetRef ref, ThemePreset preset, Color seed) async {
    ref.read(themePresetProvider.notifier).state = preset;
    ref.read(customBackgroundProvider.notifier).state = seed;
    await persistThemePreferences(seed: seed, preset: preset);
  }

  Future<void> _clearToClassic(WidgetRef ref) async {
    ref.read(themePresetProvider.notifier).state = null;
    ref.read(customBackgroundProvider.notifier).state = null;
    await clearThemePreferences();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePreset = ref.watch(themePresetProvider);
    final customBg = ref.watch(customBackgroundProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetSwatch(
              label: '经典',
              color: _classicSwatch,
              selected: activePreset == ThemePreset.classicLight ||
                  (activePreset == null && customBg == null),
              onTap: () => _clearToClassic(ref),
            ),
            _PresetSwatch(
              label: '夜空',
              color: kNightSkyShell,
              selected: activePreset == ThemePreset.nightSky,
              onTap: () => _applyPreset(ref, ThemePreset.nightSky, kNightSkyShell),
            ),
            for (final preset in [
              ThemePreset.softBlue,
              ThemePreset.softPink,
              ThemePreset.softGreen,
              ThemePreset.softYellow,
              ThemePreset.softGrey,
              ThemePreset.softPurple,
            ])
              _PresetSwatch(
                color: _swatchColorForPreset(preset),
                selected: activePreset == preset,
                onTap: () {
                  final c = _swatchColorForPreset(preset);
                  _applyPreset(ref, preset, c);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.palette_outlined),
          title: const Text('更多颜色'),
          subtitle: const Text('自定义色将清除上方预设选中'),
          onTap: () async {
            final picked = await showGlassDialog<Color>(
              context: context,
              maxWidth: 360,
              contentBuilder: (ctx) {
                final glassText = historyEditGlassTextColor(ctx);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '选择背景色',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: glassText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MaterialColorPicker(
                      onPicked: (c) => Navigator.pop(ctx, c),
                    ),
                  ],
                );
              },
            );
            if (picked == null) return;
            ref.read(themePresetProvider.notifier).state = null;
            ref.read(customBackgroundProvider.notifier).state = picked;
            await persistThemePreferences(seed: picked, preset: null);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restart_alt),
          title: const Text('清除自定义背景'),
          subtitle: const Text('恢复经典浅色默认'),
          onTap: () => _clearToClassic(ref),
        ),
      ],
    );
  }

  static Color _swatchColorForPreset(ThemePreset preset) {
    return switch (preset) {
      ThemePreset.softBlue => kThemeSoftSwatchColors[0],
      ThemePreset.softPink => kThemeSoftSwatchColors[1],
      ThemePreset.softGreen => kThemeSoftSwatchColors[2],
      ThemePreset.softYellow => kThemeSoftSwatchColors[3],
      ThemePreset.softGrey => kThemeSoftSwatchColors[4],
      ThemePreset.softPurple => kThemeSoftSwatchColors[5],
      _ => kThemeSoftSwatchColors[0],
    };
  }
}

class _SettingsGlassPanel extends StatelessWidget {
  const _SettingsGlassPanel({
    required this.child,
    this.contentPadding,
  });

  final Widget child;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = visualTokensOf(context);
    final isDark = tokens?.isDarkShell ?? (theme.brightness == Brightness.dark);

    final base = tokens?.surfaceColor ?? scheme.surface;
    final top = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.06 : 0.20),
      base,
    );
    final bottom = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.16 : 0.10),
      base,
    );

    final borderColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.22 : 0.55),
      scheme.outline.withValues(alpha: isDark ? 0.10 : 0.08),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [top, bottom],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: contentPadding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : (color.computeLuminance() < 0.15 ? Colors.white38 : Colors.black26);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: selected ? 2.5 : 1),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() < 0.4 ? Colors.white : Colors.black87,
                    size: 20,
                  )
                : null,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}

class MaterialColorPicker extends StatelessWidget {
  const MaterialColorPicker({super.key, required this.onPicked});

  final ValueChanged<Color> onPicked;

  static final _colors = kThemeSoftSwatchColors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _colors)
          InkWell(
            onTap: () => onPicked(c),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c,
                border: Border.all(
                  color: c.computeLuminance() < 0.15 ? Colors.white54 : Colors.black26,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
