#!/usr/bin/env python3
"""从 8a 定稿几何生成 App 图标源图（2026-07-27 设计定稿）。

构图「Cut tile 出血版」：偏铺网格（竖缝 16/68、横缝 28/80，砖为 52/120 模数、
起铺点偏左上）+ 右下切角三角 + 沿切口的锯缝。三外观：
- light  : 纸面 #F4F3F2 + 墨勾缝 #201E1D + 青切下料 #0088B0，不透明
- dark   : 15% 白铺面，勾缝/锯缝为真透明空隙（透出系统深色底），切下料 #62C5EE
- tinted : 竖向渐变 #DCECF4→#4F8BA1，铺面 30%、切下料 100%；
           灰度化交给 flutter_launcher_icons 的 desaturate_tinted_to_grayscale_ios
另出 Android 自适应前景：8a 浅色整面缩进安全区（66%）置于透明画布中央。

几何数值与设计稿 SVG 逐条对应（viewBox 120），勿凭感觉改。

用法：python3 tool/icon/make_app_icons.py
输出：assets/icon/icon.png / icon_dark.png / icon_tinted.png / icon_foreground.png
"""

from pathlib import Path

from PIL import Image, ImageDraw

VB = 120          # 设计稿 viewBox 边长
OUT_PX = 1024     # 输出边长
SS = 4            # 超采样倍数（先画 4096 再 LANCZOS 缩回，获得抗锯齿）
OUT = Path("assets/icon")

PAPER = (0xF4, 0xF3, 0xF2)
INK = (0x20, 0x1E, 0x1D)
CYAN_LIGHT = (0x00, 0x88, 0xB0)
CYAN_DARK = (0x62, 0xC5, 0xEE)
TINT_TOP = (0xDC, 0xEC, 0xF4)
TINT_BOTTOM = (0x4F, 0x8B, 0xA1)

SEAM = 4                      # 勾缝/锯缝线宽
V_SEAMS = (16, 68)            # 竖缝中心
H_SEAMS = (28, 80)            # 横缝中心
# 切角三角（120,68)-(120,120)-(68,120）；锯缝沿 (126,62)-(62,126)
TRI = [(120, 68), (120, 120), (68, 120)]
SAW = ((126, 62), (62, 126))
# 浅色版网格的裁切区（勾缝不进入切角）：(0,0)(120,0)(120,64)(64,120)(0,120)
GRID_CLIP = [(0, 0), (120, 0), (120, 64), (64, 120), (0, 120)]


def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw, float]:
    px = OUT_PX * SS
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img), px / VB


def draw_seams(d: ImageDraw.ImageDraw, s: float, fill) -> None:
    """四条勾缝 + 一条锯缝，全长（不裁切）。"""
    for x in V_SEAMS:
        d.line([(x * s, -4 * s), (x * s, 124 * s)], fill=fill, width=round(SEAM * s))
    for y in H_SEAMS:
        d.line([(-4 * s, y * s), (124 * s, y * s)], fill=fill, width=round(SEAM * s))
    d.line(
        [(SAW[0][0] * s, SAW[0][1] * s), (SAW[1][0] * s, SAW[1][1] * s)],
        fill=fill,
        width=round(SEAM * s),
    )


def finish(img: Image.Image) -> Image.Image:
    return img.resize((OUT_PX, OUT_PX), Image.LANCZOS)


def make_light() -> Image.Image:
    img, d, s = canvas()
    d.rectangle([0, 0, img.width, img.height], fill=(*PAPER, 255))
    d.polygon([(x * s, y * s) for x, y in TRI], fill=(*CYAN_LIGHT, 255))

    # 勾缝画在独立层，按 GRID_CLIP 裁切后合入（设计稿 clipPath 语义）
    grid = Image.new("RGBA", img.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    for x in V_SEAMS:
        gd.line([(x * s, -4 * s), (x * s, 124 * s)], fill=(*INK, 255), width=round(SEAM * s))
    for y in H_SEAMS:
        gd.line([(-4 * s, y * s), (124 * s, y * s)], fill=(*INK, 255), width=round(SEAM * s))
    clip = Image.new("L", img.size, 0)
    ImageDraw.Draw(clip).polygon([(x * s, y * s) for x, y in GRID_CLIP], fill=255)
    grid.putalpha(Image.composite(grid.getchannel("A"), clip.point(lambda _: 0), clip))
    img.alpha_composite(grid)

    # 锯缝在最上层，不裁切
    d = ImageDraw.Draw(img)
    d.line(
        [(SAW[0][0] * s, SAW[0][1] * s), (SAW[1][0] * s, SAW[1][1] * s)],
        fill=(*INK, 255),
        width=round(SEAM * s),
    )
    return finish(img).convert("RGB")  # 商店主图标必须不透明


def _punched_face(face_rgba_fn, s: float, size: int) -> Image.Image:
    """铺面 + 勾缝/锯缝挖成透明空隙（dark/tinted 共用的 mask 语义）。"""
    face = face_rgba_fn(size)
    keep = Image.new("L", (size, size), 255)
    draw_seams(ImageDraw.Draw(keep), s, 0)
    alpha = face.getchannel("A").point(lambda a: a)  # copy
    face.putalpha(Image.composite(alpha, Image.new("L", (size, size), 0), keep))
    return face


def _gradient(size: int, alpha: int) -> Image.Image:
    img = Image.new("RGBA", (size, size))
    top, bot = TINT_TOP, TINT_BOTTOM
    for y in range(size):
        t = y / (size - 1)
        row = tuple(round(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        ImageDraw.Draw(img).line([(0, y), (size, y)], fill=(*row, alpha))
    return img


def make_dark() -> Image.Image:
    img, _, s = canvas()
    white15 = lambda size: Image.new("RGBA", (size, size), (255, 255, 255, 38))
    img.alpha_composite(_punched_face(white15, s, img.width))
    ImageDraw.Draw(img).polygon(
        [(x * s, y * s) for x, y in TRI], fill=(*CYAN_DARK, 255)
    )
    return finish(img)


def make_tinted() -> Image.Image:
    img, _, s = canvas()
    img.alpha_composite(_punched_face(lambda size: _gradient(size, 77), s, img.width))
    tri = Image.new("L", img.size, 0)
    ImageDraw.Draw(tri).polygon([(x * s, y * s) for x, y in TRI], fill=255)
    full = _gradient(img.width, 255)
    img.paste(full, (0, 0), tri)
    return finish(img)


def make_foreground(light: Image.Image) -> Image.Image:
    """Android 自适应前景：整面缩进 66% 安全区。圆形遮罩下读作
    纸底上的一块砖样，切角不会被裁掉。"""
    img = Image.new("RGBA", (OUT_PX, OUT_PX), (0, 0, 0, 0))
    inner = round(OUT_PX * 0.66)
    scaled = light.convert("RGBA").resize((inner, inner), Image.LANCZOS)
    img.alpha_composite(scaled, ((OUT_PX - inner) // 2, (OUT_PX - inner) // 2))
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    light = make_light()
    for name, img in (
        ("icon.png", light),
        ("icon_dark.png", make_dark()),
        ("icon_tinted.png", make_tinted()),
        ("icon_foreground.png", make_foreground(light)),
    ):
        path = OUT / name
        img.save(path)
        print(f"{path}  {img.size[0]}x{img.size[1]}  mode={img.mode}")


if __name__ == "__main__":
    main()
