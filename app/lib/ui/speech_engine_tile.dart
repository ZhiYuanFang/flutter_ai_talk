import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/speech_engine.dart';
import '../config/speech_engine_store.dart';

/// 设置中心：语音识别方式（下拉选择）。
class SpeechEngineTile extends StatefulWidget {
  const SpeechEngineTile({this.onEngineChanged, super.key});

  /// 用户切换引擎后回调（用于联动隐藏/显示录音数据开关等）。
  final ValueChanged<SpeechEngine>? onEngineChanged;

  @override
  State<SpeechEngineTile> createState() => _SpeechEngineTileState();
}

class _SpeechEngineTileState extends State<SpeechEngineTile> {
  SpeechEngine? _engine;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final e = await SpeechEngineStore.load();
    if (!mounted) return;
    setState(() {
      _engine = e;
      _loading = false;
    });
  }

  Future<void> _set(SpeechEngine? engine) async {
    if (engine == null || engine == _engine) return;
    await SpeechEngineStore.save(engine);
    if (!mounted) return;
    setState(() => _engine = engine);
    widget.onEngineChanged?.call(engine);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    if (_loading || _engine == null) {
      return const ListTile(
        leading: Icon(Icons.mic_none_outlined),
        title: Text('语音识别'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ListTile(
      leading: const Icon(Icons.mic_none_outlined),
      title: const Text('语音识别'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<SpeechEngine>(
          value: _engine,
          isDense: true,
          alignment: AlignmentDirectional.centerEnd,
          items: [
            for (final option in SpeechEngine.values)
              DropdownMenuItem(
                value: option,
                child: Text(option.label),
              ),
          ],
          onChanged: (v) => unawaited(_set(v)),
        ),
      ),
    );
  }
}
