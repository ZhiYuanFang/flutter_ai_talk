import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/app_debug_log.dart';
import '../data/baby_share_qr_payload.dart';
import '../theme/app_color.dart';

/// 相机扫宝宝共享码；成功 pop 出 deviceNo（String）。
class BabyQrScanScreen extends StatefulWidget {
  const BabyQrScanScreen({super.key});

  @override
  State<BabyQrScanScreen> createState() => _BabyQrScanScreenState();
}

enum _CamPhase {
  /// 正在查/申请相机权限
  checking,
  /// 用户拒绝或永久拒绝
  denied,
  /// 已授权，可挂载 MobileScanner
  ready,
}

class _BabyQrScanScreenState extends State<BabyQrScanScreen> {
  MobileScannerController? _controller;
  var _handled = false;
  var _phase = _CamPhase.checking;
  var _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // 先要权限再挂相机，避免黑底无反馈
      _ensureCameraPermission();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      AppDebugLog.babyShare('camera permission granted');
      setState(() {
        _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        );
        _phase = _CamPhase.ready;
      });
      return;
    }
    AppDebugLog.babyShare(
      'camera permission denied status=$status '
      'permanent=${status.isPermanentlyDenied}',
    );
    setState(() {
      _phase = _CamPhase.denied;
      _permanentlyDenied = status.isPermanentlyDenied;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    final dn = BabyShareQrPayload.tryDecode(raw);
    if (dn == null) {
      AppDebugLog.babyShare('scan reject non-product payload');
      // 持续扫时偶尔提示，避免无反馈；不结束会话以便对准正确码
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(BabyShareQrPayload.invalidMessage),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    _handled = true;
    AppDebugLog.babyShare('scan ok deviceNoLen=${dn.length}');
    if (mounted) context.pop(dn);
  }

  /// 黑底扫一扫 AppBar：强制白字白图标，避免被全局深色 iconTheme 盖成「看不见」
  PreferredSizeWidget _scanAppBar() {
    return AppBar(
      title: const Text('扫一扫'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _deniedBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            const Text(
              '需要相机权限才能扫码绑定',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              _permanentlyDenied
                  ? '请在系统设置中开启相机权限后重试'
                  : '请允许使用相机，或改用相册识码',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (_permanentlyDenied)
              FilledButton(
                onPressed: openAppSettings,
                child: const Text('打开系统设置'),
              )
            else
              FilledButton(
                onPressed: () {
                  setState(() => _phase = _CamPhase.checking);
                  _ensureCameraPermission();
                },
                child: const Text('重新申请'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onShell = AppColor.textPrimary(context);
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('扫一扫'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            '请在手机 App 上扫码绑定',
            style: TextStyle(color: onShell),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _scanAppBar(),
      backgroundColor: Colors.black,
      body: switch (_phase) {
        _CamPhase.checking => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white70),
                SizedBox(height: 16),
                Text(
                  '正在打开相机…',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        _CamPhase.denied => _deniedBody(),
        _CamPhase.ready => Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller!,
                onDetect: _onDetect,
                // 失败时给可读文案，避免默认黑底 + 小错误图标
                errorBuilder: (context, error, child) {
                  AppDebugLog.babyShare(
                    'scanner error code=${error.errorCode} '
                    'msg=${error.errorDetails?.message}',
                  );
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '无法打开相机（${error.errorCode.name}）\n请返回后重试，或改用相册识码',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
                placeholderBuilder: (context, child) => const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                  child: Text(
                    '对准家人出示的宝宝共享码',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
      },
    );
  }
}
