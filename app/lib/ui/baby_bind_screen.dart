import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pangbao_app/home_widget/home_widget_payload.dart';

import '../api/api_exceptions.dart';
import '../api/gateway_json.dart';
import '../data/models.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../providers/toast_bus.dart';
import '../session/session_device_token_sync.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/baby_birth_picker_sheet.dart';
import 'auth/auth_field_scroll.dart';
import 'widgets/keyboard_lift.dart';

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

enum _BabyBindMode { bind, create }

/// 绑定已有宝宝或创建新宝宝（远程模式）。
class BabyBindScreen extends ConsumerStatefulWidget {
  const BabyBindScreen({super.key});

  @override
  ConsumerState<BabyBindScreen> createState() => _BabyBindScreenState();
}

class _BabyBindScreenState extends ConsumerState<BabyBindScreen> {
  final _deviceCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _deviceFocusNode = FocusNode();
  final _nicknameFocusNode = FocusNode();
  final _deviceFieldKey = GlobalKey();
  final _nicknameFieldKey = GlobalKey();
  final _scrollCtrl = ScrollController();
  final _birth = ValueNotifier<DateTime>(_bindDefaultBirth());
  BabySex _sex = BabySex.male;
  var _busy = false;
  var _mode = _BabyBindMode.create;

  @override
  void initState() {
    super.initState();
    _deviceFocusNode.addListener(_scrollDeviceIntoView);
    _nicknameFocusNode.addListener(_scrollNicknameIntoView);
  }

  void _scrollDeviceIntoView() {
    if (!mounted) return;
    scrollInlineAuthFieldIntoView(
      _deviceFocusNode,
      context: context,
      scrollController: _scrollCtrl,
      anchorKey: _deviceFieldKey,
    );
  }

  void _scrollNicknameIntoView() {
    if (!mounted) return;
    scrollInlineAuthFieldIntoView(
      _nicknameFocusNode,
      context: context,
      scrollController: _scrollCtrl,
      anchorKey: _nicknameFieldKey,
    );
  }

  GlobalKey? get _focusedAuthAnchor {
    if (_deviceFocusNode.hasFocus) return _deviceFieldKey;
    if (_nicknameFocusNode.hasFocus) return _nicknameFieldKey;
    return null;
  }

  FocusNode? get _focusedAuthField {
    if (_deviceFocusNode.hasFocus) return _deviceFocusNode;
    if (_nicknameFocusNode.hasFocus) return _nicknameFocusNode;
    return null;
  }

