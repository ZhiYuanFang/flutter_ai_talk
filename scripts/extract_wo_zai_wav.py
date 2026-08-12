import pathlib
import re
import base64

h = pathlib.Path(r"D:\work\Arduino\ai-voice\src\prompts\record_prompt_b64.h").read_text(
    encoding="utf-8", errors="ignore"
)
idx = h.find("kRecordPromptWavB64")
chunk = h[idx:]
parts = re.findall(r'"([A-Za-z0-9+/=]+)"', chunk)
b64 = "".join(parts)
raw = base64.b64decode(b64)
out = pathlib.Path(r"d:\work\flutter_ai_talk\app\assets\audio")
out.mkdir(parents=True, exist_ok=True)
path = out / "wo_zai.wav"
path.write_bytes(raw)
print("wrote", path, "bytes", len(raw), "magic", raw[:4])
