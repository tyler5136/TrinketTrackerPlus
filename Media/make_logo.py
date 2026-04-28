"""Generate the TrinketTrackerPlus addon logo.

Design: A circular trinket medallion with a tracking reticle overlay
(crosshair + ticks), a glowing cyan gem core, and a '+' badge in the
upper-right indicating the 'Plus' identity. Dark background.
"""

from PIL import Image, ImageDraw, ImageFilter
from math import cos, sin, radians

SIZE = 512
SS = 4  # supersample factor for anti-aliased edges
W = SIZE * SS

CYAN = (0, 217, 255, 255)
CYAN_DIM = (0, 140, 180, 255)
CYAN_DEEP = (0, 80, 110, 255)
WHITE = (240, 250, 255, 255)
GOLD = (255, 200, 80, 255)
BG_TOP = (16, 22, 32, 255)
BG_BOT = (4, 8, 14, 255)
DARK_RING = (10, 14, 22, 255)


def vgrad(size, top, bot):
    img = Image.new("RGBA", size, top)
    px = img.load()
    h = size[1]
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(top[0] * (1 - t) + bot[0] * t)
        g = int(top[1] * (1 - t) + bot[1] * t)
        b = int(top[2] * (1 - t) + bot[2] * t)
        for x in range(size[0]):
            px[x, y] = (r, g, b, 255)
    return img


def main():
    img = vgrad((W, W), BG_TOP, BG_BOT)
    d = ImageDraw.Draw(img, "RGBA")

    cx = cy = W // 2

    # --- Outer ring (medallion bezel) ---
    R_OUT = int(W * 0.44)
    R_IN = int(W * 0.40)
    d.ellipse([cx - R_OUT, cy - R_OUT, cx + R_OUT, cy + R_OUT], fill=CYAN_DEEP)
    d.ellipse([cx - R_IN, cy - R_IN, cx + R_IN, cy + R_IN], fill=DARK_RING)

    # Bright bezel highlight ring (thin)
    R_HL = int(W * 0.405)
    d.ellipse(
        [cx - R_HL, cy - R_HL, cx + R_HL, cy + R_HL],
        outline=CYAN, width=int(W * 0.008),
    )

    # --- Tick marks around the bezel (12 ticks, like a tracker dial) ---
    tick_outer = int(W * 0.435)
    tick_inner = int(W * 0.41)
    tick_width = int(W * 0.012)
    for i in range(12):
        ang = radians(i * 30 - 90)
        x1 = cx + tick_outer * cos(ang)
        y1 = cy + tick_outer * sin(ang)
        x2 = cx + tick_inner * cos(ang)
        y2 = cy + tick_inner * sin(ang)
        col = CYAN if i % 3 == 0 else CYAN_DIM
        d.line([(x1, y1), (x2, y2)], fill=col, width=tick_width)

    # --- Reticle crosshair (4 short lines reaching toward center, with gap) ---
    reticle_outer = int(W * 0.36)
    reticle_inner = int(W * 0.18)
    reticle_w = int(W * 0.014)
    for ang_deg in (0, 90, 180, 270):
        ang = radians(ang_deg)
        x1 = cx + reticle_outer * cos(ang)
        y1 = cy + reticle_outer * sin(ang)
        x2 = cx + reticle_inner * cos(ang)
        y2 = cy + reticle_inner * sin(ang)
        d.line([(x1, y1), (x2, y2)], fill=CYAN, width=reticle_w)

    # --- Inner glow ring around gem ---
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    R_GLOW = int(W * 0.22)
    gd.ellipse(
        [cx - R_GLOW, cy - R_GLOW, cx + R_GLOW, cy + R_GLOW],
        fill=(0, 217, 255, 110),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=W * 0.04))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img, "RGBA")

    # --- Central gem (trinket core) — diamond/rhombus shape ---
    gem_r = int(W * 0.16)
    gem = [
        (cx, cy - gem_r),
        (cx + int(gem_r * 0.78), cy),
        (cx, cy + gem_r),
        (cx - int(gem_r * 0.78), cy),
    ]
    d.polygon(gem, fill=CYAN_DIM, outline=WHITE)

    # Gem facet highlights (top half lighter)
    top_half = [(cx, cy - gem_r), (cx + int(gem_r * 0.78), cy), (cx, cy)]
    d.polygon(top_half, fill=CYAN)
    left_top = [(cx, cy - gem_r), (cx - int(gem_r * 0.78), cy), (cx, cy)]
    d.polygon(left_top, fill=(120, 235, 255, 255))

    # Gem outline emphasis
    d.line(gem + [gem[0]], fill=WHITE, width=int(W * 0.006))
    # Center crossline for facet
    d.line([(cx - int(gem_r * 0.78), cy), (cx + int(gem_r * 0.78), cy)],
           fill=WHITE, width=int(W * 0.004))

    # Tiny sparkle in upper-left of gem
    sx, sy = cx - int(gem_r * 0.25), cy - int(gem_r * 0.45)
    sr = int(W * 0.012)
    d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=WHITE)

    # --- "+" badge in upper-right ---
    bx = cx + int(W * 0.30)
    by = cy - int(W * 0.30)
    badge_r = int(W * 0.085)
    # Badge soft shadow
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse([bx - badge_r - 6, by - badge_r + 4,
                bx + badge_r - 6, by + badge_r + 4],
               fill=(0, 0, 0, 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=W * 0.015))
    img = Image.alpha_composite(img, shadow)
    d = ImageDraw.Draw(img, "RGBA")

    # Badge body (gold to pop against cyan)
    d.ellipse([bx - badge_r, by - badge_r, bx + badge_r, by + badge_r],
              fill=GOLD, outline=WHITE, width=int(W * 0.008))
    # Plus sign
    plus_arm = int(badge_r * 0.55)
    plus_w = int(badge_r * 0.30)
    d.rectangle([bx - plus_arm, by - plus_w // 2,
                 bx + plus_arm, by + plus_w // 2], fill=(40, 25, 5, 255))
    d.rectangle([bx - plus_w // 2, by - plus_arm,
                 bx + plus_w // 2, by + plus_arm], fill=(40, 25, 5, 255))

    # Downsample for anti-aliasing
    final = img.resize((SIZE, SIZE), Image.LANCZOS)
    final.save("icon.png", "PNG")

    # Also produce a 256 and 64 variant for in-game / favicon use
    final.resize((256, 256), Image.LANCZOS).save("icon_256.png", "PNG")
    final.resize((64, 64), Image.LANCZOS).save("icon_64.png", "PNG")
    print("Wrote icon.png (512), icon_256.png, icon_64.png")


if __name__ == "__main__":
    main()
