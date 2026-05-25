import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../data/models.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../providers/session_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/sign_in_channel_provider.dart';
import '../theme/app_theme_scope.dart';
import '../theme/custom_background_persist.dart';
import '../theme/theme_preset.dart';
import 'recording_diagnostics_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyAsync = ref.watch(settingsBabyProvider);
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置中心'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!loggedIn)
            Card(
              child: ListTile(
                leading: const Icon(Icons.child_care_outlined),
                title: const Text('宝宝信息'),
                subtitle: const Text('登录后查看与编辑'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/login'),
              ),
            )
          else
            babyAsync.when(
              data: (baby) => _BabyProfileReadonlyCard(
                key: ValueKey('${baby.id}-${baby.nickname}-${baby.sex}-${baby.birthDate.toIso8601String()}'),
                baby: baby,
              ),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (e, _) => Text('加载失败：$e'),
            ),
          const SizedBox(height: 12),
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) const VoiceInputSettingsGroup(),
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('隐私政策'),
            onTap: () => context.push(
              Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('切换账号'),
            onTap: () async {
              final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('切换账号'),
                      content: const Text('将清除本地会话、设备缓存并返回登录页。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok || !context.mounted) return;
              await ref.read(authRepositoryProvider).signOut();
              await ref.read(sessionProvider).signOut();
              await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
              await ref.read(signInChannelProvider.notifier).clear();
              if (context.mounted) context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('注销账户'),
            onTap: () => _confirmDeregister(context, ref),
          ),
          const Divider(height: 32),
          const Text('主题', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const _ThemePresetSection(),
        ],
      ),
    );
  }

  Future<void> _confirmDeregister(BuildContext context, WidgetRef ref) async {
    final step1 = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('注销账户'),
            content: const Text('第一步：确认你了解此操作的风险。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('继续')),
            ],
          ),
        ) ??
        false;
    if (!step1 || !context.mounted) return;
    final step2 = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('再次确认'),
            content: const Text('第二步：将向服务端申请注销并清除本地会话与设备缓存。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认注销')),
            ],
          ),
        ) ??
        false;
    if (!step2 || !context.mounted) return;
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(sessionProvider).signOut();
    await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
    await ref.read(signInChannelProvider.notifier).clear();
    if (context.mounted) context.go('/home');
  }
}

class _BabyProfileReadonlyCard extends StatelessWidget {
  const _BabyProfileReadonlyCard({super.key, required this.baby});

  final BabyProfile baby;

  static String _sexLabel(BabySex s) => switch (s) {
        BabySex.male => '男',
        BabySex.female => '女',
        BabySex.unknown => '未填',
      };

  static Widget _readonlyRow(BuildContext context, String label, String value) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: TextStyle(color: secondary, fontSize: 14)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16, height: 1.3))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final birthStr = baby.birthDate.toIso8601String().split('T').first;
    return Card(
      color: themePrimaryBlend(context, alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/settings/baby'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text('宝宝信息', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    Text(
                      '编辑',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _readonlyRow(context, '昵称', baby.nickname),
              _readonlyRow(context, '性别', _sexLabel(baby.sex)),
              _readonlyRow(context, '生日', birthStr),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('ID：${baby.id}', style: Theme.of(context).textTheme.bodySmall),
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
            final picked = await showDialog<Color>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('选择背景色'),
                content: MaterialColorPicker(
                  onPicked: (c) => Navigator.pop(ctx, c),
                ),
              ),
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
