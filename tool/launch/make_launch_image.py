#!/usr/bin/env python3
"""生成 iOS 启动屏标识图（明/暗两套 × 1x/2x/3x）。

启动图不能直接复用 App 图标：图标自带 INK 深底，砖块用的是 PAPER 浅色，
放到浅色启动背景上砖块会与背景同色，只剩一个青十字。所以这里画的是
去背版本，砖块颜色随明暗主题反转，青色缝线两套通用。

用法：python3 tool/launch/make_launch_image.py
输出：ios/Runner/Assets.xcassets/LaunchImage.imageset/
"""

from pathlib import Path

from PIL import Image, ImageDraw

INK = (0x20, 0x1E, 0x1D, 255)   # 浅色模式下的砖块色
PAPER = (0xF3, 0xF2, 0xF2, 255)  # 深色模式下的砖块色
CYAN = (0x00, 0x88, 0xB0, 255)   # 缝线，两套通用

PT = 96  # 标识边长（逻辑点），三档缩放由 SCALES 展开
SCALES = (1, 2, 3)
OUT = Path("ios/Runner/Assets.xcassets/LaunchImage.imageset")

# 比例取自 assets/icon/icon.png，保持与 App 图标同构
SEAM_RATIO = 0.105   # 缝宽 / 标识边长
RADIUS_RATIO = 0.115  # 砖块圆角 / 砖块边长


def render(size: int, tile_color) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    seam = size * SEAM_RATIO
    tile = (size - seam) / 2
    radius = tile * RADIUS_RATIO

    # 青色十字缝：横竖各一条，通贯整个标识
    mid0, mid1 = tile, tile + seam
    d.rectangle([0, mid0, size, mid1], fill=CYAN)
    d.rectangle([mid0, 0, mid1, size], fill=CYAN)

    # 四块砖填入象限
    for x in (0, tile + seam):
        for y in (0, tile + seam):
            d.rounded_rectangle(
                [x, y, x + tile, y + tile], radius=radius, fill=tile_color
            )
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for scale in SCALES:
        px = PT * scale
        suffix = "" if scale == 1 else f"@{scale}x"
        for name, color in (("", INK), ("-dark", PAPER)):
            path = OUT / f"LaunchImage{name}{suffix}.png"
            render(px, color).save(path)
            print(f"{path}  {px}x{px}")


if __name__ == "__main__":
    main()
