"""
Applet: Enterprise
Summary: TOS USS Enterprise flyby
Description: The original-series starship drifts across a starfield, then goes to warp.
Author: Robin Knauerhase
"""

load("render.star", "render")
load("math.star", "math")
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
    for i in range(4):
        put(3 + i, 13 - i, "pp")
        put(15 - i, 13 - i, "pp")
    # secondary hull (mostly hidden behind the saucer)
    put(7, 8, "eeeeeeeeeeeeeeeee")
    put(8, 6, "eeeeeeeeeeeeeeeeeeee")
    put(9, 6, "eeeeeeeeeeeeeeeeeeee")
    put(10, 6, "EEEEEEEEEEEEEEEEEEEE")
    put(11, 8, "EEEEEEEEEEEEEEEEE")
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
    return math.sin(x)

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


# ---------------------------------------------------------------------------
# Shape models for the angled and head-on views.  The ship is a few circles,
# capsules and segments in "ship coordinates" (nose toward +x); each frame we
# rotate/scale it onto the 64x32 grid, pixel by pixel.
# ---------------------------------------------------------------------------
GR = "#afb4be"
DK = "#737884"
SA = "#cdd2dc"
RED = "#ff3200"
ORG = "#ff9628"
WH = "#f0f0fa"
GLOW = "#5a8cff"

def disc(cx, cy, r, color):
    return ("disc", cx, cy, r * r, color)

def cap(x0, x1, y, r, color):
    return ("cap", x0, x1, y, r * r, color)

def seg(ax, ay, bx, by, r, color):
    dx = bx - ax
    dy = by - ay
    return ("seg", ax, ay, dx, dy, dx * dx + dy * dy, r * r, color)

def ell(cx, cy, rx, ry, color):
    return ("ell", cx, cy, 1.0 / (rx * rx), 1.0 / (ry * ry), color)

def model_top():
    out = []
    for sd in (-1, 1):
        out.append(cap(-6.2, -1.6, sd * 2.6, 0.55, GR))
    for sd in (-1, 1):
        out.append(disc(-1.6, sd * 2.6, 0.6, "b"))
    for sd in (-1, 1):
        out.append(seg(-3.2, sd * 0.4, -4.4, sd * 2.5, 0.3, DK))
    out.append(cap(-4.8, 0.5, 0, 0.75, DK))
    out.append(disc(2.6, 0, 3.0, SA))
    out.append(disc(2.6, 0, 0.5, WH))
    return out

def model_face(rear):
    nac = GLOW if rear else "b"
    out = []
    for sd in (-1, 1):
        out.append(seg(sd * 0.4, -1.7, sd * 2.5, 0.9, 0.25, DK))
    out.append(seg(0, -0.2, 0, -1.6, 0.3, DK))
    out.append(disc(0, -2.0, 0.75, GR))
    if not rear:
        out.append(disc(0, -2.0, 0.4, ORG))
    for sd in (-1, 1):
        out.append(disc(sd * 2.5, 0.9, 0.6, nac))
    out.append(ell(0, 0, 3.0, 0.45, SA))
    if not rear:
        out.append(ell(0, 0.45, 0.6, 0.35, WH))
    return out

MODEL_TOP = model_top()
MODEL_FACE = model_face(False)
MODEL_REAR = model_face(True)

def hit(shapes, px, py):
    """Colour of the topmost shape covering (px, py), or None."""
    for i in range(len(shapes) - 1, -1, -1):
        sh = shapes[i]
        k = sh[0]
        if k == "disc":
            dx = px - sh[1]
            dy = py - sh[2]
            if dx * dx + dy * dy <= sh[3]:
                return sh[4]
        elif k == "cap":
            dx = px - min(max(px, sh[1]), sh[2])
            dy = py - sh[3]
            if dx * dx + dy * dy <= sh[4]:
                return sh[5]
        elif k == "seg":
            dx = px - sh[1]
            dy = py - sh[2]
            t = min(max((dx * sh[3] + dy * sh[4]) / sh[5], 0.0), 1.0)
            ex = dx - t * sh[3]
            ey = dy - t * sh[4]
            if ex * ex + ey * ey <= sh[6]:
                return sh[7]
        else:
            dx = px - sh[1]
            dy = py - sh[2]
            if dx * dx * sh[3] + dy * dy * sh[4] <= 1.0:
                return sh[5]
    return None

