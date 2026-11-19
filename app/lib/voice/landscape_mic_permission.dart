import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../ui/widgets/app_glass_overlay.dart';

/// 横屏语音麦克风用途说明（对齐语音球先告知、UCG 位置用途框节奏）。
const kLandscapeMicRationaleTitle = '需要使用麦克风';
const kLandscapeMicRationaleMessage =
    '胖宝将在预测前台使用麦克风，以便识别唤醒词「胖宝」、'
    '或在竖屏长按「去记录」时完成语音对话转写。'
    '仅在 App 位于前台时采集，不会后台录音，也不会用于广告。';

/// 本会话是否已拒绝用途框或系统权限（避免反复硬弹）。
bool landscapeMicDeniedThisSession = false;

/// 检查是否已有麦克风权限（不弹系统框、不 request）。
Future<bool> landscapeMicAlreadyGranted() async {
  if (kIsWeb) return false;
  final status = await Permission.microphone.status;
  if (status.isGranted) return true;
  // 部分机型 permission_handler 与 record 状态不一致时再探一次。
  final recorder = AudioRecorder();
  try {
    return await recorder.hasPermission(request: false);
  } finally {
    await recorder.dispose();
  }
}

/// 预测语音表面可见时的 soft-check：只探测是否已授权。
///
/// MUST NOT 弹用途框、MUST NOT 系统 request、MUST NOT 置 [landscapeMicDeniedThisSession]
///（「尚未询问」≠「用户已拒绝」）。lifecycle / soft activate 注入此闭包。
Future<bool> softCheckLandscapeMicGranted() => landscapeMicAlreadyGranted();

/// 用户点按监听入口后的完整申请：未授权时先玻璃用途框，确认后再系统申请；已授权跳过。
///
/// 返回 true 表示可开麦；取消/拒绝返回 false，并置 [landscapeMicDeniedThisSession]。
Future<bool> ensureLandscapeMicPermission(BuildContext context) async {
  if (kIsWeb) return false;
  if (await landscapeMicAlreadyGranted()) {
    landscapeMicDeniedThisSession = false;
    return true;
  }
  if (landscapeMicDeniedThisSession) return false;
  if (!context.mounted) return false;

  final proceed = await showGlassConfirmDialog(
        context,
        title: kLandscapeMicRationaleTitle,
        message: kLandscapeMicRationaleMessage,
        cancelLabel: '暂不',
        confirmLabel: '继续',
      ) ??
      false;

  if (!proceed) {
    landscapeMicDeniedThisSession = true;
    return false;
  }

  final status = await Permission.microphone.request();
  if (status.isGranted) {
    landscapeMicDeniedThisSession = false;
    return true;
  }

  // 兜底：部分 Android 上 record 插件申请路径更稳。
  final recorder = AudioRecorder();
  try {
    final ok = await recorder.hasPermission(request: true);
    if (ok) {
      landscapeMicDeniedThisSession = false;
      return true;
    }
  } finally {
    await recorder.dispose();
  }

  landscapeMicDeniedThisSession = true;
  return false;
}
