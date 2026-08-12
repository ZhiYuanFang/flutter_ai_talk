import pathlib
import re
import base64

# 从硬件「我先退下了」提示音抽取 Flutter asset。
inc = pathlib.Path(
    r"D:\work\Arduino\ai-voice\src\prompts\exit_dialog_prompt_b64.inc"
).read_text(encoding="utf-8", errors="ignore")
parts = re.findall(r'"([A-Za-z0-9+/=]+)"', inc)
b64 = "".join(parts)
raw = base64.b64decode(b64)
out = pathlib.Path(r"d:\work\flutter_ai_talk\app\assets\audio")
out.mkdir(parents=True, exist_ok=True)
path = out / "wo_xian_tui_xia_le.wav"
path.write_bytes(raw)
print("wrote", path, "bytes", len(raw), "magic", raw[:4])
