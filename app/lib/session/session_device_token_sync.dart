import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';
import '../session/session_controller.dart';
import 'token_expiry.dart';

/// 本地已有宝宝 ID 但 JWT 缺少 `device_no` 时强制 refresh，使 WS 鉴权可用。
Future<bool> ensureAccessTokenHasDeviceNoForSession({
  required SessionController session,
  required String? localDeviceNo,
}) async {
  if (!session.isLoggedIn) return false;

  final dn = localDeviceNo;
  if (dn == null || dn.isEmpty) return true;

  final jwtDn = readJwtDeviceNo(session.accessToken);
  if (jwtDn != null && jwtDn.isNotEmpty) return true;

  final ok = await session.refreshSessionForDeviceBind();
  if (!ok) return false;

  final after = readJwtDeviceNo(session.accessToken);
  return after != null && after.isNotEmpty;
}

Future<bool> ensureAccessTokenHasDeviceNo(
  Ref ref, {
  String? localDeviceNo,
}) {
  final dn = localDeviceNo ?? ref.read(deviceNoNotifierProvider).asData?.value;
  return ensureAccessTokenHasDeviceNoForSession(
    session: ref.read(sessionProvider),
    localDeviceNo: dn,
  );
}

Future<bool> ensureAccessTokenHasDeviceNoFromWidget(
  WidgetRef ref, {
  String? localDeviceNo,
}) {
  final dn = localDeviceNo ?? ref.read(deviceNoNotifierProvider).asData?.value;
  return ensureAccessTokenHasDeviceNoForSession(
    session: ref.read(sessionProvider),
    localDeviceNo: dn,
  );
}
