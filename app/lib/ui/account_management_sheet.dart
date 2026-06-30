import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../apple/apple_sign_in_client.dart';
import '../providers/home_history_notifier.dart';
import '../bootstrap/gateway_bootstrap_gate.dart';
import '../providers/repositories.dart';
import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';
import '../providers/sign_in_channel_provider.dart';
import '../providers/toast_bus.dart';
import '../providers/user_profile_provider.dart';
import '../providers/wechat_auth_provider.dart';
import '../router/app_router.dart';
import '../session/credential_history_store.dart';
import '../wechat/wechat_auth_exception.dart';
import 'account_bind_messages.dart';
import 'home_history_edit_glass_panel.dart';
import 'widgets/app_glass_overlay.dart';

Future<void> showAccountManagementSheet(
    BuildContext context, WidgetRef ref) async {
  ref.invalidate(userProfileProvider);

  await showGlassAdaptiveBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.55,
    showDragHandle: true,
    onClose: () => Navigator.of(context).pop(),
    bodyBuilder: (sheetCtx) => _AccountManagementSheetBody(
      sheetCtx: sheetCtx,
      hostContext: context,
    ),
  );
}

class _AccountManagementSheetBody extends ConsumerStatefulWidget {
  const _AccountManagementSheetBody({
    required this.sheetCtx,
    required this.hostContext,
  });

  final BuildContext sheetCtx;
  final BuildContext hostContext;

  @override
  ConsumerState<_AccountManagementSheetBody> createState() =>
      _AccountManagementSheetBodyState();
}

