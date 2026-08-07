#!/usr/bin/env bash
# 把已抓取的截图规范化为 App Store 可接受的形式，并校验。
#
# 用法： tool/screenshots/normalize.sh <png 文件>
#
# App Store 的两条硬要求最容易翻车：
#   1. 不得含 alpha 通道
#   2. 像素尺寸必须精确匹配某一档位，差一像素都会被拒
set -euo pipefail

FILE="${1:?用法: normalize.sh <png>}"
[ -f "$FILE" ] || { echo "✗ 文件不存在: $FILE"; exit 1; }

# ASC 版本页给出的合法尺寸（含横屏），按档位分组：
#   6.5″ iPhone：1242x2688 / 1284x2778
#   6.9″ iPhone（iPhone 17 Pro Max 等）：1320x2868
#   13″ iPad（iPad Pro 13-inch，v1.1 恢复 iPad 后必填档）：2064x2752
VALID="1242x2688 2688x1242 1284x2778 2778x1284 1320x2868 2868x1320 2064x2752 2752x2064"

# 经 JPEG 中转强制合成掉 alpha，再转回 PNG
if sips -g hasAlpha "$FILE" | grep -q "hasAlpha: yes"; then
  TMP="${FILE%.png}.tmp.jpg"
  sips -s format jpeg -s formatOptions best "$FILE" --out "$TMP" >/dev/null
  sips -s format png "$TMP" --out "$FILE" >/dev/null
  rm -f "$TMP"
fi

W=$(sips -g pixelWidth  "$FILE" | awk '/pixelWidth/{print $2}')
H=$(sips -g pixelHeight "$FILE" | awk '/pixelHeight/{print $2}')
ALPHA=$(sips -g hasAlpha "$FILE" | awk '/hasAlpha/{print $2}')

printf '%s  %sx%s  alpha=%s  ' "$FILE" "$W" "$H" "$ALPHA"

if [[ " $VALID " != *" ${W}x${H} "* ]]; then
  printf '✗ 尺寸不在任何已知档位合法值内（%s）\n' "$VALID"
  exit 1
fi
if [[ "$ALPHA" != "no" ]]; then
  printf '✗ 仍带 alpha 通道，App Store 会拒收\n'
  exit 1
fi
printf '✓\n'
