import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 预测页引导门闸种类（互斥优先级：login > bind > recall）。
enum PredictionGateKind {
  none,
  login,
  bind,
  recall,
}

/// 登录引导 Dialog 是否可见（默认 false：进页不弹；骨架卡意图打开；软关为 false）。
final predictionLoginGateVisibleProvider = StateProvider<bool>((ref) => false);

/// 绑定引导 Dialog 是否可见（默认 false：进页不弹；骨架卡意图打开；软关为 false）。
final predictionBindGateVisibleProvider = StateProvider<bool>((ref) => false);
