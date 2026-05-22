// Release 构建前检查 Vosk 中文模型 zip 是否已放入 assets。
// 用法：dart run tool/check_vosk_model.dart
import 'dart:io';

void main() {
  const path = 'assets/models/vosk-model-small-cn-0.22.zip';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('缺少语音模型：$path');
    stderr.writeln('请阅读 assets/models/README.md 下载并放置 zip 后再构建 release。');
    exit(1);
  }
  final mb = file.lengthSync() / (1024 * 1024);
  stdout.writeln('OK: $path (${mb.toStringAsFixed(1)} MiB)');
}
