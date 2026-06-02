import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exceptions.dart';
import '../config/env.dart';
import '../providers/device_no_notifier.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../providers/session_provider.dart';
import '../providers/toast_bus.dart';
import '../session/credential_history_store.dart';
import '../theme/app_theme_scope.dart';
import '../theme/theme_bootstrap_cache.dart';
import 'auth/auth_ui.dart';
import 'widgets/keyboard_input_bridge.dart';
import '../wechat/wechat_web_redirect.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final RegExp _accountPattern = RegExp(r'^[a-z0-9_]{4,32}$');

  final _accountFieldKey = GlobalKey();
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _accountFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  var _loading = false;
  var _resumedPendingWebLogin = false;
  var _obscurePassword = true;
  List<CredentialEntry> _credentialEntries = const [];
  String? _accountError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _accountFocusNode.addListener(_onAccountFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyPrefillAccountFromRoute();
      _loadCredentialEntries();
      _showPendingWebWeChatError();
      _resumePendingWebWeChatLogin();
    });
  }

  void _applyPrefillAccountFromRoute() {
    final account = GoRouterState.of(context).uri.queryParameters['account']?.trim();
    if (account == null || account.isEmpty) return;
    _accountCtrl.text = account.trim().toLowerCase();
    _accountError = null;
  }

  @override
  void dispose() {
    _accountFocusNode.removeListener(_onAccountFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _accountFocusNode.dispose();
    _passwordFocusNode.dispose();
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onAccountFocusChange() {
    if (_accountFocusNode.hasFocus) {
      keyboardInputBridgeController.attach(
        controller: _accountCtrl,
        focusNode: _accountFocusNode,
        onConfirm: () => _passwordFocusNode.requestFocus(),
        scene: 'login.account',
        hint: '账号',
      );
      return;
    }
    keyboardInputBridgeController.detach(controller: _accountCtrl);
  }

  void _onPasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) {
      keyboardInputBridgeController.attach(
        controller: _passwordCtrl,
        focusNode: _passwordFocusNode,
        onConfirm: _onUsernameLogin,
        scene: 'login.password',
        obscureText: true,
        hint: '密码',
      );
      return;
    }
    keyboardInputBridgeController.detach(controller: _passwordCtrl);
  }

  String _normalizeAccount(String raw) => raw.trim().toLowerCase();

  Future<void> _loadCredentialEntries() async {
    try {
      final entries = await loadCredentialEntries();
      if (!mounted) return;
      setState(() {
        _credentialEntries = entries;
      });
    } catch (_) {
      // 读取失败时保留现有列表，避免箭头闪烁消失。
    }
  }

  void _applyCredentialEntry(CredentialEntry entry) {
    _accountCtrl.value = TextEditingValue(
      text: entry.account,
      selection: TextSelection.collapsed(offset: entry.account.length),
    );
    _passwordCtrl.value = TextEditingValue(
      text: entry.password ?? '',
      selection: TextSelection.collapsed(offset: (entry.password ?? '').length),
    );
    setState(() {
      _accountError = null;
      _passwordError = null;
    });
    final binding = keyboardInputBridgeController.binding;
    if (binding == null) return;
    if (binding.controller == _accountCtrl) {
      keyboardInputBridgeController.updateDraft(entry.account);
    } else if (binding.controller == _passwordCtrl) {
      keyboardInputBridgeController.updateDraft(entry.password ?? '');
    }
  }

  Future<void> _showCredentialPicker() async {
    if (_loading) return;

    final entries = await loadCredentialEntries();
    if (!mounted) return;
    if (entries.isEmpty) {
      setState(() => _credentialEntries = const []);
      return;
    }
    setState(() => _credentialEntries = entries);

    final box = _accountFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;

    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      color: const Color(0xFFFBF8F3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF8C7E74).withValues(alpha: 0.35)),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        offset.dy + box.size.height + 4,
      ),
      items: entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.account,
              child: Text(
                entry.account,
                style: const TextStyle(color: Color(0xFF4A3428), fontSize: 15),
              ),
            ),
          )
          .toList(),
    );
    if (selected == null || !mounted) return;

    final password = await readPasswordForAccount(selected);
    if (!mounted) return;
    _applyCredentialEntry(CredentialEntry(account: selected, password: password));
  }

  bool _validateCredentialInputs() {
    final account = _normalizeAccount(_accountCtrl.text);
    final password = _passwordCtrl.text;
    String? accountError;
    String? passwordError;
    if (!_accountPattern.hasMatch(account)) {
      accountError = '账号需 4-32 位，仅支持 a-z、0-9、_';
    }
    if (password.length < 6 || password.length > 64) {
      passwordError = '密码长度需为 6-64 位';
    }
    setState(() {
      _accountError = accountError;
      _passwordError = passwordError;
    });
    return accountError == null && passwordError == null;
  }

  Future<void> _onUsernameLogin() async {
    if (_loading) return;
    if (!_validateCredentialInputs()) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final normalized = _normalizeAccount(_accountCtrl.text);
      await auth.signInWithUsernamePassword(
        normalized,
        _passwordCtrl.text,
      );
      if (!mounted) return;
      await _loadCredentialEntries();
      if (!mounted) return;
      await _afterLoginSuccess();
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _afterLoginSuccess() async {
    await ref.read(deviceNoNotifierProvider.notifier).refresh();
    ref.invalidate(settingsBabyProvider);
    final baby = await ref.read(settingsRepositoryProvider).loadBaby();
    ref.read(babySexProvider.notifier).state = baby.sex;
    await persistCachedBabySex(baby.sex);
    if (mounted) context.go('/home');
  }

  bool get _canRedirectWebWeChatAuthorize {
    return kIsWeb && AppEnv.wechatOAuthRedirectUri.isNotEmpty && AppEnv.wechatWebAppIdEffective.isNotEmpty;
  }

  Future<void> _resumePendingWebWeChatLogin() async {
    if (!kIsWeb || _resumedPendingWebLogin || !hasPendingWeChatWebCode()) return;
    _resumedPendingWebLogin = true;
    await _onWeChatLogin();
  }

  void _showPendingWebWeChatError() {
    if (!kIsWeb) return;
    final err = consumeWeChatOAuthCallbackError();
    if (err == null || err.isEmpty) return;
    final message = switch (err) {
      'access_denied' => '已取消微信授权',
      'state_mismatch' => '授权状态校验失败，请重试',
      'missing_code' => '未收到微信授权码',
      _ => '微信授权失败：$err',
    };
    ref.showApiToastError(message);
  }

  Future<void> _onWeChatLogin() async {
    if (_loading) return;
    if (_canRedirectWebWeChatAuthorize && !hasPendingWeChatWebCode()) {
      try {
        redirectToWeChatWebAuthorize();
      } on StateError catch (e) {
        ref.showApiToastError(e.message);
      } catch (e) {
        ref.showApiToastError('无法发起微信授权：$e');
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.signInWithWeChat();
      if (!mounted) return;
      await _afterLoginSuccess();
    } on ApiBusinessException catch (e) {
      ref.showApiToastError(e.message);
    } on ApiHttpException catch (e) {
      ref.showApiToastError('网络错误(${e.statusCode})');
    } catch (_) {
      ref.showApiToastError('微信登录暂不可用，请检查 WECHAT_APP_ID、WECHAT_UNIVERSAL_LINK 与 iOS Associated Domains 配置');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegisterScreen() async {
    if (_loading) return;
    final result = await context.push<Map<String, String>>('/register');
    if (!mounted || result == null) return;

    final account = result['account']?.trim() ?? '';
    final password = result['password'] ?? '';
    if (account.isEmpty || password.isEmpty) return;

    setState(() {
      _accountCtrl.text = account;
      _passwordCtrl.text = password;
      _accountError = null;
      _passwordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (previous, next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadCredentialEntries();
        });
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFBF8F3), // 浅米色/大理石底色
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      buildAuthBrandHeader(context),
                      const SizedBox(height: 20),
                      TextField(
                        key: _accountFieldKey,
                        controller: _accountCtrl,
                        focusNode: _accountFocusNode,
                        enabled: !_loading,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        onTap: _onAccountFocusChange,
                        onChanged: keyboardInputBridgeController.updateDraft,
                        decoration: buildAuthInputDecoration(
                          labelText: '账号',
                          hintText: '4-32 位，仅 a-z0-9_',
                          errorText: _accountError,
                          suffixIcon: _credentialEntries.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _loading ? null : _showCredentialPicker,
                                  icon: const Icon(Icons.arrow_drop_down),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocusNode,
                        enabled: !_loading,
                        obscureText: _obscurePassword,
                        onTap: _onPasswordFocusChange,
                        onChanged: keyboardInputBridgeController.updateDraft,
                        onSubmitted: (_) => _onUsernameLogin(),
                        decoration: buildAuthInputDecoration(
                          labelText: '密码',
                          hintText: '6-64 位',
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _onUsernameLogin,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('账号密码登录'),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _openRegisterScreen,
                          child: const Text('注册账号'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('或', style: Theme.of(context).textTheme.bodySmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _onWeChatLogin,
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('微信登录'),
                      ),
                      const SizedBox(height: 12),
                      buildAuthPrivacyAgreement(
                        context,
                        leadText: '登录即代表您已阅读并同意',
                        onTapUserAgreement: () => context.push(
                          Uri(path: '/policy', queryParameters: {'url': AppEnv.userAgreementUrl}).toString(),
                        ),
                        onTapPrivacyPolicy: () => context.push(
                          Uri(path: '/policy', queryParameters: {'url': AppEnv.privacyPolicyUrl}).toString(),
                        ),
                      ),
                      const Spacer(),
                      if (AppEnv.wxLoginCode.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '开发模式已开启',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
