import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 预测页引导门闸种类（互斥优先级：login > bind > recall）。
enum PredictionGateKind {
  none,
  login,
  bind,
  recall,
}

/// 登录引导 Dialog 是否可见（软关为 false；无永久 dismissed）。
final predictionLoginGateVisibleProvider = StateProvider<bool>((ref) => true);

/// 绑定引导 Dialog 是否可见（软关为 false；无永久 dismissed）。
final predictionBindGateVisibleProvider = StateProvider<bool>((ref) => true);
