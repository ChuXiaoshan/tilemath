#!/usr/bin/env python3
"""生成 iOS 启动屏标识图（明/暗两套 × 1x/2x/3x）。

与 App 图标同构（8a·Cut tile 出血版，几何来自 tool/icon/make_app_icons.py）：
偏铺网格 + 右下切角。启动图不能直接复用图标：图标浅色版是纸面底，
放到浅色启动背景上会整块消失。这里画去背版本——铺面色随明暗主题反转
（浅色屏用墨色、深色屏用纸色），勾缝/锯缝是透出背景的空隙，
切下料青色随主题取对应档（同图标：浅 #0088B0 / 深 #62C5EE）。

用法：python3 tool/launch/make_launch_image.py
输出：ios/Runner/Assets.xcassets/LaunchImage.imageset/
"""

from pathlib import Path

from PIL import Image, ImageDraw

INK = (0x20, 0x1E, 0x1D)    # 浅色模式下的铺面色
PAPER = (0xF3, 0xF2, 0xF2)  # 深色模式下的铺面色
CYAN_LIGHT = (0x00, 0x88, 0xB0)
CYAN_DARK = (0x62, 0xC5, 0xEE)

PT = 96  # 标识边长（逻辑点），三档缩放由 SCALES 展开
SCALES = (1, 2, 3)
SS = 4   # 超采样倍数
OUT = Path("ios/Runner/Assets.xcassets/LaunchImage.imageset")

# 8a 几何（viewBox 120），与 tool/icon/make_app_icons.py 保持一致
VB = 120
SEAM = 4
V_SEAMS = (16, 68)
H_SEAMS = (28, 80)
TRI = [(120, 68), (120, 120), (68, 120)]
SAW = ((126, 62), (62, 126))
RADIUS = 12  # 去背标识的外圆角（viewBox 单位），切角侧保持锋利


def render(size: int, face, cyan) -> Image.Image:
    px = size * SS
    s = px / VB
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))

    # 铺面整块 + 切下料三角
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, px, px], fill=(*face, 255))
    d.polygon([(x * s, y * s) for x, y in TRI], fill=(*cyan, 255))

    # 勾缝与锯缝挖成透明空隙
    keep = Image.new("L", (px, px), 255)
    kd = ImageDraw.Draw(keep)
    w = round(SEAM * s)
    for x in V_SEAMS:
        kd.line([(x * s, -4 * s), (x * s, 124 * s)], fill=0, width=w)
    for y in H_SEAMS:
        kd.line([(-4 * s, y * s), (124 * s, y * s)], fill=0, width=w)
    kd.line(
        [(SAW[0][0] * s, SAW[0][1] * s), (SAW[1][0] * s, SAW[1][1] * s)],
        fill=0,
        width=w,
    )
    # 三角要保持完整（图标里锯缝在三角之下），把三角区域从挖除中排除
    kd.polygon([(x * s, y * s) for x, y in TRI], fill=255)

    # 外圆角遮罩（切角本身在圆角半径之外，不受影响）
    shape = Image.new("L", (px, px), 0)
    ImageDraw.Draw(shape).rounded_rectangle(
        [0, 0, px - 1, px - 1], radius=RADIUS * s, fill=255
    )
    from PIL import ImageChops

    img.putalpha(ImageChops.multiply(keep, shape))
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for scale in SCALES:
        px = PT * scale
        suffix = "" if scale == 1 else f"@{scale}x"
        for name, face, cyan in (
            ("", INK, CYAN_LIGHT),
            ("-dark", PAPER, CYAN_DARK),
        ):
            path = OUT / f"LaunchImage{name}{suffix}.png"
            render(px, face, cyan).save(path)
            print(f"{path}  {px}x{px}")


if __name__ == "__main__":
    main()
