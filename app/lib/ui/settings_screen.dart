import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../config/event_media_local_store.dart';
import '../data/models.dart';
import '../providers/settings_baby.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
import '../theme/app_theme_schedule.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_visual_tokens.dart';
import '../theme/custom_background_persist.dart';
import '../theme/theme_custom_color_wheel.dart';
import '../theme/theme_preset.dart';
import 'account_management_sheet.dart';
import 'speech_engine_tile.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/settings_glass_panel.dart';

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
                const SpeechEngineTile(),
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
                  leading: Icons.feedback_outlined,
                  title: '反馈建议',
                  onTap: () => context.push('/settings/feedback'),
                ),
                const SizedBox(height: 12),
                _buildGlassTile(
                  context,
                  leading: Icons.photo_library_outlined,
                  title: '清除历史媒体缓存',
                  subtitle: '删除本地复制的历史事件图片与视频',
                  onTap: () => _confirmClearHistoryMediaCache(context),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              const _ThemeSectionHeader(),
              const _ThemePresetSection(),
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
    required VoidCallback onTap,
  }) {
    final tokens = visualTokensOf(context);
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
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
        trailing: Icon(Icons.chevron_right, size: 20, color: onShell.withValues(alpha: 0.5)),
        onTap: onTap,
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

    return SettingsGlassPanel(
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

class _ThemeSectionHeader extends ConsumerWidget {
  const _ThemeSectionHeader();

  Future<void> _setScheduleEnabled(WidgetRef ref, bool enabled) async {
    await persistThemePreferences(scheduleEnabled: enabled);
    ref.read(themeScheduleEnabledProvider.notifier).state = enabled;
    refreshScheduledTheme(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = visualTokensOf(context);
    final onShell = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final scheduleEnabled = ref.watch(themeScheduleEnabledProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Text(
            '主题',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: onShell,
            ),
          ),
          const Spacer(),
          Text(
            '自动夜空',
            style: TextStyle(fontSize: 13, color: onShell.withValues(alpha: 0.75)),
          ),
          const SizedBox(width: 4),
          Switch.adaptive(
            value: scheduleEnabled,
            onChanged: (v) => _setScheduleEnabled(ref, v),
          ),
        ],
      ),
    );
  }
}

class _ThemePresetSection extends ConsumerStatefulWidget {
  const _ThemePresetSection();

  @override
  ConsumerState<_ThemePresetSection> createState() => _ThemePresetSectionState();
}

class _ThemePresetSectionState extends ConsumerState<_ThemePresetSection> {
  static const _classicSwatch = Color(0xFFF5F5F5);
  static const _defaultCustomPreview = Color(0xFFE3F2FD);

  var _colorWheelExpanded = false;

  Future<void> _applyBaseline(WidgetRef ref, {ThemePreset? preset, Color? seed}) async {
    await persistThemePreferences(seed: seed, preset: preset);
    ref.read(themePresetProvider.notifier).state = preset;
    ref.read(customBackgroundProvider.notifier).state = seed;
    refreshScheduledTheme(ref);
  }

  Future<void> _clearToClassic(WidgetRef ref) async {
    await clearThemePreferences();
    ref.read(themePresetProvider.notifier).state = null;
    ref.read(customBackgroundProvider.notifier).state = null;
    setState(() => _colorWheelExpanded = false);
    refreshScheduledTheme(ref);
  }

  void _toggleColorWheel() {
    setState(() => _colorWheelExpanded = !_colorWheelExpanded);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(themeScheduleEnabledProvider, (previous, next) {
      if (next && _colorWheelExpanded) {
        setState(() => _colorWheelExpanded = false);
      }
    });

    final scheduleEnabled = ref.watch(themeScheduleEnabledProvider);
    final baselinePreset = ref.watch(themePresetProvider);
    final baselineSeed = ref.watch(customBackgroundProvider);
    final isClassic = baselinePreset == null && baselineSeed == null;
    final isNightBaseline = baselinePreset == ThemePreset.nightSky;
    final isCustom = baselinePreset == null && baselineSeed != null;
    final previewColor = baselineSeed ?? _defaultCustomPreview;

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
              selected: isClassic,
              onTap: () => _clearToClassic(ref),
            ),
            _PresetSwatch(
              label: '夜空',
              color: kNightSkyShell,
              selected: isNightBaseline,
              onTap: () {
                setState(() => _colorWheelExpanded = false);
                _applyBaseline(ref, preset: ThemePreset.nightSky, seed: kNightSkyShell);
              },
            ),
            if (!scheduleEnabled)
              _ColorfulSwatch(
                label: '彩色',
                seed: baselineSeed,
                selected: isCustom,
                expanded: _colorWheelExpanded,
                onTap: _toggleColorWheel,
              ),
          ],
        ),
        if (!scheduleEnabled && _colorWheelExpanded) ...[
          const SizedBox(height: 12),
          _CustomThemeColorPicker(
            color: previewColor,
            selected: isCustom,
            onColorChanged: (c) => _applyBaseline(ref, preset: null, seed: c),
          ),
        ],
      ],
    );
  }
}

class _ColorfulSwatch extends StatelessWidget {
  const _ColorfulSwatch({
    required this.label,
    required this.seed,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final Color? seed;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  static const _rainbow = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  @override
  Widget build(BuildContext context) {
    final borderColor = selected || expanded
        ? Theme.of(context).colorScheme.primary
        : Colors.black26;
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
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: selected || expanded ? 2.5 : 1),
              color: seed,
              gradient: seed == null
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _rainbow,
                    )
                  : null,
            ),
            child: seed == null
                ? Icon(Icons.palette_outlined, color: Colors.white.withValues(alpha: 0.92), size: 22)
                : (selected
                    ? Icon(
                        Icons.check,
                        color: seed!.computeLuminance() < 0.4 ? Colors.white : Colors.black87,
                        size: 20,
                      )
                    : null),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CustomThemeColorPicker extends StatelessWidget {
  const _CustomThemeColorPicker({
    required this.color,
    required this.selected,
    required this.onColorChanged,
  });

  final Color color;
  final bool selected;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.35),
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ThemeCustomColorWheel(
          color: color,
          onColorChanged: onColorChanged,
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
