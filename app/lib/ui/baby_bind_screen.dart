import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pangbao_app/home_widget/home_widget_payload.dart';

import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
import '../api/gateway_json.dart';
import '../data/baby_share_qr_payload.dart';
import '../data/models.dart';
import '../data/client_usage_events.dart';
import '../providers/authorized_api_client_provider.dart';
import '../providers/client_usage_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/home_history_notifier.dart';
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

/// 预览昵称展示：空则「宝宝」。
String _previewDisplayName(String? babyName) {
  final t = babyName?.trim() ?? '';
  return t.isEmpty ? '宝宝' : t;
}

enum _BabyBindMode { bind, create }

/// 绑定已有宝宝或创建新宝宝（远程模式）。
/// 绑定模式：扫一扫 / 相册识码 → bind_preview → 确认昵称 → bindwx（无手输 ID）。
class BabyBindScreen extends ConsumerStatefulWidget {
  const BabyBindScreen({super.key});

  @override
  ConsumerState<BabyBindScreen> createState() => _BabyBindScreenState();
}

class _BabyBindScreenState extends ConsumerState<BabyBindScreen> {
  final _nicknameCtrl = TextEditingController();
  final _nicknameFocusNode = FocusNode();
  final _nicknameFieldKey = GlobalKey();
  final _scrollCtrl = ScrollController();
  final _birth = ValueNotifier<DateTime>(_bindDefaultBirth());
  BabySex _sex = BabySex.male;
  var _busy = false;
  // 全家共享主路径：进页默认绑定（扫码），创建为次路径
  var _mode = _BabyBindMode.bind;

  @override
  void initState() {
    super.initState();
    _nicknameFocusNode.addListener(_scrollNicknameIntoView);
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
    if (_nicknameFocusNode.hasFocus) return _nicknameFieldKey;
    return null;
  }

  FocusNode? get _focusedAuthField {
    if (_nicknameFocusNode.hasFocus) return _nicknameFocusNode;
    return null;
  }

  @override
  void dispose() {
    _nicknameFocusNode.removeListener(_scrollNicknameIntoView);
    _nicknameFocusNode.dispose();
    _nicknameCtrl.dispose();
    _scrollCtrl.dispose();
    _birth.dispose();
    super.dispose();
  }

  void _scheduleHistoryBootstrapAfterBind() {
    // 统一池：切宝宝 bootstrap 已含一次 7 日种子
    unawaited(ref.read(homeHistoryProvider.notifier).onDeviceNoChanged());
  }

