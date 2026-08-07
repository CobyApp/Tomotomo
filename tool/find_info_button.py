#!/usr/bin/env python3
"""Prints "x y" for the lowest study-sheet (i) button in a chat screenshot.

The button sits to the right of a reply and moves with the height of the
conversation above it, which differs per language, so the capture script finds
it by colour instead of assuming a coordinate. It is the only pale-blue disc on
the screen.

Exits non-zero when no button is found, so the caller notices rather than
tapping empty background and screenshotting the wrong thing.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

# The disc's fill, sampled from a real capture. It is very close to the page
# background's bottom gradient, so colour alone finds the whole lower half of the
# screen — the disc is identified by being a *bounded* run of that colour, a few
# dozen pixels wide, rather than by the colour itself.
TARGET = (222, 232, 251)
TOLERANCE = 8
MIN_RUN = 36
MAX_RUN = 110


def close(pixel: tuple[int, int, int]) -> bool:
    return all(abs(pixel[i] - TARGET[i]) <= TOLERANCE for i in range(3))


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: find_info_button.py <screenshot.png>", file=sys.stderr)
        return 2
    image = Image.open(Path(sys.argv[1])).convert("RGB")
    w, h = image.size
    px = image.load()

    # Right-hand quarter only: the discs live there, and nothing else on screen
    # shares the colour.
    x_from = int(w * 0.72)
    best: tuple[int, int] | None = None
    y = int(h * 0.08)
    while y < int(h * 0.85):
        run_start = None
        for x in range(x_from, w):
            if close(px[x, y]):
                if run_start is None:
                    run_start = x
            else:
                if run_start is not None and MIN_RUN <= x - run_start <= MAX_RUN:
                    best = ((run_start + x) // 2, y)
                run_start = None
        # A run reaching the right edge is the background, not a disc.
        y += 4

    if best is None:
        print("no (i) button found", file=sys.stderr)
        return 1
    # `best` is the last (lowest) disc's widest row, which is its centre line.
    print(f"{best[0]} {best[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
