import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../api/gateway_json.dart';
import '../data/models.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/settings_baby.dart';
import '../providers/toast_bus.dart';

DateTime _bindDefaultBirth() {
  final now = DateTime.now();
  final j6 = DateTime(now.year, 6, 1);
  if (!j6.isAfter(now)) return j6;
  return DateTime(now.year, 1, 1);
}

DateTime _bindClampBirthForPicker(DateTime birth) {
  final first = DateTime(2000);
  final last = DateTime.now();
  final d = DateTime(birth.year, birth.month, birth.day);
  if (d.isBefore(first)) return first;
  if (d.isAfter(last)) return DateTime(last.year, last.month, last.day);
  return d;
}

/// 绑定已有宝宝或创建新宝宝（远程模式）。
class BabyBindScreen extends ConsumerStatefulWidget {
  const BabyBindScreen({super.key});

  @override
  ConsumerState<BabyBindScreen> createState() => _BabyBindScreenState();
}

class _BabyBindScreenState extends ConsumerState<BabyBindScreen> {
  final _deviceCtrl = TextEditingController();
  final _birth = ValueNotifier<DateTime>(_bindDefaultBirth());
  BabySex _sex = BabySex.unknown;
  var _busy = false;

  @override
  void dispose() {
    _deviceCtrl.dispose();
    _birth.dispose();
    super.dispose();
  }

  Future<void> _bind() async {
    final no = _deviceCtrl.text.trim();
    if (no.isEmpty) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(authorizedApiClientProvider);
      await api.postJsonEnvelope('/device/app/api/user/bindwx', {'deviceNo': no});
      await ref.read(deviceNoNotifierProvider.notifier).setLocal(no);
      ref.invalidate(settingsBabyProvider);
      if (mounted) context.pop(true);
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(authorizedApiClientProvider);
      final d = _birth.value;
      final midnight = DateTime(d.year, d.month, d.day);
      final sexCode = switch (_sex) {
        BabySex.female => 0,
        BabySex.male => 1,
        BabySex.unknown => 0,
      };
      final data = await api.postJsonEnvelope(
        '/device/app/api/user/auto_save',
        {
          'birthday': midnight.millisecondsSinceEpoch ~/ 1000,
          'sex': sexCode,
        },
      );
      final dn = readGatewayStr(data ?? const {}, 'deviceNo', 'device_no');
      if (dn == null || dn.isEmpty) {
        ref.showApiToastError('创建成功但未返回 deviceNo');
        return;
      }
      await ref.read(deviceNoNotifierProvider.notifier).setLocal(dn);
      ref.invalidate(settingsBabyProvider);
      if (mounted) context.pop(true);
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('绑定宝宝'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop(false)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('绑定已有宝宝', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _deviceCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '宝宝 deviceNo',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _bind,
            child: const Text('绑定'),
          ),
          const Divider(height: 40),
          const Text('创建新宝宝', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<DateTime>(
            valueListenable: _birth,
            builder: (context, d, _) {
              return ListTile(
                title: const Text('生日'),
                subtitle: Text(d.toIso8601String().split('T').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _bindClampBirthForPicker(d),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) _birth.value = picked;
                },
              );
            },
          ),
          SegmentedButton<BabySex>(
            segments: const [
              ButtonSegment(value: BabySex.male, label: Text('男')),
              ButtonSegment(value: BabySex.female, label: Text('女')),
              ButtonSegment(value: BabySex.unknown, label: Text('未填')),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => setState(() => _sex = s.first),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: const Text('创建并绑定'),
          ),
        ],
      ),
    );
  }
}