  /// 扫码/识码得到 deviceNo 后：预览 → 确认 → bindwx。
  Future<void> _onDeviceNoFromQr(String deviceNo) async {
    final no = deviceNo.trim();
    if (no.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(authorizedApiClientProvider);
      final data = await api.postJsonEnvelope(
        '/device/app/api/user/bind_preview',
        {'deviceNo': no},
      );
      final echo =
          readGatewayStr(data ?? const {}, 'deviceNo', 'device_no') ?? no;
      final babyName =
          readGatewayStr(data ?? const {}, 'babyName', 'baby_name') ?? '';
      final display = _previewDisplayName(babyName);
      AppDebugLog.babyShare(
        'preview ok deviceNoLen=${echo.length} nameLen=${display.length}',
      );
      if (!mounted) return;
      final go = await showGlassConfirmDialog(
            context,
            title: '确认绑定',
            message: '确认绑定到「$display」？\n绑定后将同步该宝宝的喂养与预测。',
            cancelLabel: '取消',
            confirmLabel: '确认绑定',
          ) ??
          false;
      if (!go) {
        AppDebugLog.babyShare('preview confirm cancelled');
        return;
      }
      await _bindDeviceNo(echo);
    } on ApiBusinessException catch (e) {
      AppDebugLog.babyShare('preview fail err=${e.message}');
      ref.showApiToastError(e.message);
    } catch (e) {
      AppDebugLog.babyShare('preview fail err=$e');
      ref.showApiToastError('预览失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bindDeviceNo(String no) async {
    final api = ref.read(authorizedApiClientProvider);
    await api.postJsonEnvelope('/device/app/api/user/bindwx', {'deviceNo': no});
    final synced =
        await ensureAccessTokenHasDeviceNoFromWidget(ref, localDeviceNo: no);
    if (!synced) {
      if (mounted) {
        ref.showApiToastError('会话刷新失败，请重新登录后再试');
      }
      return;
    }
    await ref.read(deviceNoNotifierProvider.notifier).setLocal(no);
    ref.invalidate(settingsBabyProvider);
    _scheduleHistoryBootstrapAfterBind();
    unawaited(
      ref
          .read(feedRepositoryProvider)
          .reconnectHistoryWebSocket(resetStrike: true),
    );
    if (mounted) GoRouter.of(context).go('/home');
  }

  Future<void> _openCameraScan() async {
    if (_busy) return;
    final dn = await context.push<String>('/settings/scan-baby-qr');
    if (!mounted || dn == null || dn.trim().isEmpty) return;
    await _onDeviceNoFromQr(dn);
  }

  Future<void> _pickAlbumQr() async {
    if (_busy) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) return;
      final controller = MobileScannerController();
      try {
        final capture = await controller.analyzeImage(picked.path);
        final raw = capture?.barcodes
                .map((b) => b.rawValue)
                .whereType<String>()
                .map((s) => s.trim())
                .firstWhere((s) => s.isNotEmpty, orElse: () => '') ??
            '';
        if (raw.isEmpty) {
          AppDebugLog.babyShare('album no barcode');
          if (mounted) {
            ref.showApiToastError(BabyShareQrPayload.invalidMessage);
          }
          return;
        }
        final dn = BabyShareQrPayload.tryDecode(raw);
        if (dn == null) {
          AppDebugLog.babyShare('album reject non-product');
          if (mounted) {
            ref.showApiToastError(BabyShareQrPayload.invalidMessage);
          }
          return;
        }
        AppDebugLog.babyShare('album ok deviceNoLen=${dn.length}');
        await _onDeviceNoFromQr(dn);
      } finally {
        await controller.dispose();
      }
    } catch (e) {
      AppDebugLog.babyShare('album fail err=$e');
      if (mounted) {
        ref.showApiToastError('无法识别图片中的二维码');
      }
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
    var shouldPop = false;
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
        ref.showApiToastError('创建成功但未返回宝宝信息');
        return;
      }
      final synced =
          await ensureAccessTokenHasDeviceNoFromWidget(ref, localDeviceNo: dn);
      if (!synced) {
        if (mounted) {
          ref.showApiToastError('会话刷新失败，请重新登录后再试');
        }
        return;
      }
      await ref.read(deviceNoNotifierProvider.notifier).setLocal(dn);
      shouldPop = true;
      ref.invalidate(settingsBabyProvider);
      _scheduleHistoryBootstrapAfterBind();
      unawaited(
        ref
            .read(feedRepositoryProvider)
            .reconnectHistoryWebSocket(resetStrike: true),
      );
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } finally {
      if (mounted && shouldPop) GoRouter.of(context).go('/home');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = visualTokensOf(context);
    final isDark = tokens?.isDarkShell ??
        (Theme.of(context).brightness == Brightness.dark);

    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd =
        Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;

    return ClientUsageShowOnce(
      event: ClientUsageEvents.bindBabyShow,
      child: Scaffold(
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
                  child: InlineAuthKeyboardLiftHost(
                    scrollController: _scrollCtrl,
                    focusedNode: _focusedAuthField,
                    anchorKey: _focusedAuthAnchor,
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        16 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: _mode == _BabyBindMode.bind
                          ? _buildBindCard(context, scheme)
                          : _buildCreateCard(context, scheme, isDark),
                    ),
                  ),
                ),
                _buildFooterButtons(scheme, isDark),
              ],
            ),
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

  Widget _buildBindCard(BuildContext context, ColorScheme scheme) {
    final onShell = AppColor.textPrimary(context);
    final scanEnabled = !kIsWeb && !_busy;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '扫码绑定',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onShell,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '让家人出示共享二维码，扫一扫或从相册选码即可绑定同一宝宝。',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColor.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),
          if (kIsWeb)
            Text(
              '请在手机 App 上使用扫码或相册绑定；网页端请改用「创建新宝宝」，或请家人在手机上操作。',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: onShell.withValues(alpha: 0.75),
              ),
            )
          else ...[
            FilledButton.icon(
              onPressed: scanEnabled ? _openCameraScan : null,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('扫一扫'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary.withValues(alpha: 0.85),
                foregroundColor: AppColor.onPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: scanEnabled ? _pickAlbumQr : null,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('相册选码'),
              style: OutlinedButton.styleFrom(
                foregroundColor: onShell,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateCard(
      BuildContext context, ColorScheme scheme, bool isDark) {
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      Icon(Icons.calendar_today,
                          size: 18, color: scheme.primary),
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
    // 绑定模式：扫码即流程，底部仅取消；创建模式保留确认。
    if (_mode == _BabyBindMode.bind) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: TextButton(
          onPressed: () => context.pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColor.textMuted(context),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('取消', style: TextStyle(fontSize: 16)),
        ),
      );
    }

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
              onPressed: _busy ? null : _create,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary.withValues(alpha: 0.8),
                foregroundColor: AppColor.onPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99)),
                elevation: 0,
              ),
              child: Text(
                _busy ? '处理中...' : '确认',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? scheme.primary
                  : AppColor.textPrimary(context).withValues(alpha: 0.6),
            ),
          ),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppColor.fieldFill(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColor.textMuted(context),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white)
                .withValues(alpha: isDark ? 0.08 : 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
