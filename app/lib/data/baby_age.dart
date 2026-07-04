import 'models.dart';

/// 完整日历月龄（生日当天算满一月）。
int babyAgeInMonths(DateTime birthDate, DateTime now) {
  final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final today = DateTime(now.year, now.month, now.day);
  if (today.isBefore(birth)) return 0;
  var months = (today.year - birth.year) * 12 + today.month - birth.month;
  if (today.day < birth.day) months -= 1;
  return months < 0 ? 0 : months;
}

/// birthDate 是否可用于月龄（非未来、非明显 placeholder）。
bool isUsableBabyBirthDate(DateTime birthDate, DateTime now) {
  final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final today = DateTime(now.year, now.month, now.day);
  if (birth.isAfter(today)) return false;
  if (birth.year == now.year && birth.month == 1 && birth.day == 1) return false;
  return true;
}

String formatBabyAgeText(DateTime birthDate, DateTime now) {
  if (!isUsableBabyBirthDate(birthDate, now)) return '不满1个月啦';
  final months = babyAgeInMonths(birthDate, now);
  if (months == 0) return '不满1个月啦';
  if (months < 12) return '$months个月啦';
  final years = months ~/ 12;
  final rem = months % 12;
  if (rem == 0) return '$years岁啦';
  return '$years岁$rem个月啦';
}

String truncateWidgetNickname(String nickname) {
  final t = nickname.trim();
  if (t.isEmpty) return '宝宝';
  if (t.length <= 6) return t;
  return '${t.substring(0, 6)}…';
}

/// 小组件头部：`{昵称} · {月龄文案}`。
String formatWidgetHeaderLine(BabyProfile baby, [DateTime? now]) {
  final n = truncateWidgetNickname(baby.nickname);
  final age = formatBabyAgeText(baby.birthDate, now ?? DateTime.now());
  return '$n · $age';
}
