# tidbyt-enterprise

A sweeping-by USS Enterprise (original series) for the [Tidbyt](https://tidbyt.com) 64x32 display,
written in Starlark for [Pixlet](https://github.com/tidbyt/pixlet).

The ship drifts across a starfield, then goes to warp. Views: side, top, bottom, diagonal,
approaching, and receding, each flying left-to-right or right-to-left.

## Run it

    pixlet serve enterprise.star                 # preview at http://localhost:8080
    pixlet render enterprise.star -o enterprise.webp
    pixlet push --installation-id enterprise <device-id> enterprise.webp

Pass config on the command line, e.g. `pixlet render enterprise.star view=top direction=left`.

| key         | values                                                                 | default |
|-------------|------------------------------------------------------------------------|---------|
| `view`      | `all`, `side`, `top`, `bottom`, `diagonal`, `approach`, `recede`       | `all`   |
| `direction` | `both` (alternate), `right`, `left`                                    | `both`  |

The Tidbyt phone app only shows these dropdowns for a published or private app; a pushed image is fixed.

## Modding

- Side, top and bottom are pixel sprites built in `build_side()` and `build_plan()`.
- Diagonal, approach and recede use a small shape model (`model_top()`, `model_face()`):
  circles, capsules and segments, rotated and scaled per frame.
- Keep the rendered WebP under 192 KiB, the Tidbyt push limit.

Inspired by an Enterprise flyby I wrote for a Pimoroni Unicorn HAT HD.

## License

MIT, see LICENSE.
