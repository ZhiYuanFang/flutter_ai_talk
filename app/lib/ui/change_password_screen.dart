import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
import '../providers/user_profile_provider.dart';
import '../session/credential_history_store.dart';
import '../theme/app_visual_tokens.dart';
import 'auth/auth_field_scroll.dart';
import 'auth/auth_ui.dart';
import 'widgets/keyboard_lift.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _oldFocus = FocusNode();
  final _newFocus = FocusNode();
  final _oldFieldKey = GlobalKey();
  final _newFieldKey = GlobalKey();
  final _scrollCtrl = ScrollController();
  var _busy = false;
  var _obscureOld = true;
  var _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _oldFocus.addListener(_scrollOldIntoView);
    _newFocus.addListener(_scrollNewIntoView);
  }

  void _scrollOldIntoView() {
    if (!mounted) return;
    scrollInlineAuthFieldIntoView(
      _oldFocus,
      context: context,
      scrollController: _scrollCtrl,
      anchorKey: _oldFieldKey,
    );
  }

  void _scrollNewIntoView() {
    if (!mounted) return;
    scrollInlineAuthFieldIntoView(
      _newFocus,
      context: context,
      scrollController: _scrollCtrl,
      anchorKey: _newFieldKey,
    );
  }

  GlobalKey? get _focusedAuthAnchor {
    if (_oldFocus.hasFocus) return _oldFieldKey;
    if (_newFocus.hasFocus) return _newFieldKey;
    return null;
  }

  FocusNode? get _focusedAuthField {
    if (_oldFocus.hasFocus) return _oldFocus;
    if (_newFocus.hasFocus) return _newFocus;
    return null;
  }

  @override
  void dispose() {
    _oldFocus.removeListener(_scrollOldIntoView);
    _newFocus.removeListener(_scrollNewIntoView);
    _oldFocus.dispose();
    _newFocus.dispose();
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final oldPw = _oldCtrl.text;
    final newPw = _newCtrl.text;
    if (oldPw.isEmpty || newPw.isEmpty) {
      ref.showApiToastError('请填写旧密码与新密码');
      return;
    }
    if (newPw.length < 6 || newPw.length > 64) {
      ref.showApiToastError('新密码长度需为 6-64 位');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).changeUsernamePassword(
            oldPassword: oldPw,
            newPassword: newPw,
          );
      final profile = await ref.read(authRepositoryProvider).fetchUserProfile();
      final account = profile.account;
      await removePassword(account);
      await ref.read(sessionProvider).signOut();
      if (!mounted) return;
      ref.showApiToast('密码修改成功，请重新登录');
      if (account.isNotEmpty) {
        context.go('/login?account=${Uri.encodeComponent(account)}');
      } else {
        context.go('/login');
      }
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } catch (e) {
      ref.showApiToastError('修改失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final tokens = visualTokensOf(context);
    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd = Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;
    final onShell = tokens?.onShell ?? scheme.onSurface;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('修改密码'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : () => context.pop(),
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
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e', style: TextStyle(color: onShell))),
            data: (profile) {
              if (!profile.hasAccount) {
                return Center(
                  child: Text('当前账号不支持修改密码', style: TextStyle(color: onShell)),
                );
              }
              scheduleInlineAuthScrollOnInset(
                context,
                focusedNode: _focusedAuthField,
                scrollController: _scrollCtrl,
                anchorKey: _focusedAuthAnchor,
              );
              return ListView(
                controller: _scrollCtrl,
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
                children: [
                  _ChangePasswordGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '当前账号',
                          style: TextStyle(
                            fontSize: 13,
                            color: onShell.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile.account,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: onShell,
                          ),
                        ),
                        const SizedBox(height: 20),
                        keyboardLiftTarget(
                          focusNode: _oldFocus,
                          anchorKey: _oldFieldKey,
                          child: TextField(
                            controller: _oldCtrl,
                            focusNode: _oldFocus,
                            enabled: !_busy,
                            obscureText: _obscureOld,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _newFocus.requestFocus(),
                            decoration: buildAuthInputDecoration(
                              labelText: '旧密码',
                              suffixIcon: IconButton(
                                onPressed: _busy ? null : () => setState(() => _obscureOld = !_obscureOld),
                                icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        keyboardLiftTarget(
                          focusNode: _newFocus,
                          anchorKey: _newFieldKey,
                          child: TextField(
                            controller: _newCtrl,
                            focusNode: _newFocus,
                            enabled: !_busy,
                            obscureText: _obscureNew,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: buildAuthInputDecoration(
                              labelText: '新密码',
                              hintText: '6-64 位',
                              suffixIcon: IconButton(
                                onPressed: _busy ? null : () => setState(() => _obscureNew = !_obscureNew),
                                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: scheme.primary,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('确认修改'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordGlassPanel extends StatelessWidget {
  const _ChangePasswordGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = visualTokensOf(context);
    final isDark = tokens?.isDarkShell ?? (theme.brightness == Brightness.dark);
    final base = tokens?.surfaceColor ?? scheme.surface;
    final top = Color.alphaBlend(Colors.white.withValues(alpha: isDark ? 0.06 : 0.20), base);
    final bottom = Color.alphaBlend(scheme.primary.withValues(alpha: isDark ? 0.16 : 0.10), base);
    final borderColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.22 : 0.55),
      scheme.outline.withValues(alpha: isDark ? 0.10 : 0.08),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [top, bottom],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: child,
          ),
        ),
      ),
    );
  }
}