  @override
  void dispose() {
    _deviceFocusNode.removeListener(_scrollDeviceIntoView);
    _nicknameFocusNode.removeListener(_scrollNicknameIntoView);
    _deviceFocusNode.dispose();
    _nicknameFocusNode.dispose();
    _deviceCtrl.dispose();
    _nicknameCtrl.dispose();
    _scrollCtrl.dispose();
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
      final synced = await ensureAccessTokenHasDeviceNoFromWidget(ref, localDeviceNo: no);
      if (!synced) {
        if (mounted) {
          ref.showApiToastError('会话刷新失败，请重新登录后再试');
        }
        return;
      }
      await ref.read(deviceNoNotifierProvider.notifier).setLocal(no);
      ref.invalidate(settingsBabyProvider);
      unawaited(
        ref.read(feedRepositoryProvider).reconnectHistoryWebSocket(resetStrike: true),
      );
      if (mounted) context.pop(true);
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final go = await showGlassConfirmDialog(
          context,
          title: '创建新宝宝提醒',
          message: '若家人已创建宝宝，请使用绑定宝宝功能，不要创建新宝宝。',
          cancelLabel: '去绑定宝宝',
          confirmLabel: '继续创建',
        ) ??
        false;
    if (!go) {
      if (mounted) {
        setState(() => _mode = _BabyBindMode.bind);
      }
      return;
    }

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
          'babyName': _nicknameCtrl.text.trim(),
        },
      );
      final dn = readGatewayStr(data ?? const {}, 'deviceNo', 'device_no');
      if (dn == null || dn.isEmpty) {
        ref.showApiToastError('创建成功但未返回宝宝ID');
        return;
      }
      final synced = await ensureAccessTokenHasDeviceNoFromWidget(ref, localDeviceNo: dn);
      if (!synced) {
        if (mounted) {
          ref.showApiToastError('会话刷新失败，请重新登录后再试');
        }
        return;
      }
      await ref.read(deviceNoNotifierProvider.notifier).setLocal(dn);
      ref.invalidate(settingsBabyProvider);
      unawaited(
        ref.read(feedRepositoryProvider).reconnectHistoryWebSocket(resetStrike: true),
      );
      if (mounted) context.pop(true);
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = visualTokensOf(context);
    final isDark = tokens?.isDarkShell ?? (Theme.of(context).brightness == Brightness.dark);

    // 背景渐变：随主色调变化
    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd = Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('宝宝信息绑定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(false),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildModeSwitcher(scheme, isDark),
              const SizedBox(height: 32),
              Expanded(
                child: Builder(
                  builder: (context) {
                    scheduleInlineAuthScrollOnInset(
                      context,
                      focusedNode: _focusedAuthField,
                      scrollController: _scrollCtrl,
                      anchorKey: _focusedAuthAnchor,
                    );
                    return SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
                      child: _mode == _BabyBindMode.bind
                          ? _buildBindCard(context, scheme, isDark)
                          : _buildCreateCard(context, scheme, isDark),
                    );
                  },
                ),
              ),
              _buildFooterButtons(scheme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitcher(ColorScheme scheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: '绑定宝宝',
              selected: _mode == _BabyBindMode.bind,
              onTap: () => setState(() => _mode = _BabyBindMode.bind),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: '创建新宝宝',
              selected: _mode == _BabyBindMode.create,
              onTap: () => setState(() => _mode = _BabyBindMode.create),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBindCard(BuildContext context, ColorScheme scheme, bool isDark) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '输入宝宝ID',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          keyboardLiftTarget(
            focusNode: _deviceFocusNode,
            anchorKey: _deviceFieldKey,
            child: TextField(
              controller: _deviceCtrl,
              focusNode: _deviceFocusNode,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '请输入宝宝ID',
                filled: true,
                fillColor: AppColor.fieldFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '从你的家人那查看宝宝信息，复制宝宝id输入',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColor.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCard(BuildContext context, ColorScheme scheme, bool isDark) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '宝宝基本信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel(context, '宝宝昵称'),
          keyboardLiftTarget(
            focusNode: _nicknameFocusNode,
            anchorKey: _nicknameFieldKey,
            child: TextField(
              controller: _nicknameCtrl,
              focusNode: _nicknameFocusNode,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '请输入宝宝昵称',
                filled: true,
                fillColor: AppColor.fieldFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel(context, '宝宝生日'),
          ValueListenableBuilder<DateTime>(
            valueListenable: _birth,
            builder: (context, d, _) {
              return InkWell(
                onTap: () async {
                  final picked = await showBabyBirthPickerSheet(
                    context,
                    initialValue: _bindClampBirthForPicker(d),
                    title: '选择宝宝生日',
                  );
                  if (picked != null) _birth.value = picked;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColor.fieldFill(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                         HomeWidgetRowPayload.isoDateUtc(d),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today, size: 18, color: scheme.primary),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildLabel(context, '宝宝性别'),
          Row(
            children: [
              _SexChip(
                label: '小王子',
                selected: _sex == BabySex.male,
                color: Colors.blue,
                onTap: () => setState(() => _sex = BabySex.male),
              ),
              const SizedBox(width: 12),
              _SexChip(
                label: '小公主',
                selected: _sex == BabySex.female,
                color: Colors.pink,
                onTap: () => setState(() => _sex = BabySex.female),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppColor.textMuted(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFooterButtons(ColorScheme scheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => context.pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppColor.textMuted(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('取消', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _busy ? null : (_mode == _BabyBindMode.bind ? _bind : _create),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary.withValues(alpha: 0.8),
                foregroundColor: AppColor.onPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 0,
              ),
              child: Text(
                _busy ? '处理中...' : '确认',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // 选中态：浅壳近白玻璃；暗壳 surface+primary，避免白板
          color: selected ? AppColor.contentCard(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.primary : scheme.primary.withValues(alpha: 0.7),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColor.modalFill(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColor.modalBorder(context)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SexChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SexChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 未选中底/边走主题玻璃；选中保留性别语义色（产品例外）
    final idleFill = AppColor.fieldFill(context);
    final idleBorder = AppColor.fieldBorder(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : idleFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : idleBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColor.textMuted(context),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

