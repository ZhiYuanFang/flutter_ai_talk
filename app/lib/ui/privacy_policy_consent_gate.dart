import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/env.dart';
import '../config/privacy_policy_consent_store.dart';
import '../theme/app_color.dart';

/// 首启隐私门闩：无标题 WebView + 底栏同意/退出。
class PrivacyPolicyConsentGate extends StatefulWidget {
  const PrivacyPolicyConsentGate({
    super.key,
    required this.onAccepted,
  });

  /// 已写入本地同意后回调，由宿主继续冷启动。
  final VoidCallback onAccepted;

  @override
  State<PrivacyPolicyConsentGate> createState() =>
      _PrivacyPolicyConsentGateState();
}

class _PrivacyPolicyConsentGateState extends State<PrivacyPolicyConsentGate> {
  WebViewController? _controller;
  var _loading = true;
  var _loadFailed = false;
  var _accepting = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    } else {
      _loading = false;
    }
  }

  void _initWebView() {
    final uri = Uri.tryParse(AppEnv.privacyPolicyUrl) ??
        Uri.parse(AppEnv.privacyPolicyUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _loadFailed = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadFailed = false;
            });
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadFailed = true;
            });
          },
        ),
      )
      ..loadRequest(uri);
  }

  void _retry() {
    if (kIsWeb) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    _controller?.loadRequest(
      Uri.tryParse(AppEnv.privacyPolicyUrl) ??
          Uri.parse(AppEnv.privacyPolicyUrl),
    );
  }

  Future<void> _onDecline() async {
    // 不同意：不写同意，直接退出进程。
    await SystemNavigator.pop();
  }

  Future<void> _onAccept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      await PrivacyPolicyConsentStore.saveAccepted();
      if (!mounted) return;
      widget.onAccepted();
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColor.primary(context);
    final surface = AppColor.surface(context);
    final muted = AppColor.textMuted(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // 系统返回等同不同意并退出。
        unawaited(_onDecline());
      },
      child: Material(
        color: surface,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: kIsWeb
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SelectableText(
                            '请阅读隐私政策后选择同意或退出。\n\n'
                            '${AppEnv.privacyPolicyUrl}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted),
                          ),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_controller != null)
                            WebViewWidget(controller: _controller!),
                          if (_loading)
                            const Align(
                              alignment: Alignment.topCenter,
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          if (_loadFailed && !_loading)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '隐私政策加载失败，请检查网络后重试',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: muted),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _retry,
                                      child: const Text('重试'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              // 固定底栏：不同意退出 / 同意继续。
              Material(
                elevation: 8,
                color: surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _accepting ? null : _onDecline,
                          child: const Text('不同意并退出'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _accepting ? null : _onAccept,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                          ),
                          child: _accepting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('同意并继续'),
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
