#!/usr/bin/env python3
"""Build the acreetion-anim Plymouth theme assets.

Layers:
  acreetion-base.png  1920x1080 canvas, logo with the plume cut out (transparent)
  flare-NN.png        ignition frames, cropped sprite (plume + prerendered glow)
  flare-hot.png       bright plume frame for the loop shimmer
  glow.png            radial gradient sprite for the eye shimmer
"""
import numpy as np
from PIL import Image, ImageFilter
from collections import deque
import os

# Regenerates every sprite in this directory from the static theme's PNG.
# Run from this directory:  python3 generate-frames.py
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = HERE
SRC = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/plymouth/themes/acreetion/acreetion.png'
os.makedirs(OUT, exist_ok=True)
N_FLARE = 20          # ignition frames
FEATHER = 36          # px of soft edge at the reveal line
GLOW_PAD = 100        # px of room around the plume for the prerendered glow

im = Image.open(SRC).convert('RGBA')
a = np.array(im).astype(np.float64)
R, G, B, A = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
H, W = R.shape

# ---------------------------------------------------------------- flare mask
red = (R > G * 1.12 + 6) & (R > B * 1.05 + 6) & (A > 30)
whiteish = (A > 200) & (R > 190) & (G > 190) & (B > 190)
mask = red | whiteish
seen = np.zeros_like(mask, bool)
q = deque([(880, 960)])
seen[880, 960] = True
while q:
    y, x = q.popleft()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ny, nx = y + dy, x + dx
        if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not seen[ny, nx]:
            seen[ny, nx] = True
            q.append((ny, nx))

fys, fxs = np.where(seen)
y_top, y_bot = fys.min(), fys.max()
x_min, x_max = fxs.min(), fxs.max()
print(f'plume: x {x_min}-{x_max}  y {y_top}-{y_bot}  px {seen.sum()}')

def dilate(m, it):
    out = m.copy()
    for _ in range(it):
        out = out | np.roll(out, 1, 0) | np.roll(out, -1, 0) \
                 | np.roll(out, 1, 1) | np.roll(out, -1, 1)
    return out

# cut slightly wider than the flood mask so the plume's own anti-aliased
# edge travels with the sprite instead of leaving a dark seam on the base
cut = dilate(seen, 2)

# ------------------------------------------------------------- base (no plume)
base = a.copy()
base[cut, 3] = 0.0
Image.fromarray(base.astype(np.uint8), 'RGBA').save(f'{OUT}/acreetion-base.png')

# flare sprite crop, with room for the prerendered glow
cx0, cy0 = max(x_min - GLOW_PAD, 0), max(y_top - GLOW_PAD, 0)
cx1, cy1 = min(x_max + GLOW_PAD, W), min(y_bot + GLOW_PAD, H)
cw, ch = cx1 - cx0, cy1 - cy0
print(f'flare sprite crop: ({cx0},{cy0})-({cx1},{cy1})  {cw}x{ch}')

crop = a[cy0:cy1, cx0:cx1]
local_cut = cut[cy0:cy1, cx0:cx1]
local_seen = seen[cy0:cy1, cx0:cx1]

# plume pixels only (original colours + alpha)
flare_base = crop.copy()
flare_base[~local_cut, 3] = 0.0

y_bot_l = y_bot - cy0
y_top_l = y_top - cy0

halo_full = None

def ambient_halo(alpha, scale):
    """Red halo radiating from the whole plume shape."""
    blur = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(26 * scale))
    h = np.array(blur).astype(np.float64) / 255.0
    halo = np.zeros((*h.shape, 4))
    halo[:, :, 0] = 255
    halo[:, :, 1] = 90
    halo[:, :, 2] = 70
    halo[:, :, 3] = np.clip(h * 190, 0, 255)
    return halo

def compose_frame(p, bright=1.0, halo_scale=1.0, head_heat=1.0):
    """One ignition frame. p in [0,1]: 0 nothing lit, 1 fully lit."""
    out = np.zeros((ch, cw, 4))
    if p <= 0:
        return out
    head = y_bot_l - p * (y_bot_l - y_top_l)      # reveal line, bottom -> top
    yy = np.arange(ch).reshape(-1, 1)
    # plume fades in over FEATHER px below the reveal line
    factor = np.clip((yy - head) / FEATHER, 0, 1)
    vis = (flare_base[:, :, 3] > 0) & (factor > 0)
    boost = 1 + head_heat * 0.9 * np.exp(-((yy - head) / 42) ** 2)   # per-row head heat
    out[:, :, :3] = np.clip(flare_base[:, :, :3]
                            * np.maximum(bright, 1.0) * boost[:, :, None], 0, 255)
    out[:, :, 3] = np.where(vis, flare_base[:, :, 3] * factor, 0)

    if halo_scale > 0:
        glow_alpha = np.zeros((ch, cw))
        band = np.clip(1 - np.abs(yy - head) / 70, 0, 1)          # hot band at the head
        glow_alpha = np.maximum(glow_alpha, local_seen * band)
        halo = ambient_halo((local_seen * 255).astype(np.uint8), halo_scale)
        glow_band = ambient_halo((np.maximum(local_seen * band, 0) * 255).astype(np.uint8), 0.7)
        out = np.clip(out + halo * min(p, 1.0) + glow_band, 0, 255)
    return out

for k in range(N_FLARE):
    p = k / (N_FLARE - 1)
    if k == N_FLARE - 1:
        # settled: exactly the original plume look -- no head heat, no halo
        frame = compose_frame(1.0, bright=1.0, halo_scale=0.0, head_heat=0.0)
    else:
        # brief overshoot just before the plume completes, then settle
        bright = 1.0 + 0.35 * max(0.0, p - 0.85) / 0.15
        frame = compose_frame(p, bright=bright, halo_scale=min(1.0, 0.25 + p))
    Image.fromarray(frame.astype(np.uint8), 'RGBA').save(f'{OUT}/flare-{k:02d}.png')

# flare-hot: the settled plume, brighter, for the loop shimmer
hot = compose_frame(1.0, bright=1.5, halo_scale=1.3, head_heat=0.0)
Image.fromarray(hot.astype(np.uint8), 'RGBA').save(f'{OUT}/flare-hot.png')

# ------------------------------------------------------------------ eye glow
ECX, ECY, ECR = 950, 350, 150          # outer eye ring centre / radius
gx0, gy0, gx1, gy1 = ECX - 190, ECY - 190, ECX + 190, ECY + 190
glow = np.zeros((gy1 - gy0, gx1 - gx0, 4))
yy, xx = np.mgrid[gy0:gy1, gx0:gx1]
r = np.sqrt((xx - ECX) ** 2 + (yy - ECY) ** 2) / ECR
core = np.clip(1 - r, 0, 1) ** 2
glow[:, :, 0] = 205
glow[:, :, 1] = 225
glow[:, :, 2] = 255
glow[:, :, 3] = np.clip(core * 255, 0, 255)
Image.fromarray(glow.astype(np.uint8), 'RGBA').save(f'{OUT}/glow.png')

print('eye glow crop:', gx0, gy0, gx1, gy1)
print('assets written to', OUT)
