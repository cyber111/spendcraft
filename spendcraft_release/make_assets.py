#!/usr/bin/env python3
"""
SpendCraft Play Store assets: styled screenshots, feature graphic, store icon.
Adapted from ~/.claude/skills/playstore-release/reference/*.py for macOS
(system Helvetica Neue — the FoodDelivery design system's fallback after Inter).

Run from this folder:  python3 make_assets.py   (needs Pillow)
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "source")
ICON_SRC = os.path.join(HERE, "..", "assets", "icon")
APP_NAME = "SpendCraft"

HELV = "/System/Library/Fonts/HelveticaNeue.ttc"
FACE = {"regular": 0, "bold": 1, "light": 7, "medium": 10}


def font(size, weight="bold"):
    return ImageFont.truetype(HELV, size, index=FACE[weight])


# Brand: ink (the app's default monochrome UI) + teal (the launcher icon).
INK = ((31, 31, 31), (5, 5, 5))
TEAL = ((13, 148, 136), (15, 118, 110))
TEAL_ACCENT = (45, 212, 191)


def gradient(size, top, bottom, diagonal=False):
    """Smooth gradient by upscaling a tiny image (fast, no banding)."""
    if diagonal:
        mid = tuple((a + b) // 2 for a, b in zip(top, bottom))
        g = Image.new("RGB", (2, 2))
        g.putdata([top, mid, mid, bottom])
    else:
        g = Image.new("RGB", (1, 2))
        g.putdata([top, bottom])
    return g.resize(size, Image.BICUBIC)


def rounded(img, radius):
    """Return RGBA copy with rounded corners (also trims device-frame corners)."""
    img = img.convert("RGBA")
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([(0, 0), (img.width - 1, img.height - 1)], radius, fill=255)
    img.putalpha(m)
    return img


def glow(canvas, center, radius, color, alpha=90):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    x, y = center
    ImageDraw.Draw(layer).ellipse([(x - radius, y - radius), (x + radius, y + radius)], fill=color + (alpha,))
    layer = layer.filter(ImageFilter.GaussianBlur(radius // 2))
    canvas.alpha_composite(layer)


def text_center(d, W, text, y, fnt, fill):
    b = d.textbbox((0, 0), text, font=fnt)
    d.text(((W - (b[2] - b[0])) // 2 - b[0], y), text, font=fnt, fill=fill)


# The uploaded captures are 896x2000 and some include the emulator's rounded
# device corners; a 120px source-scale radius trims those for every shot.
SHOT_RADIUS = 120

# ---------------------------------------------------------------- screenshots
W, H = 1080, 1920
SCREENS = [
    # (source, headline, background)
    ("1.webp", "Every Rupee,\nAt a Glance", INK),
    ("2.webp", "See Where Your\nMoney Goes", TEAL),
    ("3.webp", "Stay on\nBudget", INK),
    ("7.webp", "Easy on the Eyes,\nDay or Night", TEAL),
    # 4.webp (old Guest-mode card) and 8.webp (sign-in screen) no longer match
    # the local-only v1 — recapture Settings if a 5th/6th shot is wanted.
]


def make_screenshots():
    out_dir = os.path.join(HERE, "screenshots")
    os.makedirs(out_dir, exist_ok=True)
    f_head, f_brand = font(78, "bold"), font(38, "medium")
    for i, (src, headline, (c1, c2)) in enumerate(SCREENS, 1):
        img = gradient((W, H), c1, c2).convert("RGBA")
        glow(img, (W - 120, 260), 260, TEAL_ACCENT if c1 == INK[0] else (255, 255, 255), 40)
        d = ImageDraw.Draw(img)
        y = 96
        for line in headline.split("\n"):
            text_center(d, W, line, y, f_head, (255, 255, 255))
            y += 96
        shot = rounded(Image.open(os.path.join(SRC, src)), SHOT_RADIUS)
        max_h = H - y - 190
        r = min((W - 220) / shot.width, max_h / shot.height)
        shot = shot.resize((int(shot.width * r), int(shot.height * r)), Image.LANCZOS)
        top = y + 40
        # Hairline frame so white UI doesn't bleed into light glows, and
        # black UI stays distinct on ink.
        frame = rounded(Image.new("RGB", (shot.width + 6, shot.height + 6), (70, 70, 70)), int(SHOT_RADIUS * r) + 3)
        img.alpha_composite(frame, ((W - frame.width) // 2, top - 3))
        img.alpha_composite(shot, ((W - shot.width) // 2, top))
        text_center(d, W, APP_NAME, H - 96, f_brand, (255, 255, 255, 220))
        path = os.path.join(out_dir, f"{i:02d}.png")
        img.convert("RGB").save(path)
        print("wrote", os.path.relpath(path, HERE))


# ---------------------------------------------------------------- store icon
def make_icons():
    src = Image.open(os.path.join(ICON_SRC, "app_icon.png")).convert("RGBA")
    # Play wants a full-bleed square (it applies its own mask). Rebuild the
    # transparent corners from the icon's own gradient colours.
    s = src.width
    pts = [src.getpixel(p)[:3] for p in [(180, 180), (s - 180, 180), (180, s - 180), (s - 180, s - 180)]]
    bg = Image.new("RGB", (2, 2))
    bg.putdata(pts)
    full = bg.resize((s, s), Image.BILINEAR).convert("RGBA")
    full.alpha_composite(src)
    full.convert("RGB").resize((512, 512), Image.LANCZOS).save(os.path.join(HERE, "icon_512x512.png"))
    fg = Image.open(os.path.join(ICON_SRC, "icon_foreground.png")).convert("RGBA")
    fg.resize((512, 512), Image.LANCZOS).save(os.path.join(HERE, "icon_foreground.png"))
    print("wrote icon_512x512.png, icon_foreground.png")
    return full


# ----------------------------------------------------------- feature graphic
def make_feature_graphic(icon_full):
    FW, FH = 1024, 500
    fg = gradient((FW, FH), (28, 28, 28), (0, 0, 0), diagonal=True).convert("RGBA")
    glow(fg, (880, 90), 220, TEAL_ACCENT, 70)
    glow(fg, (120, 470), 180, (13, 148, 136), 60)
    d = ImageDraw.Draw(fg)

    ic = rounded(icon_full.resize((84, 84), Image.LANCZOS), 20)
    fg.alpha_composite(ic, (50, 52))
    d.text((152, 60), APP_NAME, font=font(62, "bold"), fill=(255, 255, 255))
    d.text((52, 160), "Track every rupee. Stay on budget.", font=font(27, "regular"), fill=(229, 229, 229))
    d.text((52, 196), "Works offline — no account needed.", font=font(27, "regular"), fill=(163, 163, 163))

    # Pills: FoodDelivery-style 1px outline, 4px radius. Wrap before the
    # right 30% (x > 700) where the phone sits.
    f_pill = font(19, "medium")
    x, y = 52, 262
    for p in ["Expenses", "Budgets", "Charts", "Dark mode", "CSV export", "₹ formatting"]:
        b = d.textbbox((0, 0), p, font=f_pill)
        w = b[2] - b[0] + 28
        if x + w > 690:
            x, y = 52, y + 48
        d.rounded_rectangle([(x, y), (x + w, y + 36)], 4, outline=(115, 115, 115), width=1)
        d.text((x + 14, y + 8 - b[1] // 2), p, font=f_pill, fill=(245, 245, 245))
        x += w + 10

    f_badge = font(19, "bold")
    x, y = 52, y + 66
    for bdg, fill, ink in [("Free", (255, 255, 255), (0, 0, 0)), ("No ads", TEAL[0], (255, 255, 255))]:
        b = d.textbbox((0, 0), bdg, font=f_badge)
        w = b[2] - b[0] + 32
        d.rounded_rectangle([(x, y), (x + w, y + 40)], 4, fill=fill)
        d.text((x + 16, y + 10 - b[1] // 2), bdg, font=f_badge, fill=ink)
        x += w + 10

    shot = rounded(Image.open(os.path.join(SRC, "1.webp")), SHOT_RADIUS)
    r = 430 / shot.height
    shot = shot.resize((int(shot.width * r), 430), Image.LANCZOS)
    px, py = FW - shot.width - 70, (FH - shot.height) // 2
    frame = rounded(Image.new("RGB", (shot.width + 8, shot.height + 8), (64, 64, 64)), int(SHOT_RADIUS * r) + 4)
    fg.alpha_composite(frame, (px - 4, py - 4))
    fg.alpha_composite(shot, (px, py))
    fg.convert("RGB").save(os.path.join(HERE, "feature_graphic_1024x500.png"))
    print("wrote feature_graphic_1024x500.png")


if __name__ == "__main__":
    make_screenshots()
    make_feature_graphic(make_icons())
