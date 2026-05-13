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
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('自定义背景颜色'),
            subtitle: const Text('保存后将覆盖性别默认背景'),
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
              if (picked != null) {
                ref.read(customBackgroundProvider.notifier).state = picked;
                await persistCustomBackground(picked);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('清除自定义背景'),
            onTap: () async {
              ref.read(customBackgroundProvider.notifier).state = null;
              await persistCustomBackground(null);
            },
          ),
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

class MaterialColorPicker extends StatelessWidget {
  const MaterialColorPicker({super.key, required this.onPicked});

  final ValueChanged<Color> onPicked;

  static const _colors = <Color>[
    Color(0xFFE3F2FD),
    Color(0xFFFFEBEE),
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFECEFF1),
    Color(0xFFE1BEE7),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _colors)
          InkWell(
            onTap: () => onPicked(c),
            child: Container(width: 44, height: 44, decoration: BoxDecoration(color: c, border: Border.all())),
          ),
      ],
    );
  }
}
