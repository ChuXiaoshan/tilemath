#!/usr/bin/env bash
# Noto Sans SC 子集化管线：完整 VF 有 17MB，本 app 中文 UI 字符有限，
# 裁剪后每权重约百 KB 级。**每次改动 app_zh.arb 后必须重跑本脚本**，
# 否则新增汉字会逐字回退到系统字体（不崩，但字形混排）。
# 依赖：fonttools（brew install fonttools）、curl。
set -euo pipefail
cd "$(dirname "$0")/../.."

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
VF_URL='https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf'

# 1) 取 VF（本地已有缓存参数可跳过下载：subset_noto_sc.sh <vf路径>）
if [[ $# -ge 1 && -f "$1" ]]; then
  cp "$1" "$WORK/vf.ttf"
else
  curl -sL "$VF_URL" -o "$WORK/vf.ttf"
fi

# 2) 从 zh ARB 提取全部字符 + ASCII + 常用中文标点缓冲
python3 - "$WORK/glyphs.txt" <<'PY'
import json, string, sys

chars = set(string.printable)
# 中文标点/符号缓冲（不在 ARB 也预留，避免小改动就得重跑）
chars |= set('，。、：；！？（）《》【】—·…％×℃′″¥￥')
with open('lib/l10n/app_zh.arb', encoding='utf-8') as f:
    data = json.load(f)
for key, value in data.items():
    if not key.startswith('@') and isinstance(value, str):
        chars |= set(value)
with open(sys.argv[1], 'w', encoding='utf-8') as f:
    f.write(''.join(sorted(chars)))
PY

# 3) 实例化 400/600 → 子集化（700 不出：中文无 w700 场景，缺了走系统回退）
for pair in "400:Regular" "600:SemiBold"; do
  w="${pair%%:*}"; name="${pair##*:}"
  fonttools varLib.instancer "$WORK/vf.ttf" wght="$w" -o "$WORK/static-$w.ttf" >/dev/null 2>&1
  pyftsubset "$WORK/static-$w.ttf" \
    --text-file="$WORK/glyphs.txt" \
    --layout-features='*' \
    --output-file="assets/fonts/NotoSansSC-$name-subset.ttf"
done

ls -la assets/fonts/NotoSansSC-*.ttf
echo "完成。记得 fvm flutter clean 不必，热重载即可看到新字形。"
