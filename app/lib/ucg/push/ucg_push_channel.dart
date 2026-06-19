/// Vendor push channel for launcher badge (no FCM).
enum UcgPushChannel {
  apns('apns'),
  hms('hms'),
  mipush('mipush');

  const UcgPushChannel(this.apiValue);
  final String apiValue;

  static UcgPushChannel? tryParse(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    for (final c in UcgPushChannel.values) {
      if (c.apiValue == v) return c;
    }
    return null;
  }
}

class UcgPushTokenEvent {
  const UcgPushTokenEvent({required this.channel, required this.token});

  final UcgPushChannel channel;
  final String token;
}
