import 'package:flutter/foundation.dart';

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
  if (!isUsableBabyBirthDate(birthDate, now)) return '不满1个月';
  final months = babyAgeInMonths(birthDate, now);
  if (months == 0) return '不满1个月';
  if (months < 12) return '$months个月啦';
  final years = months ~/ 12;
  final rem = months % 12;
  if (rem == 0) return '$years岁啦';
  return '$years岁$rem个月啦';
}

// --- 应用内身份展示原子（L1）：可空 profile → 统一空态；不截断昵称。
// 小组件载荷请用下方 truncateWidgetNickname / formatWidgetHeaderLine。

/// 仓库未绑定占位昵称（不得作为应用内身份展示）。
const String kUnboundBabyPlaceholderNickname = '未绑定宝宝ID';

/// 身份展示昵称：null / 空白 / 占位「未绑定宝宝ID」→「宝宝」。
String displayBabyNickname(BabyProfile? baby) {
  final t = baby?.nickname.trim() ?? '';
  // 占位串与空昵称同等视为无效。
  if (t.isEmpty || t == kUnboundBabyPlaceholderNickname) return '宝宝';
  return t;
}

/// 身份展示月龄：null →「不满1个月啦」；否则委托 [formatBabyAgeText]。
String displayBabyAgeText(BabyProfile? baby, [DateTime? now]) {
  if (baby == null) return '不满1个月啦';
  return formatBabyAgeText(baby.birthDate, now ?? DateTime.now());
}

/// 合成身份行：月龄为空时仅昵称，不得强拼「 · 」。
String composeBabyIdentityLine(String nickname, String ageText) {
  final age = ageText.trim();
  if (age.isEmpty) return nickname;
  return '$nickname · $age';
}

/// 应用内合成行「昵称 · 月龄」（不套用小组件六字截断；UI 侧 ellipsis）。
String displayBabyIdentityLine(BabyProfile? baby, [DateTime? now]) {
  return composeBabyIdentityLine(
    displayBabyNickname(baby),
    displayBabyAgeText(baby, now),
  );
}

/// 头像用 babyId：null → 空串。
String displayBabyId(BabyProfile? baby) => baby?.id ?? '';

/// 头像用性别：null → [BabySex.unknown]。
BabySex displayBabySex(BabyProfile? baby) => baby?.sex ?? BabySex.unknown;

/// 应用内身份展示快照：字段均经 L1 原子解析（或会话覆盖 chrome）。
@immutable
class BabyDisplay {
  const BabyDisplay({
    required this.profile,
    required this.nickname,
    required this.ageText,
    required this.identityLine,
    required this.babyId,
    required this.sex,
    this.showAge = true,
  });

  final BabyProfile? profile;
  final String nickname;
  final String ageText;
  final String identityLine;
  final String babyId;
  final BabySex sex;
  /// 是否展示月龄段/行（未登录/未绑定 chrome 为 false）。
  final bool showAge;

  /// 委托 L1；[now] 缺省为墙钟（身份月龄不绑预测秒级 clock）。
  factory BabyDisplay.resolve(BabyProfile? baby, [DateTime? now]) {
    final at = now ?? DateTime.now();
    final nickname = displayBabyNickname(baby);
    final ageText = displayBabyAgeText(baby, at);
    return BabyDisplay(
      profile: baby,
      nickname: nickname,
      ageText: ageText,
      identityLine: composeBabyIdentityLine(nickname, ageText),
      babyId: displayBabyId(baby),
      sex: displayBabySex(baby),
      showAge: true,
    );
  }

  /// 会话覆盖：固定昵称、隐藏月龄（未登录 / 已登录未绑定）。
  factory BabyDisplay.authChrome({
    required String nickname,
    BabyProfile? profile,
  }) {
    return BabyDisplay(
      profile: profile,
      nickname: nickname,
      ageText: '',
      identityLine: nickname,
      babyId: displayBabyId(profile),
      sex: displayBabySex(profile),
      showAge: false,
    );
  }
}

/// 小组件昵称：空 →「宝宝」；超过 6 字硬截断（与应用内 display* 分流）。
String truncateWidgetNickname(String nickname) {
  final t = nickname.trim();
  if (t.isEmpty) return '宝宝';
  if (t.length <= 6) return t;
  return '${t.substring(0, 6)}…';
}

/// 小组件头部：`{昵称} · {月龄文案}`（含六字截断）。
String formatWidgetHeaderLine(BabyProfile baby, [DateTime? now]) {
  final n = truncateWidgetNickname(baby.nickname);
  final age = formatBabyAgeText(baby.birthDate, now ?? DateTime.now());
  return '$n · $age';
}