class _AccountManagementSheetBodyState
    extends ConsumerState<_AccountManagementSheetBody> {
  var _bindingWx = false;
  var _bindingApple = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final scheme = Theme.of(context).colorScheme;

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _buildProfileLoadErrorContent(
        error: e,
        glassText: glassText,
        glassLabel: glassLabel,
      ),
      data: (profile) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSheetTitle(glassText),
          const SizedBox(height: 16),
          if (profile.hasAccount)
            _AccountActionTile(
              icon: Icons.password,
              title: '修改密码',
              glassText: glassText,
              onTap: () {
                Navigator.of(widget.sheetCtx).pop();
                widget.hostContext.push('/settings/change-password');
              },
            ),
          if (profile.isAppleBound)
            _AccountActionTile(
              icon: Icons.apple,
              title: '已绑定 Apple',
              glassText: glassLabel.withValues(alpha: 0.7),
              enabled: false,
            )
          else
            _AccountActionTile(
              icon: Icons.apple,
              title: _bindingApple ? '绑定中…' : '绑定 Apple',
              glassText: glassText,
              enabled: !_bindingApple && !_bindingWx,
              onTap: (_bindingApple || _bindingWx)
                  ? null
                  : () => _bindApple(context),
            ),
          if (profile.isWxBound)
            _AccountActionTile(
              icon: Icons.chat,
              title: '已绑定微信',
              glassText: glassLabel.withValues(alpha: 0.7),
              enabled: false,
            )
          else
            _AccountActionTile(
              icon: Icons.chat,
              title: _bindingWx ? '绑定中…' : '绑定微信',
              glassText: glassText,
              enabled: !_bindingWx && !_bindingApple,
              onTap: (_bindingWx || _bindingApple)
                  ? null
                  : () => _bindWeChat(context),
            ),
          Divider(color: glassLabel.withValues(alpha: 0.2), height: 24),
          _buildSwitchAccountTile(glassText),
          _AccountActionTile(
            icon: Icons.delete_forever,
            title: '注销账户',
            glassText: glassText,
            onTap: () => _deregister(),
          ),
          if (_bindingWx || _bindingApple)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: scheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSheetTitle(Color glassText) {
    return Text(
      '账号管理',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: glassText,
      ),
    );
  }

  String _profileLoadErrorMessage(Object error) {
    if (error is ApiHttpException) {
      return '网络异常，请检查网络后重试';
    }
    if (error is ApiBusinessException) {
      return error.message;
    }
    if (error is SocketException || error is IOException) {
      return '网络异常，请检查网络后重试';
    }
    return '加载账号信息失败，请稍后重试';
  }

  Widget _buildProfileLoadErrorContent({
    required Object error,
    required Color glassText,
    required Color glassLabel,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSheetTitle(glassText),
        const SizedBox(height: 16),
        Text(
          _profileLoadErrorMessage(error),
          textAlign: TextAlign.center,
          style: TextStyle(color: glassLabel, fontSize: 14),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => ref.invalidate(userProfileProvider),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            shape: const StadiumBorder(),
          ),
          child: const Text('重试'),
        ),
        const SizedBox(height: 8),
        Divider(color: glassLabel.withValues(alpha: 0.2), height: 24),
        _buildSwitchAccountTile(glassText),
      ],
    );
  }

  Widget _buildSwitchAccountTile(Color glassText) {
    return _AccountActionTile(
      icon: Icons.swap_horiz,
      title: '切换账号',
      glassText: glassText,
      onTap: () => _switchAccount(),
    );
  }

  Future<void> _bindWeChat(BuildContext context) async {
    setState(() => _bindingWx = true);
    try {
      final client = ref.read(weChatAuthClientProvider);
      if (client == null) {
        ref.showApiToastError('当前环境不支持微信授权');
        return;
      }
      final code = await client.obtainWxCode();
      await ref.read(authRepositoryProvider).bindWx(jsCode: code);
      ref.invalidate(userProfileProvider);
      if (!context.mounted) return;
      await showGlassDialog<void>(
        context: context,
        contentBuilder: (ctx) {
          final text = historyEditGlassTextColor(ctx);
          final label = historyEditGlassLabelColor(ctx);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '绑定成功',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, color: text),
              ),
              const SizedBox(height: 12),
              Text(
                '绑定微信账号成功',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: label),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.primary,
                  minimumSize: const Size(double.infinity, 44),
                  shape: const StadiumBorder(),
                ),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    } on WeChatAuthCanceledException {
      ref.showApiToast('已取消微信授权');
    } on WeChatAuthException catch (e) {
      ref.showApiToastError(e.message);
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(bindConflictMessage(e));
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } catch (e) {
      ref.showApiToastError('绑定失败：$e');
    } finally {
      if (mounted) setState(() => _bindingWx = false);
    }
  }

  Future<void> _bindApple(BuildContext context) async {
    setState(() => _bindingApple = true);
    try {
      final identityToken = await obtainAppleIdentityToken();
      await ref
          .read(authRepositoryProvider)
          .bindApple(identityToken: identityToken);
      ref.invalidate(userProfileProvider);
      if (!context.mounted) return;
      await showGlassDialog<void>(
        context: context,
        contentBuilder: (ctx) {
          final text = historyEditGlassTextColor(ctx);
          final label = historyEditGlassLabelColor(ctx);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '绑定成功',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, color: text),
              ),
              const SizedBox(height: 12),
              Text(
                '绑定 Apple 账号成功',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: label),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.primary,
                  minimumSize: const Size(double.infinity, 44),
                  shape: const StadiumBorder(),
                ),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(bindConflictMessage(e));
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } catch (e) {
      ref.showApiToastError('绑定失败：$e');
    } finally {
      if (mounted) setState(() => _bindingApple = false);
    }
  }

  Future<void> _switchAccount() async {
    final ok = await showGlassConfirmDialog(
          widget.hostContext,
          title: '切换账号',
          message: '将清除本地会话、宝宝ID与历史记录缓存并返回登录页。',
          useRootNavigator: false,
        ) ??
        false;
    if (!ok) return;

    if (Navigator.of(widget.sheetCtx).canPop()) {
      Navigator.of(widget.sheetCtx).pop();
    }

    try {
      await ref.read(authRepositoryProvider).signOut();
    } finally {
      ref.read(feedRepositoryProvider).disconnectHistoryWebSocket();
      GatewayBootstrapGate.reset();
      await ref.read(sessionProvider).signOut();
      await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
      await ref.read(signInChannelProvider.notifier).clear();
      await ref.read(feedRepositoryProvider).clearCache();
      // await ref.read(homeHistoryProvider.notifier).refreshFromRemote();// 切换账号时，不刷新历史记录, 防止刷新时会话已过期导致自动刷新
      ref.read(goRouterProvider).go('/login');
    }
  }

  Future<void> _deregister() async {
    await confirmAccountDeregistration(
      widget.hostContext,
      ref,
      closeSheet: () {
        if (Navigator.of(widget.sheetCtx).canPop()) {
          Navigator.of(widget.sheetCtx).pop();
        }
      },
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.glassText,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final Color glassText;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: enabled ? primary : glassText, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: glassText,
                  ),
                ),
              ),
              if (enabled && onTap != null)
                Icon(Icons.chevron_right,
                    size: 20, color: glassText.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> confirmAccountDeregistration(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? closeSheet,
}) async {
  final dialogContext = context;
  final step1 = await showGlassConfirmDialog(
        dialogContext,
        title: '注销账户',
        message: '第一步：确认你了解此操作的风险。该操作不可撤销，你的所有记录将被永久删除。',
        confirmLabel: '继续',
        useRootNavigator: false,
      ) ??
      false;
  if (!step1) return;

  final step2 = await showGlassTextConfirmDialog(
        dialogContext,
        title: '注销确认',
        message: '第二步：请输入“确定注销”以继续申请。',
        expectedText: '确定注销',
        confirmLabel: '确认注销',
        useRootNavigator: false,
      ) ??
      false;
  if (!step2) return;

  closeSheet?.call();

  try {
    final profile = await ref.read(authRepositoryProvider).fetchUserProfile();
    await ref.read(authRepositoryProvider).deactivateAccount();
    if (profile.account.isNotEmpty) {
      await removeAccount(profile.account);
    }
    await ref.read(sessionProvider).signOut();
    await ref.read(deviceNoNotifierProvider.notifier).clearLocal();
    await ref.read(signInChannelProvider.notifier).clear();
    await ref.read(feedRepositoryProvider).clearCache();
    await ref.read(homeHistoryProvider.notifier).refreshFromRemote();

    ref.read(goRouterProvider).go('/login');
    ref.showApiToast('注销成功');
  } catch (e) {
    ref.showApiToastError('注销失败：$e');
  }
}
