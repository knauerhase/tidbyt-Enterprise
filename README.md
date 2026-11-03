# Tidbyt Enterprise

A sweeping-by USS Enterprise (original series) for the [Tidbyt](https://tidbyt.com) 64x32 display,
written in Starlark for [Pixlet](https://github.com/tidbyt/pixlet).

The ship drifts across a starfield, then goes to warp. The show has three short **parts**, each sized to fit one
display slot (about 10 seconds), so install the app up to three times and drag them next to each other:

| Part | Scenes | Length |
|------|--------|--------|
| 1: Flyby (default) | side pass going right, top pass going left | 7.2 s |
| 2: Skirmish | diagonal pass, then a battle: a Klingon D7 closes, blue phasers fire, it blows up | 8.8 s |
| 3: Head-on | the Enterprise approaches (NCC-1701 fades in, full-screen white-out), then recedes and vanishes | 6.6 s |
| Surprise me | two different scenes picked at random | up to 8.8 s |

Settings in the Tidbyt app: **Part of the show**, and **Reverse direction** (flip the side, top and diagonal passes).
Smooth (2x2 anti-aliased) edges are always on.

## Run it

    pixlet serve enterprise.star                 # preview at http://localhost:8080
    pixlet render enterprise.star part=skirmish -o enterprise.webp
    pixlet push --installation-id Enterprise2 <device-id> enterprise.webp

Installation IDs must be alphanumeric. A pushed image is a fixed animation: it plays for the device's display time and ignores
`show_full_animation` and the settings form, which only apply to apps published in the community store. To see all three parts on a
device by push, push three installations (`Enterprise1`..`Enterprise3` with `part=flyby`, `part=skirmish`, `part=headon`) and drag them together.

### Command-line options

| key | values | default |
|-----|--------|---------|
| `part` | `flyby`, `skirmish`, `headon`, `surprise` | `flyby` |
| `reverse` | `true` / `false` | `false` |
| `smooth` | `true` (2x2 anti-aliased angled views) or `false` (crisp) | `true` |
| `scene1`, `scene2`, `scene3` | `all` (full 22 s show, scene1 only), `side`, `top`, `bottom`, `diagonal`, `battle`, `approach`, `recede`, `random`, `none` | unset |
| `direction` | `both` (alternate), `right`, `left` (with `scene1`..`scene3`) | `both` |

`scene1`..`scene3` (and the older single `view=` key) are for scripting and tinkering and don't appear in the phone app's
settings by default; set `SHOW_ADVANCED_SETTINGS = True` in `enterprise.star` to show them (plus Direction and Smooth edges) in the form.
Setting any scene overrides `part`. Scene lengths: side/top/bottom/diagonal 3.6 s per pass, battle 5.2 s, approach and
recede 3.3 s.

## Pushing to your device

Put your device ID and API key in `~/.config/tidbyt/env` (chmod 600):

    export TIDBYT_DEVICE_ID=...
    export TIDBYT_API_KEY=...

Installation IDs must be alphanumeric. `tools/push-random.sh` renders a random view and direction and pushes it
quietly (in the background) as installation `Enterprise`; run it from cron for a varied flyby. `DRY_RUN=1` renders without pushing.

## Modding

- Side, top and bottom are pixel sprites built in `build_side()` and `build_plan()` (the side view includes the far nacelle).
- Diagonal, approach and recede use a small shape model (`model_top()`, `model_face()`):
  circles, capsules and segments, rotated and scaled per frame.
- Keep the rendered WebP under 192 KiB, the Tidbyt push limit.

Inspired by an Enterprise flyby I wrote for a Pimoroni Unicorn HAT HD.

## License

MIT, see LICENSE.