def draw_model(shapes, cx, cy, ang, scale, frame, flipv, ss):
    """Boxes for the model centred at (cx, cy), heading ang degrees (0 = right).
    ss = 1 samples each pixel once (crisp); ss = 2 averages 2x2 samples (smooth)."""
    a = ang * math.pi / 180.0
    ca = math.cos(a)
    sa = math.sin(a)
    inv = 1.0 / scale
    r = int(scale * 7.2) + 1
    x_lo = max(0, int(cx) - r)
    x_hi = min(W, int(cx) + r + 1)
    y_lo = max(0, int(cy) - r)
    y_hi = min(H, int(cy) + r + 1)
    pulse = 90 + int(80 * (1 + sin(frame * 0.7)) / 2)
    bussard = "#ff" + hex2(pulse) + "00"
    out = []
    for yy in range(y_lo, y_hi):
        run_col = None
        run_start = x_lo
        for xx in range(x_lo, x_hi + 1):
            col = None
            if xx < x_hi:
                if ss == 1:
                    dx = xx + 0.5 - cx
                    dy = yy + 0.5 - cy
                    px = (dx * ca + dy * sa) * inv
                    py = (dy * ca - dx * sa) * inv
                    if flipv:
                        py = -py
                    col = hit(shapes, px, py)
                    if col == "b":
                        col = bussard
                else:
                    # 2x2 supersampling: average four samples (misses count as sky)
                    tr = 0
                    tg = 0
                    tb = 0
                    nhit = 0
                    for sy in (0.25, 0.75):
                        for sx in (0.25, 0.75):
                            dx = xx + sx - cx
                            dy = yy + sy - cy
                            px = (dx * ca + dy * sa) * inv
                            py = (dy * ca - dx * sa) * inv
                            if flipv:
                                py = -py
                            c = hit(shapes, px, py)
                            if c == "b":
                                c = bussard
                            if c == None:
                                tg += 2
                                tb += 14
                            else:
                                nhit += 1
                                tr += int(c[1:3], 16)
                                tg += int(c[3:5], 16)
                                tb += int(c[5:7], 16)
                    if nhit > 0:
                        col = "#" + hex2(tr // 4) + hex2(tg // 4) + hex2(tb // 4)
            if col != run_col:
                if run_col != None:
                    out.append(box(run_start, yy, xx - run_start, 1, run_col))
                run_start = xx
                run_col = col
    return out

def lcg(seed):
    return (seed * 1103515245 + 12345) % 2147483648

def star_boxes(stars):
    return [box(st[0], st[1], 1, 1, gray(st[2])) for st in stars if (0 <= st[0] and st[0] < W and 0 <= st[1] and st[1] < H)]

def build_diag_frame(f, ang, ss):
    """Plan-view ship crossing the panel diagonally at heading ang."""
    s = f / (FRAMES - 1.0)
    prog = 0.55 * s + 0.45 * s * s * s * s
    speed = 0.4 + 2.2 * s * s * s
    a = ang * math.pi / 180.0
    fx = math.cos(a)
    fy = math.sin(a)
    sc = 2.5
    total = 2 * (abs(fx) * 32 + abs(fy) * 16 + sc * 7.2)
    d = total * prog
    cx = 32 - fx * total / 2 + fx * d - fy * 2
    cy = 16 - fy * total / 2 + fy * d + fx * 2

    kids = [render.Box(width = W, height = H, color = BG)]
    k = f * (0.25 + 0.5 * s)
    kids.extend(star_boxes([((st[0] - int(fx * k)) % W, (st[1] - int(fy * k)) % H, st[2]) for st in STARS]))

    if speed > 1.0:
        n = int(speed * 7)
        for sd in (-1, 1):
            tx = cx + sc * (-6.4 * fx - sd * 2.6 * fy)
            ty = cy + sc * (-6.4 * fy + sd * 2.6 * fx)
            for i in range(1, n):
                fade = 1.0 - i / float(n)
                kids.append(box(int(tx - fx * i), int(ty - fy * i), 1, 1, "#" + hex2(int(120 * fade)) + hex2(int(160 * fade)) + hex2(int(255 * fade))))
                if int(tx - fx * i) < 0 or int(tx - fx * i) >= W:
                    break
    kids.extend(draw_model(MODEL_TOP, cx, cy, ang, sc, f, False, ss))
    return render.Stack(children = kids)

APPROACH_FRAMES = 60
RECEDE_FRAMES = 60

def burst_stars(nf):
    """Per-frame star positions streaming outward from the centre."""
    seed = 777
    st = []
    for _ in range(24):
        seed = lcg(seed)
        x = seed % W
        seed = lcg(seed)
        y = seed % H
        seed = lcg(seed)
        st.append([float(x), float(y), 70 + seed % 130])
    out = []
    for f in range(nf):
        s = f / (nf - 1.0)
        sp = 0.25 + 1.2 * s
        cur = []
        for t in st:
            dx = t[0] - 32.0
            dy = t[1] - 16.0
            d = math.sqrt(dx * dx + dy * dy) + 0.3
            step = sp * (0.3 + d / 20.0) / d
            t[0] += dx * step
            t[1] += dy * step
            if t[0] < 0 or t[0] >= W or t[1] < 0 or t[1] >= H:
                seed = lcg(seed)
                t[0] = 32.0 + seed % 7 - 3
                seed = lcg(seed)
                t[1] = 16.0 + seed % 5 - 2
            cur.append((int(t[0]), int(t[1]), int(t[2] * min(1.0, d / 10.0))))
        out.append(cur)
    return out

def approach_frames(ss):
    stars = burst_stars(APPROACH_FRAMES)
    frames = []
    for f in range(APPROACH_FRAMES):
        s = f / (APPROACH_FRAMES - 1.0)
        sc = 0.12 * math.pow(58.0, s)
        kids = [render.Box(width = W, height = H, color = BG)]
        kids.extend(star_boxes(stars[f]))
        kids.extend(draw_model(MODEL_FACE, 32, 17, 0, sc, f, True, ss))
        frames.append(render.Stack(children = kids))
    for i in range(6):  # it whooshes past: white-out that fades
        k = 1.0 - i / 6.0
        c = "#" + hex2(int(240 * k)) + hex2(int(240 * k)) + hex2(int(250 * k + 14 * (1 - k)))
        frames.append(render.Box(width = W, height = H, color = c))
    return frames

def recede_frames(ss):
    frames = []
    for f in range(RECEDE_FRAMES):
        s = f / (RECEDE_FRAMES - 1.0)
        sc = 7.0 * math.pow(0.03, s)
        kids = [render.Box(width = W, height = H, color = BG)]
        kids.extend(star_boxes(STARS))
        kids.extend(draw_model(MODEL_REAR, 32, 17 - 4 * s, 0, sc, f, True, ss))
        frames.append(render.Stack(children = kids))
    # warp flash where it disappears
    for i in range(8):
        k = 1.0 - i / 8.0
        kids = [render.Box(width = W, height = H, color = BG)]
        kids.extend(star_boxes(STARS))
        hw = int(2 + 12 * k)
        hh = int(1 + 5 * k)
        glow = "#" + hex2(int(150 * k)) + hex2(int(200 * k)) + hex2(int(255 * k))
        kids.append(box(32 - hw, 13, 2 * hw, 1, glow))
        kids.append(box(32, 13 - hh, 1, 2 * hh, glow))
        r = int(1 + 3 * k)
        kids.append(box(32 - r, 13 - r, 2 * r + 1, 2 * r + 1, "#" + hex2(int(255 * k)) * 3))
        frames.append(render.Stack(children = kids))
    return frames

def make_pass(name, right):
    if name in VIEWS:
        return ("sprite", VIEWS[name], right)
    if name == "diagonal":
        return ("diag", -28 if right else 152, right)
    return (name, None, right)

def passes(view_name, direction):
    """List of passes to string together for the chosen view and direction."""
    out = []
    if view_name == "all":
        seq = ["side", "top", "bottom", "diagonal", "approach", "recede"]
        for i in range(len(seq)):
            right = (i % 2 == 0) if direction == "both" else (direction == "right")
            out.append(make_pass(seq[i], right))
    elif view_name in ("approach", "recede"):
        out.append(make_pass(view_name, True))
    else:
        if direction != "left":
            out.append(make_pass(view_name, True))
        if direction != "right":
            out.append(make_pass(view_name, False))
    return out

def main(config):
    direction = config.str("direction", "both")
    view_name = config.str("view", "all")
    ss = 2 if config.bool("smooth", True) else 1
    frames = []
    for kind, arg, right in passes(view_name, direction):
        if kind == "sprite":
            frames += [build_frame(arg, f, right) for f in range(FRAMES)]
        elif kind == "diag":
            frames += [build_diag_frame(f, arg, ss) for f in range(FRAMES)]
        elif kind == "approach":
            frames += approach_frames(ss)
        else:
            frames += recede_frames(ss)
    return render.Root(
        delay = DELAY,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "smooth",
                name = "Smooth edges",
                desc = "Anti-alias the angled and head-on views (larger file).",
                icon = "wandMagicSparkles",
                default = True,
            ),
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
                    schema.Option(display = "Diagonal", value = "diagonal"),
                    schema.Option(display = "Approaching", value = "approach"),
                    schema.Option(display = "Receding", value = "recede"),
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
