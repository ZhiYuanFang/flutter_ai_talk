import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/env.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.initialUrl ?? AppEnv.privacyPolicyUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(uri ?? Uri.parse(AppEnv.privacyPolicyUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: Stack(
        children: [
          if (kIsWeb)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Web 端 webview_flutter 能力因浏览器环境而异；当前以占位说明替代。\n\n'
                  '应打开地址：\n${widget.initialUrl ?? AppEnv.privacyPolicyUrl}\n\n'
                  '生产环境可改用 iframe / 内嵌 Web 组件或 url_launcher 策略。',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_loading && !kIsWeb) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
