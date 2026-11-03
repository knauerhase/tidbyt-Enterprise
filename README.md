# tidbyt-enterprise

A sweeping-by USS Enterprise (original series) for the [Tidbyt](https://tidbyt.com) 64x32 display,
written in Starlark for [Pixlet](https://github.com/tidbyt/pixlet).

The ship drifts across a starfield, then goes to warp. Views: side, top, bottom, diagonal,
battle, approaching, and receding. "All views" plays side, top, diagonal, battle, approach and recede (bottom is
nearly identical to top, so it's selectable on its own but left out of the loop). Side-view passes fly left-to-right or right-to-left over a drifting planet; the approach
shows the registry (NCC-1701) fading in and out before the ship fills the screen; the recede just vanishes.

## Run it

    pixlet serve enterprise.star                 # preview at http://localhost:8080
    pixlet render enterprise.star -o enterprise.webp
    pixlet push --installation-id enterprise <device-id> enterprise.webp

Pass config on the command line, e.g. `pixlet render enterprise.star view=top direction=left`.

| key         | values                                                                 | default |
|-------------|------------------------------------------------------------------------|---------|
| `scene1`    | `all` (full show), `side`, `top`, `bottom`, `diagonal`, `battle`, `approach`, `recede`, `random`, `none` | `all` |
| `scene2`, `scene3` | same scenes (no `all`); `none` skips the slot (ignored when `scene1=all`) | `none` |
| `direction` | `both` (alternate), `right`, `left`                                    | `both`  |
| `smooth`    | `true` (2x2 anti-aliased angled views, ~95 KB) or `false` (crisp, ~83 KB) | `true`  |

The Tidbyt phone app only shows these dropdowns for a published or private app; a pushed image is fixed.

### Choosing scenes

Pick one, two or three scenes with `scene1`..`scene3`, e.g. `scene1=battle scene2=approach scene3=recede`.
With one scene, `direction=both` flies it both ways; with several, "alternate" flips direction from scene to scene.
`random` picks one scene at render time. The old single `view=` key still works (it sets `scene1`).
Install the app more than once in the Tidbyt app to get different mixes, and drag them into any order.
Rough lengths: a side/top/bottom/diagonal pass 3.6 s each way, battle 5.2 s, approach and recede 3.3 s each.

## Pushing to your device

Put your device ID and API key in `~/.config/tidbyt/env` (chmod 600):

    export TIDBYT_DEVICE_ID=...
    export TIDBYT_API_KEY=...

Installation IDs must be alphanumeric. `tools/push-random.sh` renders a random view and direction and pushes it
quietly (in the background) as installation `enterprise`; run it from cron for a varied flyby. `DRY_RUN=1` renders without pushing.

## Modding

- Side, top and bottom are pixel sprites built in `build_side()` and `build_plan()` (the side view includes the far nacelle).
- Diagonal, approach and recede use a small shape model (`model_top()`, `model_face()`):
  circles, capsules and segments, rotated and scaled per frame.
- Keep the rendered WebP under 192 KiB, the Tidbyt push limit.

Inspired by an Enterprise flyby I wrote for a Pimoroni Unicorn HAT HD.

## License

MIT, see LICENSE.
