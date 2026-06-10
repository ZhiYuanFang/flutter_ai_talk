import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';
import '../session/session_controller.dart';
import 'token_expiry.dart';

/// 本地已有宝宝 ID 时，确保 JWT `device_no` 与本地一致（缺失或不一致则 refresh）。
Future<bool> ensureAccessTokenHasDeviceNoForSession({
  required SessionController session,
  required String? localDeviceNo,
}) async {
  if (!session.isLoggedIn) return false;

  final dn = localDeviceNo;
  if (dn == null || dn.isEmpty) return true;

  final jwtDn = readJwtDeviceNo(session.accessToken);
  if (jwtDn != null && jwtDn.isNotEmpty && jwtDn == dn) return true;

  final ok = await session.refreshSessionForDeviceBind();
  if (!ok) return false;

  final after = readJwtDeviceNo(session.accessToken);
  return after != null && after.isNotEmpty && after == dn;
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
