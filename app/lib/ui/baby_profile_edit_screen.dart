import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_baby.dart';
import 'baby_profile_editor.dart';

/// 设置中心下一级：编辑宝宝资料（可保存）。
class BabyProfileEditScreen extends ConsumerWidget {
  const BabyProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyAsync = ref.watch(settingsBabyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑宝宝信息'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          babyAsync.when(
            data: (baby) => BabyProfileEditor(
              key: ValueKey('${baby.id}-${baby.nickname}-${baby.sex}-${baby.birthDate.toIso8601String()}'),
              initialBaby: baby,
              onSaved: () {
                if (context.mounted) context.pop();
              },
            ),
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('加载失败：$e'),
          ),
        ],
      ),
    );
  }
}
