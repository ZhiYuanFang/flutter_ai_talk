import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/recording_diagnostics_store.dart';
import '../config/speech_engine.dart';
import '../config/speech_engine_store.dart';
import 'speech_engine_tile.dart';

/// 设置：是否显示云端录音诊断面板（仅当前引擎为云端 ASR 时可见）。
class RecordingDiagnosticsTile extends StatefulWidget {
  const RecordingDiagnosticsTile({this.engine, super.key});

  /// 由 [VoiceInputSettingsGroup] 传入；单独使用时在内部加载。
  final SpeechEngine? engine;

  @override
  State<RecordingDiagnosticsTile> createState() => _RecordingDiagnosticsTileState();
}

class _RecordingDiagnosticsTileState extends State<RecordingDiagnosticsTile> {
  SpeechEngine? _engine;
  var _enabled = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(RecordingDiagnosticsTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engine != null && widget.engine != oldWidget.engine) {
      setState(() => _engine = widget.engine);
    }
  }

  Future<void> _load() async {
    final engine = widget.engine ?? await SpeechEngineStore.load();
    final v = await RecordingDiagnosticsStore.load();
    if (!mounted) return;
    setState(() {
      _engine = engine;
      _enabled = v;
      _loading = false;
    });
  }

  Future<void> _set(bool value) async {
    await RecordingDiagnosticsStore.save(value);
    if (!mounted) return;
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    if (_loading) {
      return const SizedBox.shrink();
    }
    if (_engine != SpeechEngine.cloudAsr) {
      return const SizedBox.shrink();
    }
    return SwitchListTile(
      secondary: const Icon(Icons.graphic_eq),
      title: const Text('显示录音数据'),
      subtitle: const Text('按住说话时，在语音按钮左侧显示 PCM 参数'),
      value: _enabled,
      onChanged: _set,
    );
  }
}

/// 语音识别引擎 + 录音数据开关（开关随引擎联动显隐）。
class VoiceInputSettingsGroup extends StatefulWidget {
  const VoiceInputSettingsGroup({super.key});

  @override
  State<VoiceInputSettingsGroup> createState() => _VoiceInputSettingsGroupState();
}

class _VoiceInputSettingsGroupState extends State<VoiceInputSettingsGroup> {
  SpeechEngine? _engine;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEngine());
  }

  Future<void> _loadEngine() async {
    final e = await SpeechEngineStore.load();
    if (!mounted) return;
    setState(() => _engine = e);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpeechEngineTile(
          onEngineChanged: (e) => setState(() => _engine = e),
        ),
        RecordingDiagnosticsTile(engine: _engine),
      ],
    );
  }
}
