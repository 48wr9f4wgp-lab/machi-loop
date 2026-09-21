#!/usr/bin/env python3
"""Check slice UI coverage in the requested charset and, optionally, a real font."""
from pathlib import Path
import argparse

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--font', type=Path)
args = parser.parse_args()
required = set()
for name in ('main_v40_land_acquisition.gd', 'main_v41_camera_navigation.gd', 'main_v42_playable_loop.gd', 'main_v43_tempo_payoff.gd'):
    required.update(c for c in (root / name).read_text(encoding='utf-8') if ord(c) > 127)
charset = set((root / 'assets/jp_charset.txt').read_text(encoding='utf-8'))
missing = required - charset
if missing:
    raise SystemExit('CHARSET_MISSING: ' + ''.join(sorted(missing)))
if args.font:
    from fontTools.ttLib import TTFont
    with TTFont(args.font) as font:
        cmap = font.getBestCmap()
        missing = {c for c in required if ord(c) not in cmap}
    if missing:
        raise SystemExit('FONT_CMAP_MISSING: ' + ''.join(sorted(missing)))
print(f'PLAYABLE_TEXT_OK characters={len(required)} font_checked={bool(args.font)}')
