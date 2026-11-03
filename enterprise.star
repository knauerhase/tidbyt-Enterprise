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

def build_side():
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

def build_plan(bottom):
    """Plan view (looking down on the ship, or up at its belly), facing right."""
    sw = 40
    sh = 19
    g = [["." for _ in range(sw)] for _ in range(sh)]

    def put(row, col, text):
        for i in range(len(text)):
            g[row][col + i] = text[i]

    # nacelles at the sides, with pylons joining them to the hull
    for top_row, shade_row in ((1, 2), (16, 17)):
        put(top_row, 3, "nnnnnnnnnnnnnn")
        put(top_row, 17, "b")
        put(shade_row, 3, "NNNNNNNNNNNNNN")
        put(shade_row, 17, "b")
    for r in range(3, 8):
        put(r, 12, "pp")
    for r in range(11, 16):
        put(r, 12, "pp")
    # secondary hull (mostly hidden behind the saucer)
    put(8, 9, "eeeeeeeeeeeeeeeeee")
    put(9, 9, "eeeeeeeeeeeeeeeeee")
    put(10, 9, "EEEEEEEEEEEEEEEEEE")
    # saucer: a disc centred at (31, 9)
    for r in range(sh):
        for c in range(sw):
            d2 = (c - 31) * (c - 31) + (r - 9) * (r - 9)
            if d2 > 54:
                continue
            ch = "S"
            if d2 > 31:
                ch = "s"
            if bottom:
                if d2 <= 6:
                    ch = "k"  # neck where it joins the hull
                elif d2 >= 17 and d2 <= 24:
                    ch = "E"  # underside ring
            elif d2 <= 4:
                ch = "d"  # bridge dome
            g[r][c] = ch
    return ["".join(r) for r in g]

def make_view(rows, streaks):
    return {"rows": rows, "w": len(rows[0]), "h": len(rows), "streaks": streaks}

# streaks: (row inside the sprite, distance of the tail from the sprite's rear edge)
VIEWS = {
    "side": make_view(build_side(), [(0, 2), (1, 2), (8, 9)]),
    "top": make_view(build_plan(False), [(1, 3), (2, 3), (16, 3), (17, 3), (9, 9)]),
    "bottom": make_view(build_plan(True), [(1, 3), (2, 3), (16, 3), (17, 3), (9, 9)]),
}

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

def ship_widgets(view, x0, y0, right, frame):
    """Boxes for the ship with its left edge at x0 (may be partly off-screen)."""
    out = []
    pulse = 90 + int(80 * (1 + sin(frame * 0.7)) / 2)
    bussard = "#ff" + hex2(pulse) + "00"
    for ry in range(view["h"]):
        row = view["rows"][ry]
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

def build_frame(view, f, right):
    sw = view["w"]
    y0 = (H - view["h"]) // 2
    s = f / (FRAMES - 1.0)
    prog = 0.55 * s + 0.45 * s * s * s * s  # gentle cruise, then warp
    speed = 0.4 + 2.2 * s * s * s
    span = W + sw + 6
    if right:
        x0 = int(-sw + prog * span)
    else:
        x0 = int(W - prog * span)

    kids = [render.Box(width = W, height = H, color = BG)]

    # stars slide opposite to the ship, faster as it speeds up
    drift = int((1 if right else -1) * f * (0.25 + 0.5 * s))
    for st in STARS:
        sx = (st[0] - drift) % W
        kids.append(box(sx, st[1], 1, 1, gray(st[2])))

    # warp streaks behind the nacelles and hull once it gets going
    if speed > 1.0:
        length = int(speed * 7)
        for row, off in view["streaks"]:
            tail = x0 + off if right else x0 + sw - off
            kids.extend(streak_widgets(tail, y0 + row, length, right))

    kids.extend(ship_widgets(view, x0, y0, right, f))
    return render.Stack(children = kids)

def passes(view_name, direction):
    """List of (view, right?) passes for the chosen view and direction."""
    names = ["side", "top", "bottom"] if view_name == "all" else [view_name]
    out = []
    for n in names:
        if direction != "left":
            out.append((VIEWS[n], True))
        if direction != "right":
            out.append((VIEWS[n], False))
    return out

def main(config):
    direction = config.str("direction", "both")
    view_name = config.str("view", "all")
    frames = []
    for view, right in passes(view_name, direction):
        frames += [build_frame(view, f, right) for f in range(FRAMES)]
    return render.Root(
        delay = DELAY,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "view",
                name = "View",
                desc = "Which angle to see the Enterprise from.",
                icon = "eye",
                default = "all",
                options = [
                    schema.Option(display = "All views", value = "all"),
                    schema.Option(display = "Side", value = "side"),
                    schema.Option(display = "Top", value = "top"),
                    schema.Option(display = "Bottom", value = "bottom"),
                ],
            ),
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
