import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../api/api_exceptions.dart';
import '../data/cash_vip_models.dart';
import '../data/xiaozhi_mcp_models.dart';
import '../providers/device_no_notifier.dart';
import '../providers/toast_bus.dart';
import '../providers/xiaozhi_mcp_provider.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'home_history_edit_glass_panel.dart';
import 'xiaozhi_console_link.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/settings_glass_panel.dart';

/// 设置中心「小智音箱」：开通态 + 绑定管理。
class XiaozhiSpeakerScreen extends ConsumerStatefulWidget {
  const XiaozhiSpeakerScreen({super.key});

  @override
  ConsumerState<XiaozhiSpeakerScreen> createState() =>
      _XiaozhiSpeakerScreenState();
}

class _XiaozhiSpeakerScreenState extends ConsumerState<XiaozhiSpeakerScreen> {
  bool _paying = false;

  /// 规范化 MAC 便于本地判断 upsert。
  String _normMac(String raw) {
    final hex = StringBuffer();
    for (final c in raw.toLowerCase().codeUnits) {
      if ((c >= 48 && c <= 57) || (c >= 97 && c <= 102)) {
        hex.writeCharCode(c);
      }
    }
    return hex.toString();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(xiaozhiMcpUnlockProvider);
    ref.invalidate(xiaozhiMcpBindingsProvider);
  }

