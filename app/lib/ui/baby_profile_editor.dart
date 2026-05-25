import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../theme/app_theme_scope.dart';
import '../theme/theme_bootstrap_cache.dart';
import 'widgets/app_toast.dart';

/// 宝宝资料表单：加载 [initialBaby]，保存后刷新 [settingsBabyProvider] 与主题性别。
/// [onSaved] 在保存成功且 SnackBar 展示前调用（例如返回上一级）。
class BabyProfileEditor extends ConsumerStatefulWidget {
  const BabyProfileEditor({super.key, required this.initialBaby, this.onSaved});

  final BabyProfile initialBaby;
  final VoidCallback? onSaved;

  @override
  ConsumerState<BabyProfileEditor> createState() => _BabyProfileEditorState();
}

class _BabyProfileEditorState extends ConsumerState<BabyProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late BabySex _sex;
  late DateTime _birth;

  static final DateTime _firstBirth = DateTime(2000);

  /// 生日不可早于 2000、不可晚于今天（与 [showDatePicker] 一致）。
  static DateTime _clampBirthToValidRange(DateTime birth) {
    final last = DateTime.now();
    final d = DateTime(birth.year, birth.month, birth.day);
    if (d.isBefore(_firstBirth)) return _firstBirth;
    if (d.isAfter(last)) return DateTime(last.year, last.month, last.day);
    return d;
  }

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.initialBaby.nickname);
    _sex = widget.initialBaby.sex;
    _birth = _clampBirthToValidRange(widget.initialBaby.birthDate);
  }

  @override
  void didUpdateWidget(covariant BabyProfileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = oldWidget.initialBaby;
    final n = widget.initialBaby;
    if (o.id != n.id || o.nickname != n.nickname || o.sex != n.sex || o.birthDate != n.birthDate) {
      _nicknameCtrl.text = n.nickname;
      _sex = n.sex;
      _birth = _clampBirthToValidRange(n.birthDate);
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final last = DateTime.now();
    final initial = _clampBirthToValidRange(_birth);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _firstBirth,
      lastDate: last,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = BabyProfile(
      id: widget.initialBaby.id,
      nickname: _nicknameCtrl.text.trim(),
      sex: _sex,
      birthDate: _birth,
    );
    try {
      await ref.read(settingsRepositoryProvider).saveBaby(profile);
      ref.invalidate(settingsBabyProvider);
      ref.read(babySexProvider.notifier).state = profile.sex;
      await persistCachedBabySex(profile.sex);
      if (!mounted) return;
      showAppToast('宝宝信息已保存', tone: AppToastTone.success);
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      showAppToast('保存失败：$e', tone: AppToastTone.error);
    }
  }

  void _cancel() {
    _nicknameCtrl.text = widget.initialBaby.nickname;
    _sex = widget.initialBaby.sex;
    _birth = _clampBirthToValidRange(widget.initialBaby.birthDate);
    setState(() {});
    showAppToast('已恢复为上次加载的数据');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('宝宝信息', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nicknameCtrl,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '昵称不能为空';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text('性别'),
              const SizedBox(height: 8),
              SegmentedButton<BabySex>(
                segments: const [
                  ButtonSegment(value: BabySex.male, label: Text('男')),
                  ButtonSegment(value: BabySex.female, label: Text('女')),
                  ButtonSegment(value: BabySex.unknown, label: Text('未填')),
                ],
                selected: {_sex},
                onSelectionChanged: (s) => setState(() => _sex = s.first),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('生日'),
                subtitle: Text(_birth.toIso8601String().split('T').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirth,
              ),
              Text('ID：${widget.initialBaby.id}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _cancel, child: const Text('取消')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(onPressed: _save, child: const Text('保存')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
