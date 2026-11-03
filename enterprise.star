"""
Applet: Enterprise
Summary: TOS USS Enterprise flyby
Description: The original-series starship drifts across a starfield, then goes to warp.
Author: Robin Knauerhase
"""

load("render.star", "render")
load("schema.star", "schema")

W = 64
H = 32
FRAMES = 72
DELAY = 50  # ms per frame -> 3.6 s sweep

BG = "#00020e"

# Palette for the sprite characters.
COLORS = {
    "S": "#cdd1db",  # saucer top
    "s": "#8c91a0",  # saucer rim / underside
    "d": "#ebebf5",  # bridge dome
    "k": "#82879a",  # neck
    "e": "#aab0bb",  # engineering hull
    "E": "#646978",  # hull underside
    "D": "#ff9628",  # deflector dish
    "n": "#a0a5af",  # nacelle
    "N": "#6e7380",  # nacelle shadow
    "p": "#6e737d",  # pylon
}

def build_sprite():
    """Paint the side-view ship (facing right) into a grid of characters."""
    sw = 40
    sh = 12
    g = [["." for _ in range(sw)] for _ in range(sh)]

    def put(row, col, text):
        for i in range(len(text)):
            g[row][col + i] = text[i]

    # nacelle (bussard 'b' at the front, pulsed per frame)
    put(0, 2, "nnnnnnnnnnnnnn")
    put(0, 16, "b")
    put(1, 2, "NNNNNNNNNNNNNN")
    put(1, 16, "b")
    # pylon, slanting down toward the hull
    put(2, 7, "pp")
    put(3, 8, "pp")
    put(4, 9, "pp")
    put(5, 10, "pp")
    put(6, 11, "pp")
    # saucer
    put(1, 27, "dddd")
    put(2, 22, "sSSSSSSSSSSSSs")
    put(3, 20, "sSSSSSSSSSSSSSSSSs")
    put(4, 19, "SSSSSSSSSSSSSSSSSSSS")
    put(5, 21, "ssssssssssssssss")
    put(6, 24, "ssssssssss")
    # neck + secondary hull
    put(6, 21, "kk")
    put(7, 9, "eeeeeeeeeeeeee")
    put(8, 8, "eeeeeeeeeeeeeeee")
    put(9, 9, "EEEEEEEEEEEEEE")
    put(7, 23, "ee")
    put(8, 24, "D")
    put(9, 23, "E")
    return ["".join(r) for r in g]

SPRITE = build_sprite()
SPRITE_W = len(SPRITE[0])
SPRITE_H = len(SPRITE)

def runs(row):
    """Run-length encode a row string into [(char, start, length)]."""
    out = []
    i = 0
    for _ in range(len(row)):
        if i >= len(row):
            break
        j = i
        for _ in range(len(row)):
            if j < len(row) and row[j] == row[i]:
                j += 1
            else:
                break
        out.append((row[i], i, j - i))
        i = j
    return out

def box(x, y, w, h, color):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(width = w, height = h, color = color),
    )

def ship_widgets(x0, y0, right, frame):
    """Boxes for the ship with its left edge at x0 (may be partly off-screen)."""
    out = []
    pulse = 90 + int(80 * (1 + sin(frame * 0.7)) / 2)
    bussard = "#ff" + hex2(pulse) + "00"
    for ry in range(SPRITE_H):
        row = SPRITE[ry]
        if not right:
            row = row[::-1]
        for ch, start, n in runs(row):
            if ch == ".":
                continue
            color = bussard if ch == "b" else COLORS[ch]
            x = x0 + start
            lo = max(x, 0)
            hi = min(x + n, W)
            if hi > lo:
                out.append(box(lo, y0 + ry, hi - lo, 1, color))
    return out

def sin(x):
    """Small sine (Taylor, after range reduction) -- avoids loading math."""
    tau = 6.283185
    x = x - tau * int(x / tau)
    if x > 3.141593:
        x -= tau
    elif x < -3.141593:
        x += tau
    return x - x * x * x / 6 + x * x * x * x * x / 120 - x * x * x * x * x * x * x / 5040

def make_stars(n):
    """Deterministic pseudo-random star list [(x, y, brightness)]."""
    stars = []
    seed = 12345
    for _ in range(n):
        seed = (seed * 1103515245 + 12345) % 2147483648
        x = seed % W
        seed = (seed * 1103515245 + 12345) % 2147483648
        y = seed % H
        seed = (seed * 1103515245 + 12345) % 2147483648
        b = 70 + seed % 130
        stars.append((x, y, b))
    return stars

STARS = make_stars(22)

def hex2(v):
    digits = "0123456789abcdef"
    v = max(0, min(255, v))
    return digits[v // 16] + digits[v % 16]

def gray(b):
    return "#" + hex2(b) + hex2(b) + hex2(b + 12)

def streak_widgets(x_tail, y, length, right):
    """Fading warp streak trailing behind x_tail on row y."""
    out = []
    shades = ["#9ec0ff", "#6a96ff", "#3c64d2", "#1e3c8c"]
    seg = max(1, length // len(shades))
    for i in range(len(shades)):
        if right:
            hi = x_tail - i * seg
            lo = hi - seg
        else:
            lo = x_tail + i * seg
            hi = lo + seg
        lo = max(lo, 0)
        hi = min(hi, W)
        if hi > lo:
            out.append(box(lo, y, hi - lo, 1, shades[i]))
    return out

def build_frame(f, right, y0):
    s = f / (FRAMES - 1.0)
    prog = 0.55 * s + 0.45 * s * s * s * s  # gentle cruise, then warp
    speed = 0.4 + 2.2 * s * s * s
    span = W + SPRITE_W + 6
    if right:
        x0 = int(-SPRITE_W + prog * span)
    else:
        x0 = int(W - prog * span)

    kids = [render.Box(width = W, height = H, color = BG)]

    # stars slide opposite to the ship, faster as it speeds up
    drift = int((1 if right else -1) * f * (0.25 + 0.5 * s))
    for st in STARS:
        sx = (st[0] - drift) % W
        kids.append(box(sx, st[1], 1, 1, gray(st[2])))

    # warp streaks behind nacelle and hull once it gets going
    if speed > 1.0:
        length = int(speed * 7)
        if right:
            nac_tail = x0 + 2
            hull_tail = x0 + 9
        else:
            nac_tail = x0 + SPRITE_W - 2
            hull_tail = x0 + SPRITE_W - 9
        kids.extend(streak_widgets(nac_tail, y0, length, right))
        kids.extend(streak_widgets(nac_tail, y0 + 1, length, right))
        kids.extend(streak_widgets(hull_tail, y0 + 8, length, right))

    kids.extend(ship_widgets(x0, y0, right, f))
    return render.Stack(children = kids)

def main(config):
    direction = config.str("direction", "both")
    y0 = (H - SPRITE_H) // 2
    frames = []
    if direction != "left":
        frames += [build_frame(f, True, y0) for f in range(FRAMES)]
    if direction != "right":
        frames += [build_frame(f, False, y0) for f in range(FRAMES)]
    return render.Root(
        delay = DELAY,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Which way the Enterprise flies.",
                icon = "arrowsLeftRight",
                default = "both",
                options = [
                    schema.Option(display = "Alternate", value = "both"),
                    schema.Option(display = "Left to right", value = "right"),
                    schema.Option(display = "Right to left", value = "left"),
                ],
            ),
        ],
    )