  Future<void> _purchasePermanent(XiaozhiMcpProduct product) async {
    if (_paying) return;
    // 付款前知情确认：须自购硬件，本次付款不含音箱实体。
    final agreed = await showGlassConfirmDialog(
          context,
          title: '开通前确认',
          message:
              '使用本功能前，须自行购买小智音箱。本次付款仅开通 App 内绑定与语音记喂养能力，不包含音箱实体。',
          confirmLabel: '继续开通',
        ) ??
        false;
    if (!agreed || !mounted) return;
    setState(() => _paying = true);
    try {
      final outcome =
          await ref.read(xiaozhiMcpPaymentServiceProvider).purchase(product);
      if (!mounted) return;
      if (outcome.cancelled) {
        ref.showApiToast(outcome.message);
        return;
      }
      if (outcome.success) {
        ref.showApiToast(outcome.message, tone: AppToastTone.success);
        await _refreshAll();
      } else {
        ref.showApiToastError(outcome.message);
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _onAddTap({
    required XiaozhiMcpUnlockView unlock,
    required bool hasBaby,
  }) async {
    if (!hasBaby) {
      final go = await showGlassConfirmDialog(
            context,
            title: '需要先绑定宝宝',
            message: '添加小智音箱前请先绑定宝宝设备，喂养记录才会落到正确账号。',
            confirmLabel: '去绑机',
          ) ??
          false;
      if (go && mounted) context.push('/settings/bind-baby');
      return;
    }
    if (!unlock.canAdd) {
      final product = unlock.product;
      if (product != null && product.isOnSale) {
        final go = await showGlassConfirmDialog(
              context,
              title: '体验已用完',
              message:
                  '免费体验已使用完毕。开通永久能力后即可继续添加音箱（¥${formatVipFenYuan(product.priceFen)}）。',
              confirmLabel: '永久开通',
            ) ??
            false;
        if (go && mounted) await _purchasePermanent(product);
      } else {
        ref.showApiToast('体验已用完，请稍后再试或联系客服开通');
      }
      return;
    }

    // 试用可用且未开通：提交前再确认（表单内也会再确认一次提交）。
    final result = await showGlassDialog<_AddBindingResult>(
      context: context,
      maxWidth: 360,
      maxHeightFraction: 0.85,
      contentBuilder: (ctx) => _AddBindingDialogBody(
        needTrialConfirm: unlock.trialAvailable && !unlock.unlocked,
        // 用管理页 context 叠帮助路由，不关表单。
        onHelpMac: () => context.push('/settings/xiaozhi-speaker/help-mac'),
        onHelpToken: () =>
            context.push('/settings/xiaozhi-speaker/help-token'),
      ),
    );
    if (result == null || !mounted) return;

    final existing = ref.read(xiaozhiMcpBindingsProvider).asData?.value ??
        const <XiaozhiMcpBindingItem>[];
    final hadMac = existing.any(
      (e) => _normMac(e.speakerMac) == _normMac(result.speakerMac),
    );

    try {
      await ref.read(xiaozhiMcpBindingRepositoryProvider).add(
            mcpToken: result.mcpToken,
            speakerMac: result.speakerMac,
            alias: result.alias,
          );
      if (!mounted) return;
      ref.showApiToast(
        hadMac ? '已更新该音箱接入点' : '已添加音箱',
        tone: AppToastTone.success,
      );
      await _refreshAll();
    } on ApiBusinessException {
      // 仓库已 toast
    } catch (_) {
      if (mounted) ref.showApiToastError('添加失败，请稍后重试');
    }
  }

  Future<void> _editAlias(XiaozhiMcpBindingItem item) async {
    final next = await showGlassDialog<String>(
      context: context,
      maxWidth: 340,
      contentBuilder: (ctx) => _AliasEditDialogBody(initialAlias: item.alias),
    );
    if (next == null || !mounted) return;
    final name = next.trim();
    if (name.isEmpty) {
      ref.showApiToast('备注不能为空');
      return;
    }
    try {
      await ref
          .read(xiaozhiMcpBindingRepositoryProvider)
          .updateAlias(id: item.id, alias: name);
      if (!mounted) return;
      ref.showApiToast('备注已更新', tone: AppToastTone.success);
      ref.invalidate(xiaozhiMcpBindingsProvider);
    } on ApiBusinessException {
      // toasted
    } catch (_) {
      if (mounted) ref.showApiToastError('更新失败');
    }
  }

  Future<void> _deleteBinding(XiaozhiMcpBindingItem item) async {
    final go = await showGlassConfirmDialog(
          context,
          title: '删除音箱？',
          message: '将解除「${item.alias}」的绑定，音箱将无法再经本账号录入喂养。',
          confirmLabel: '删除',
        ) ??
        false;
    if (!go || !mounted) return;
    try {
      await ref.read(xiaozhiMcpBindingRepositoryProvider).delete(item.id);
      if (!mounted) return;
      ref.showApiToast('已删除', tone: AppToastTone.success);
      ref.invalidate(xiaozhiMcpBindingsProvider);
    } on ApiBusinessException {
      // toasted
    } catch (_) {
      if (mounted) ref.showApiToastError('删除失败');
    }
  }

  String _unlockHeadline(XiaozhiMcpUnlockView v) {
    if (v.isPermanent) return '已永久开通';
    if (v.isTrialActive) {
      final end = DateTime.fromMillisecondsSinceEpoch(v.expiresAt * 1000);
      return '体验中 · 至 ${DateFormat('MM/dd HH:mm').format(end)}';
    }
    if (v.trialAvailable) return '可免费体验 24 小时';
    return '体验已用完';
  }

  String _unlockSub(XiaozhiMcpUnlockView v) {
    if (v.isPermanent) return '可添加多台小智音箱，对话即可录入喂养。';
    if (v.isTrialActive) {
      return '体验结束后首次对话可能断开连接；开通永久后可继续使用。';
    }
    if (v.trialAvailable) {
      return '添加第一台音箱时自动开始体验，每账号仅一次。';
    }
    return '开通永久能力后可继续添加音箱。';
  }

  @override
  Widget build(BuildContext context) {
    final unlockAsync = ref.watch(xiaozhiMcpUnlockProvider);
    final bindingsAsync = ref.watch(xiaozhiMcpBindingsProvider);
    final deviceNo =
        ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
    final hasBaby = deviceNo.isNotEmpty;

    final tokens = visualTokensOf(context);
    final scheme = Theme.of(context).colorScheme;
    final onShell = tokens?.onShell ?? AppColor.textPrimary(context);
    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd =
        Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('小智音箱'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      // 硬件自购前提：与开通/绑定正交；? 进购买说明（群 QR）。
                      SettingsGlassPanel(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '使用绑定功能前，请自行采购小智音箱。App 提供开通与绑定，不包含硬件。',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: onShell.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '如何购买',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: Icon(
                                Icons.help_outline,
                                size: 20,
                                color: scheme.primary,
                              ),
                              onPressed: () => context
                                  .push('/settings/xiaozhi-speaker/howto-buy'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 效果说明：绑定 MCP 后能做什么（与自购/开通态分离）。
                      SettingsGlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '绑定后可以做什么',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: onShell,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '绑定小智音箱并完成开通后，你可以直接对音箱说话记录宝宝喂养（吃奶、辅食等），记录会同步到当前绑定的宝宝账号，无需每次打开手机 App。',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: onShell.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      unlockAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => SettingsGlassPanel(
                          child: Text(
                            '开通态加载失败，下拉重试',
                            style: TextStyle(color: onShell),
                          ),
                        ),
                        data: (unlock) {
                          final product = unlock.product;
                          final showPay = product != null &&
                              product.isOnSale &&
                              !unlock.isPermanent;
                          return SettingsGlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _unlockHeadline(unlock),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: onShell,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _unlockSub(unlock),
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: onShell.withValues(alpha: 0.75),
                                  ),
                                ),
                                if (showPay) ...[
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: _paying
                                        ? null
                                        : () => _purchasePermanent(product),
                                    style: FilledButton.styleFrom(
                                      foregroundColor:
                                          AppColor.onPrimary(context),
                                    ),
                                    child: _paying
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color:
                                                  AppColor.onPrimary(context),
                                            ),
                                          )
                                        : _PermanentPayButtonLabel(
                                            priceFen: product.priceFen,
                                            originalPriceFen:
                                                product.originalPriceFen,
                                            onPrimary:
                                                AppColor.onPrimary(context),
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      if (!hasBaby) ...[
                        const SizedBox(height: 12),
                        SettingsGlassPanel(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '尚未绑定宝宝，添加音箱前请先绑机。',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: onShell.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/settings/bind-baby'),
                                child: const Text('去绑机'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        '已绑定音箱',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onShell,
                        ),
                      ),
                      const SizedBox(height: 8),
                      bindingsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => SettingsGlassPanel(
                          child: Text(
                            '列表加载失败，下拉重试',
                            style: TextStyle(color: onShell),
                          ),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return SettingsGlassPanel(
                              child: XiaozhiConsoleLinkedText(
                                leading: '还没有绑定音箱。从「',
                                trailing: '」复制 MAC 与 MCP 接入点后添加。',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: onShell.withValues(alpha: 0.8),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _BindingCard(
                                  item: items[i],
                                  onShell: onShell,
                                  onEditAlias: () => _editAlias(items[i]),
                                  onDelete: () => _deleteBinding(items[i]),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: unlockAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => FilledButton.icon(
                    onPressed: () => _onAddTap(
                      unlock: const XiaozhiMcpUnlockView(
                        unlocked: false,
                        trialAvailable: false,
                      ),
                      hasBaby: hasBaby,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('添加音箱'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColor.onPrimary(context),
                    ),
                  ),
                  data: (unlock) {
                    final disabledLook = !unlock.canAdd || !hasBaby;
                    return FilledButton.icon(
                      onPressed: () =>
                          _onAddTap(unlock: unlock, hasBaby: hasBaby),
                      icon: const Icon(Icons.add),
                      label: Text(
                        !hasBaby
                            ? '添加音箱（需先绑机）'
                            : (!unlock.canAdd
                                ? '添加音箱（需先开通）'
                                : '添加音箱'),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColor.onPrimary(context),
                        backgroundColor: disabledLook
                            ? scheme.primary.withValues(alpha: 0.55)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 永久开通钮文案：现价 + 可选划线原价（原价须大于现价）。
class _PermanentPayButtonLabel extends StatelessWidget {
  const _PermanentPayButtonLabel({
    required this.priceFen,
    required this.originalPriceFen,
    required this.onPrimary,
  });

  final int priceFen;
  final int originalPriceFen;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    final showOrig = originalPriceFen > priceFen;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '永久开通 ¥${formatVipFenYuan(priceFen)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: onPrimary,
          ),
        ),
        if (showOrig) ...[
          const SizedBox(width: 8),
          Text(
            '¥${formatVipFenYuan(originalPriceFen)}',
            style: TextStyle(
              fontSize: 12,
              color: onPrimary.withValues(alpha: 0.65),
              decoration: TextDecoration.lineThrough,
              decorationColor: onPrimary.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}

class _BindingCard extends StatelessWidget {
  const _BindingCard({
    required this.item,
    required this.onShell,
    required this.onEditAlias,
    required this.onDelete,
  });

  final XiaozhiMcpBindingItem item;
  final Color onShell;
  final VoidCallback onEditAlias;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // 连接态仅绿/红两态（非主题正文色）。
    final dot = item.connected
        ? const Color(0xFF34C759)
        : Theme.of(context).colorScheme.error;
    return SettingsGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.alias,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onShell,
                  ),
                ),
              ),
              Text(
                item.connected ? '已连接' : '未连接',
                style: TextStyle(
                  fontSize: 12,
                  color: onShell.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'MAC  ${item.speakerMac}',
            style: TextStyle(
              fontSize: 13,
              color: onShell.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Token  ${item.tokenMask}',
            style: TextStyle(
              fontSize: 13,
              color: onShell.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: onEditAlias, child: const Text('改备注')),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBindingResult {
  const _AddBindingResult({
    required this.alias,
    required this.speakerMac,
    required this.mcpToken,
  });

  final String alias;
  final String speakerMac;
  final String mcpToken;
}

/// 添加表单：controller 由弹层 State 持有。
class _AddBindingDialogBody extends StatefulWidget {
  const _AddBindingDialogBody({
    required this.needTrialConfirm,
    required this.onHelpMac,
    required this.onHelpToken,
  });

  final bool needTrialConfirm;
  final VoidCallback onHelpMac;
  final VoidCallback onHelpToken;

  @override
  State<_AddBindingDialogBody> createState() => _AddBindingDialogBodyState();
}

class _AddBindingDialogBodyState extends State<_AddBindingDialogBody> {
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _macCtrl;
  late final TextEditingController _tokenCtrl;
  bool _submitting = false;
  /// 弹层内可见；根 SnackBar 会被 dialog 挡住。
  String? _formError;

  @override
  void initState() {
    super.initState();
    _aliasCtrl = TextEditingController();
    _macCtrl = TextEditingController();
    _tokenCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _macCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  void _clearFormError() {
    if (_formError == null) return;
    setState(() => _formError = null);
  }

  Future<void> _submit() async {
    final alias = _aliasCtrl.text.trim();
    final mac = _macCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    if (alias.isEmpty || mac.isEmpty || token.isEmpty) {
      setState(() => _formError = '请填完整：备注名、音箱 MAC、MCP 接入点');
      return;
    }
    if (widget.needTrialConfirm) {
      final go = await showGlassConfirmDialog(
            context,
            title: '开始免费体验？',
            message: '添加后将开始 24 小时免费体验，每账号仅一次。确认继续？',
            confirmLabel: '开始体验并添加',
          ) ??
          false;
      if (!go || !mounted) return;
    }
    if (!mounted) return;
    setState(() {
      _formError = null;
      _submitting = true;
    });
    Navigator.pop(
      context,
      _AddBindingResult(alias: alias, speakerMac: mac, mcpToken: token),
    );
  }

  Widget _labelWithHelp({
    required String label,
    required VoidCallback onHelp,
    required Color textColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        IconButton(
          tooltip: '查看说明',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(Icons.help_outline, size: 18, color: textColor),
          onPressed: onHelp,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '添加小智音箱',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: glassText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '备注名',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: glassLabel,
            ),
          ),
          TextField(
            controller: _aliasCtrl,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearFormError(),
            decoration: InputDecoration(
              hintText: '如：客厅音箱',
              hintStyle: TextStyle(color: glassLabel.withValues(alpha: 0.5)),
            ),
            style: TextStyle(color: glassText),
          ),
          const SizedBox(height: 8),
          _labelWithHelp(
            label: '音箱 MAC',
            textColor: glassLabel,
            onHelp: widget.onHelpMac,
          ),
          TextField(
            controller: _macCtrl,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearFormError(),
            decoration: InputDecoration(
              hintText: '3c:dc:75:fc:7f:c4',
              hintStyle: TextStyle(color: glassLabel.withValues(alpha: 0.5)),
            ),
            style: TextStyle(color: glassText),
          ),
          const SizedBox(height: 8),
          _labelWithHelp(
            label: '小智 MCP 接入点',
            textColor: glassLabel,
            onHelp: widget.onHelpToken,
          ),
          TextField(
            controller: _tokenCtrl,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => _clearFormError(),
            decoration: InputDecoration(
              hintText: '可粘贴 wss://…/mcp/?token=…',
              hintStyle: TextStyle(color: glassLabel.withValues(alpha: 0.5)),
            ),
            style: TextStyle(color: glassText, fontSize: 13),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 10),
            Text(
              _formError!,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: scheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed:
                    _submitting ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: glassLabel),
                child: const Text('取消'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: AppColor.onPrimary(context),
                ),
                child: const Text('添加'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 改备注：controller 由弹层 State 持有。
class _AliasEditDialogBody extends StatefulWidget {
  const _AliasEditDialogBody({required this.initialAlias});

  final String initialAlias;

  @override
  State<_AliasEditDialogBody> createState() => _AliasEditDialogBodyState();
}

class _AliasEditDialogBodyState extends State<_AliasEditDialogBody> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialAlias);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '修改备注',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: glassText,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '备注名',
            hintStyle: TextStyle(color: glassLabel.withValues(alpha: 0.5)),
          ),
          style: TextStyle(color: glassText),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: glassLabel),
              child: const Text('取消'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context, _ctrl.text),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: AppColor.onPrimary(context),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ],
    );
  }
}
