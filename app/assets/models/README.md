# Vosk 中文小模型（内置安装包）

## 放哪里（唯一正确路径）

把 **zip 原文件**（不要先解压成文件夹）放在本目录下，完整路径为：

```
app/assets/models/vosk-model-small-cn-0.22.zip
```

仓库根目录视角：

```
flutter_ai_talk/
  app/
    assets/
      models/
        README.md                          ← 本说明
        vosk-model-small-cn-0.22.zip       ← 你要放的文件（约 42MB）
```

## 下载

- 打开：<https://alphacephei.com/vosk/models>
- 找到 **vosk-model-small-cn-0.22**，下载其 **.zip**
- 下载后若文件名不同，请重命名为 `vosk-model-small-cn-0.22.zip` 再放入上表目录

## 校验

在 `app/` 目录执行：

```bash
dart run tool/check_vosk_model.dart
```

成功会输出 zip 大小；失败会提示缺少文件。

安装 release APK/AAB 后约增加 **42–55MB**。模型随包内置，**无需**首次联网下载，**无需**分包（整包携带）。

## iOS 原生库（仅开发机/CI 构建 iOS 时需要）

```bash
cd app
dart run vosk_flutter_service install -t ios
```

## 缺模型时

Release 构建前请确认 zip 存在；否则 `flutter build apk` 可通过，但语音功能在运行时会提示「语音模型未就绪」。
