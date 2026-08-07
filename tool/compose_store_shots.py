#!/usr/bin/env python3
"""Composes the raw captures into captioned store images.

Reads build/store_shots/<lang>/<screen>.png (see tool/store_shots.sh) and writes
build/store_shots/out/<store>/<lang>/<n>-<screen>.png.

Two sizes:
  appstore  1320x2868  the capture's own size, which App Store Connect accepts
                       for the required 6.9-inch slot
  play      1080x1920  Google Play phone

The background gradient is sampled from the app itself (#F7C9F5 to #DDE9FA) so
the frame and the screen inside it read as one image.

Fonts are chosen per language by coverage, and every caption is checked against
the font's cmap before drawing — a missing glyph renders as an empty box, which
is easy to miss in a language you do not read.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "build" / "store_shots"
OUT = RAW / "out"

SIZES = {"appstore": (1320, 2868), "play": (1080, 1920)}

TOP = (247, 201, 245)
BOTTOM = (221, 233, 250)
INK = (43, 32, 56)

FONTS = {
    # Full Hangul and Latin; the app's own body face.
    "ko": ROOT / "assets/fonts/Pretendard-Bold.otf",
    "en": ROOT / "assets/fonts/Pretendard-Bold.otf",
    # The app's Japanese display face: all kana plus 4,954 Han.
    "ja": ROOT / "assets/fonts/MPLUSRounded1c-Bold.ttf",
    # Simplified Chinese needs a face built for it; nothing bundled has enough
    # Han, and MPLUS covers only part of the Simplified set.
    "zh": Path("/System/Library/Fonts/Hiragino Sans GB.ttc"),
}

# Screen order is the order they appear in the listing.
#
# Settings is deliberately absent: a disabled "watch an ad" button sits across
# the top of it, in a loading state, which is the worst thing to lead a store
# listing with. The multilingual point it would have carried is made better by
# the friends screen, whose language chips actually show it.
SCREENS = ["chat", "friends", "words", "chats"]

CAPTIONS = {
    "ko": {
        "chat": "대화하면서\n자연스럽게 배워요",
        "friends": "네 가지 언어의 친구를\n직접 만들어요",
        "words": "저장한 표현으로\n카드 복습",
        "chats": "인터넷 없이\n기기 안에서 대화",
    },
    "ja": {
        "chat": "話しながら\n自然に身につく",
        "friends": "4つの言語の友だちを\n自分で作れる",
        "words": "保存した表現を\nカードで復習",
        "chats": "ネットなしで\n端末の中だけで会話",
    },
    "en": {
        "chat": "Learn a language\nby actually chatting",
        "friends": "Make friends in\nany of four languages",
        "words": "Review saved phrases\nas flashcards",
        "chats": "Runs on your device,\nwith no internet",
    },
    "zh": {
        "chat": "在聊天中\n自然学会",
        "friends": "创建四种语言的\n专属朋友",
        "words": "用收藏的表达\n卡片复习",
        "chats": "无需联网\n完全在设备上对话",
    },
}


def font_charset(path: Path) -> set[int]:
    """Every code point the font's cmap covers."""
    data = path.read_bytes()
    (tag,) = struct.unpack(">I", data[:4])
    base = 0
    if tag == 0x74746366:  # ttcf: use the first face
        (base,) = struct.unpack(">I", data[12:16])
    (count,) = struct.unpack(">H", data[base + 4 : base + 6])
    tables = {}
    for i in range(count):
        p = base + 12 + 16 * i
        name = data[p : p + 4].decode("latin1")
        offset, _length = struct.unpack(">II", data[p + 8 : p + 16])
        tables[name] = offset
    cmap = tables["cmap"]
    (n,) = struct.unpack(">H", data[cmap + 2 : cmap + 4])
    chosen = None
    for i in range(n):
        _pid, _eid, sub = struct.unpack(">HHI", data[cmap + 4 + 8 * i : cmap + 12 + 8 * i])
        (fmt,) = struct.unpack(">H", data[cmap + sub : cmap + sub + 2])
        if fmt in (4, 12):
            chosen = (fmt, cmap + sub)
            if fmt == 12:
                break
    fmt, sub = chosen
    chars: set[int] = set()
    if fmt == 4:
        (seg_x2,) = struct.unpack(">H", data[sub + 6 : sub + 8])
        seg = seg_x2 // 2
        ends = struct.unpack(f">{seg}H", data[sub + 14 : sub + 14 + seg_x2])
        sp = sub + 16 + seg_x2
        starts = struct.unpack(f">{seg}H", data[sp : sp + seg_x2])
        for s, e in zip(starts, ends):
            if s != 0xFFFF:
                chars.update(range(s, min(e, 0xFFFF) + 1))
    else:
        (groups,) = struct.unpack(">I", data[sub + 12 : sub + 16])
        for i in range(groups):
            s, e, _g = struct.unpack(">III", data[sub + 16 + 12 * i : sub + 28 + 12 * i])
            chars.update(range(s, e + 1))
    return chars


def gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    base = Image.new("RGB", (1, h))
    px = base.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        px[0, y] = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
    return base.resize((w, h), Image.BILINEAR)


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), img.size], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def compose(shot: Path, caption: str, font_path: Path, size: tuple[int, int]) -> Image.Image:
    w, h = size
    canvas = gradient(size).convert("RGBA")

    # Caption block across the top, then the screen below it, bleeding off the
    # bottom edge so the image reads as a device rather than a floating card.
    caption_top = round(h * 0.055)
    draw = ImageDraw.Draw(canvas)

    # Shrink until the longest line clears the margins. A caption sized purely
    # by canvas height ran to the edge in English, and a longer translation in
    # any language would have run past it.
    max_width = w * 0.86
    font_size = round(h * 0.042)
    lines = caption.split("\n")
    while font_size > 12:
        font = ImageFont.truetype(str(font_path), font_size)
        widest = max(draw.textlength(line, font=font) for line in lines)
        if widest <= max_width:
            break
        font_size -= 2
    line_gap = round(font_size * 0.30)

    y = caption_top
    for line in lines:
        box = draw.textbbox((0, 0), line, font=font)
        draw.text(
            ((w - (box[2] - box[0])) / 2 - box[0], y),
            line,
            font=font,
            fill=INK,
        )
        y += (box[3] - box[1]) + line_gap

    shot_img = Image.open(shot).convert("RGB")
    target_w = round(w * 0.80)
    target_h = round(target_w * shot_img.height / shot_img.width)
    shot_img = shot_img.resize((target_w, target_h), Image.LANCZOS)
    framed = rounded(shot_img, round(target_w * 0.055))

    x = (w - target_w) // 2
    # Follow the caption rather than sitting at a fixed fraction: a two-line
    # caption at a fixed offset left a band of empty gradient between the two,
    # and the gap would change again with a three-line translation.
    top = y - line_gap + round(h * 0.045)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow.paste(
        Image.new("RGBA", framed.size, (60, 30, 80, 90)),
        (x, top + round(h * 0.006)),
        framed,
    )
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(18)))
    canvas.paste(framed, (x, top), framed)
    return canvas.convert("RGB")


def main() -> int:
    if not RAW.exists():
        print(f"No captures in {RAW}; run tool/store_shots.sh first.", file=sys.stderr)
        return 1

    problems: list[str] = []
    charsets = {lang: font_charset(path) for lang, path in FONTS.items()}
    for lang, screens in CAPTIONS.items():
        missing = {
            ch
            for text in screens.values()
            for ch in text
            if ch != "\n" and ord(ch) not in charsets[lang]
        }
        if missing:
            problems.append(f"{lang}: {FONTS[lang].name} lacks {sorted(missing)}")
    if problems:
        # A missing glyph draws an empty box, which is easy to miss in a language
        # you cannot read — so refuse rather than ship it.
        print("\n".join(problems), file=sys.stderr)
        return 1

    written = 0
    for store, size in SIZES.items():
        for lang, screens in CAPTIONS.items():
            out_dir = OUT / store / lang
            out_dir.mkdir(parents=True, exist_ok=True)
            for index, screen in enumerate(SCREENS, start=1):
                shot = RAW / lang / f"{screen}.png"
                if not shot.exists():
                    print(f"missing capture: {shot}", file=sys.stderr)
                    continue
                image = compose(shot, screens[screen], FONTS[lang], size)
                image.save(out_dir / f"{index}-{screen}.png")
                written += 1
    print(f"Wrote {written} images to {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
