"""Render a GDSII layout to a PNG you can actually show someone.

    python tools/render_gds.py openlane/titan_x5_fp32_fma/final/titan_x5_fp32_fma.gds

A GDS file is the end of the physical design flow -- the thing a foundry turns
into silicon -- and it is completely invisible until rendered. A picture of it
is the single most persuasive artefact this project has, because almost nobody
outside the industry has one of their own.

Uses KLayout's Python module, which draws exactly what its GUI would.
"""

from __future__ import annotations

import sys
from pathlib import Path

import klayout.db as db
import klayout.lay as lay


def render(gds_path: Path, out_path: Path, width: int = 2400,
           dark: bool = True, crop_um: float = 0.0,
           metals_only: bool = False) -> None:
    """Draw a GDS to PNG.

    ``crop_um`` renders a square window of that many microns from the centre
    instead of the whole die. This matters: a 478 um die drawn 2400 pixels wide
    puts every standard cell below one pixel, and 43 layers of sub-pixel detail
    average out to flat colour. Zooming in is the difference between a green
    rectangle and something that visibly looks like a chip.

    ``metals_only`` hides everything but routing, which is the view people
    recognise as "a chip layout".
    """
    layout_view = lay.LayoutView()
    layout_view.load_layout(str(gds_path), 0)
    layout_view.max_hier()

    # Black reads better for a layout: the metal layers are bright, and on a
    # white field they wash out into a grey mess.
    layout_view.set_config("background-color", "#000000" if dark else "#ffffff")
    layout_view.set_config("grid-visible", "false")
    layout_view.set_config("text-visible", "false")

    if metals_only:
        # sky130 routing layers. Everything below (diffusion, poly, contacts)
        # is what turns the full-die view into noise.
        keep = {67, 68, 69, 70, 71, 72}          # li1, met1..met5
        for layer in layout_view.each_layer():
            layer.visible = layer.source_layer in keep

    cell = layout_view.active_cellview().cell
    bbox = cell.dbbox()

    if crop_um > 0:
        half = crop_um / 2.0
        cx, cy = bbox.center().x, bbox.center().y
        target = db.DBox(cx - half, cy - half, cx + half, cy + half)
        layout_view.zoom_box(target)
        aspect = 1.0
    else:
        layout_view.zoom_fit()
        aspect = (bbox.height() / bbox.width()) if bbox.width() > 0 else 1.0

    # Give the drawing time to settle before capturing; without this the image
    # can come out half-rendered.
    layout_view.timer()
    height = max(200, int(width * aspect))

    # Signature is (file, w, h, linewidth, oversampling, resolution, target_box,
    # monochrome). An empty DBox means "whatever the view is currently showing",
    # which is what zoom_fit just set. Oversampling 3 is what makes the metal
    # tracks read as lines rather than aliased noise.
    try:
        layout_view.save_image_with_options(
            str(out_path), width, height, 0, 3, 0, db.DBox(), False
        )
    except TypeError:
        # Older bindings expose only the simple form.
        layout_view.save_image(str(out_path), width, height)

    print(f"  cell        : {cell.name}")
    print(f"  size        : {bbox.width():.1f} x {bbox.height():.1f} um")
    print(f"  layers      : {layout_view.active_cellview().layout().layers()}")
    print(f"  image       : {out_path}  ({width}x{height})")
    print(f"  file size   : {out_path.stat().st_size / 1024:.0f} KiB")


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    gds = Path(sys.argv[1])
    if not gds.exists():
        print(f"not found: {gds}")
        return 1

    assets = Path("docs/assets")
    assets.mkdir(parents=True, exist_ok=True)
    stem = gds.stem
    print(f"rendering {gds.name} ({gds.stat().st_size / 1048576:.0f} MB)\n")

    for label, kwargs, name in [
        ("full die, routing only", dict(metals_only=True), f"{stem}_layout.png"),
        ("120 um detail",          dict(crop_um=120.0),    f"{stem}_detail.png"),
        ("40 um close-up",         dict(crop_um=40.0),     f"{stem}_closeup.png"),
    ]:
        print(f"[{label}]")
        render(gds, assets / name, **kwargs)
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
