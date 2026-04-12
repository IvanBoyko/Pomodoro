#!/usr/bin/env python3
"""Pomodoro iOS App Icon Generator — Classic Kitchen Timer, Red/Warm, Minimal 3D"""

from PIL import Image, ImageDraw, ImageFilter
import numpy as np, math, os

S = 1024
CX = CY = S // 2

# Pre-compute coordinate grids (shared across all variants)
_yr, _xr = np.mgrid[0:S, 0:S]
_dx = _xr.astype(np.float32) - CX
_dy = _yr.astype(np.float32) - CY
_D  = np.hypot(_dx, _dy)


def make_icon(v='light'):
    palettes = {
        'light': dict(
            BG1=(52, 16, 11),   BG2=(18, 5, 3),
            BH=(238, 68, 44),   BL=(142, 22, 12),
            FC=(252, 244, 226),
            TH=(80, 28, 18),    TL=(158, 78, 62),
            LH=(232, 188, 68),  LL=(162, 122, 30),
            KH=(202, 160, 50),  KL=(145, 105, 20),
        ),
        'dark': dict(
            BG1=(22, 6, 4),     BG2=(7, 2, 1),
            BH=(220, 56, 36),   BL=(128, 18, 10),
            FC=(244, 236, 218),
            TH=(70, 24, 15),    TL=(140, 68, 54),
            LH=(220, 178, 58),  LL=(152, 112, 26),
            KH=(192, 150, 42),  KL=(135, 95, 15),
        ),
        'tinted': dict(
            BG1=(68, 68, 68),   BG2=(26, 26, 26),
            BH=(190, 190, 190), BL=(108, 108, 108),
            FC=(246, 246, 246),
            TH=(50, 50, 50),    TL=(102, 102, 102),
            LH=(190, 190, 190), LL=(130, 130, 130),
            KH=(172, 172, 172), KL=(122, 122, 122),
        ),
    }
    P = palettes[v]

    # ── Background: radial gradient (warm dark red, lighter center) ──
    t_bg = np.clip(_D / (S * 0.70), 0, 1) ** 1.2
    arr = np.stack(
        [P['BG1'][i] * (1 - t_bg) + P['BG2'][i] * t_bg for i in range(3)],
        axis=-1,
    ).astype(np.float32)

    # ── Timer body: directional sphere gradient + rim darkening ──
    BR = 368
    m_body = _D <= BR
    dot_b  = _dx * (-0.55) + _dy * (-0.75)   # light from upper-left
    t_body = np.clip((-dot_b + BR) / (2 * BR), 0, 1)
    t_rim  = np.clip((_D - BR * 0.72) / (BR * 0.28), 0, 1) ** 2
    t_c    = t_body * (1 - t_rim * 0.55) + t_rim * 0.45
    for i in range(3):
        arr[:, :, i] = np.where(
            m_body,
            P['BH'][i] * (1 - t_c) + P['BL'][i] * t_c,
            arr[:, :, i],
        )

    img = Image.fromarray(arr.clip(0, 255).astype(np.uint8), 'RGB')

    # ── Body specular highlight (upper-left soft blob) ──
    hl = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse(
        [CX - 238, CY - 295, CX - 18, CY - 118], fill=(255, 225, 210, 148)
    )
    hl = hl.filter(ImageFilter.GaussianBlur(44))
    img = Image.alpha_composite(img.convert('RGBA'), hl).convert('RGB')

    # ── Face inset shadow ring ──
    FR = 265
    sh = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    shdraw = ImageDraw.Draw(sh)
    for d in range(0, 22, 2):
        a = int(((d / 22.0) ** 1.8) * 100)
        r = FR + d * 1.9
        shdraw.ellipse([CX - r, CY - r, CX + r, CY + r], fill=(0, 0, 0, a))
    sh = sh.filter(ImageFilter.GaussianBlur(5))
    img = Image.alpha_composite(img.convert('RGBA'), sh).convert('RGB')

    # ── Face (cream circle) ──
    draw = ImageDraw.Draw(img)
    draw.ellipse([CX - FR, CY - FR, CX + FR, CY + FR], fill=P['FC'])

    # Subtle bottom shading on face
    fa = np.array(img).astype(np.float32)
    m_face = _D <= FR
    t_fs   = np.clip((_yr - (CY - FR)) / (2 * FR), 0, 1)
    for i in range(3):
        fa[:, :, i] = np.where(m_face, fa[:, :, i] * (1 - t_fs * 0.07), fa[:, :, i])
    img = Image.fromarray(fa.clip(0, 255).astype(np.uint8), 'RGB')
    draw = ImageDraw.Draw(img)

    # ── Tick marks ──
    T_OUT = FR - 13
    for m in range(60):
        ang = math.radians(m * 6 - 90)
        ca, sa = math.cos(ang), math.sin(ang)
        if   m % 15 == 0: t_in, w, col = FR - 62, 5, P['TH']
        elif m % 5  == 0: t_in, w, col = FR - 48, 3, P['TH']
        else:             t_in, w, col = FR - 27, 2, P['TL']
        draw.line(
            [(CX + ca * t_in, CY + sa * t_in), (CX + ca * T_OUT, CY + sa * T_OUT)],
            fill=col, width=w,
        )

    # Center hub
    draw.ellipse([CX - 14, CY - 14, CX + 14, CY + 14], fill=P['TH'])
    draw.ellipse([CX - 6,  CY - 6,  CX + 6,  CY + 6],  fill=P['FC'])

    # ── Bells (golden domes at top of body) ──
    BELL_Y  = CY - BR + 30   # y=174
    BELL_SEP = 90             # horizontal offset from center
    BELL_R   = 52

    for bx in (CX - BELL_SEP, CX + BELL_SEP):
        db_x = _xr.astype(np.float32) - bx
        db_y = _yr.astype(np.float32) - BELL_Y
        D_bell  = np.hypot(db_x, db_y)
        m_bell  = D_bell <= BELL_R
        dot_bell = db_x * (-0.55) + db_y * (-0.75)
        t_bell  = np.clip((-dot_bell + BELL_R) / (2 * BELL_R), 0, 1)
        ba = np.array(img).astype(np.float32)
        for i in range(3):
            ba[:, :, i] = np.where(
                m_bell,
                P['LH'][i] * (1 - t_bell) + P['LL'][i] * t_bell,
                ba[:, :, i],
            )
        img = Image.fromarray(ba.clip(0, 255).astype(np.uint8), 'RGB')
        # Bell specular
        bhl = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(bhl).ellipse(
            [bx - 20, BELL_Y - 26, bx + 3, BELL_Y - 6], fill=(255, 248, 200, 165)
        )
        bhl = bhl.filter(ImageFilter.GaussianBlur(7))
        img = Image.alpha_composite(img.convert('RGBA'), bhl).convert('RGB')

    draw = ImageDraw.Draw(img)
    # Small clapper dot between the bells
    draw.ellipse(
        [CX - 7, BELL_Y - 7, CX + 7, BELL_Y + 7], fill=P['TH']
    )

    # ── Winding knob (dome rising from between the bells, top center) ──
    KX, KY = CX, CY - BR + 15   # center at y=159 (straddles body top)
    KRX, KRY = 22, 36
    dk_x = _xr.astype(np.float32) - KX
    dk_y = _yr.astype(np.float32) - KY
    m_knob  = (dk_x / KRX) ** 2 + (dk_y / KRY) ** 2 <= 1
    dot_k   = dk_x * (-0.50) + dk_y * (-0.80)
    t_knob  = np.clip((-dot_k + max(KRX, KRY)) / (2 * max(KRX, KRY)), 0, 1)
    ka = np.array(img).astype(np.float32)
    for i in range(3):
        ka[:, :, i] = np.where(
            m_knob,
            P['KH'][i] * (1 - t_knob) + P['KL'][i] * t_knob,
            ka[:, :, i],
        )
    img = Image.fromarray(ka.clip(0, 255).astype(np.uint8), 'RGB')
    khl = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(khl).ellipse(
        [KX - 12, KY - 24, KX + 5, KY - 8], fill=(255, 248, 220, 175)
    )
    khl = khl.filter(ImageFilter.GaussianBlur(6))
    img = Image.alpha_composite(img.convert('RGBA'), khl).convert('RGB')

    return img


OUTDIR = os.path.join(
    os.path.dirname(__file__),
    '../Pomodoro/Pomodoro/Assets.xcassets/AppIcon.appiconset',
)
os.makedirs(OUTDIR, exist_ok=True)

variants = [
    ('light',  'AppIcon.png'),
    ('dark',   'AppIcon-Dark.png'),
    ('tinted', 'AppIcon-Tinted.png'),
]
for v, fn in variants:
    path = os.path.join(OUTDIR, fn)
    make_icon(v).save(path, 'PNG')
    print(f'  {v:8s} → {path}')

print('Done!')
