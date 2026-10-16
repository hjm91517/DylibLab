#!/usr/bin/env python3
# 生成 DylibLab App 图标（1024x1024 PNG，仅用标准库，逐行跨度填充，速度快）
# 用法: python3 gen_icon.py
import struct, zlib, math

SIZE = 1024

def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

BG_TOP = hexc('#1C232E')
BG_BOT = hexc('#0D1117')
MINT   = hexc('#4FD1C5')
AMBER  = hexc('#F5A623')
BLUE   = hexc('#5B8DEF')

def mix(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)

# 圆角矩形在行 y 的水平跨度（中心坐标 + 尺寸 + 圆角半径）
def span(cx, cy, w, h, r, y):
    hy = y - cy
    half_h = h / 2.0
    if abs(hy) > half_h:
        return None
    if abs(hy) <= half_h - r:
        return (cx - w / 2.0, cx + w / 2.0)
    dy = abs(hy) - (half_h - r)
    dx = math.sqrt(max(r * r - dy * dy, 0.0))
    return (cx - w / 2.0 + (r - dx), cx + w / 2.0 - (r - dx))

pixels = bytearray(SIZE * SIZE * 4)

def fill_span(y, s, color, alpha=255):
    if s is None:
        return
    x0 = max(0, int(s[0]))
    x1 = min(SIZE, int(math.ceil(s[1])))
    if x1 <= x0:
        return
    chunk = bytes(color + (alpha,)) * (x1 - x0)
    pixels[(y * SIZE + x0) * 4:(y * SIZE + x1) * 4] = chunk

# 1. 背景：圆角矩形 + 纵向渐变
CX = CY = SIZE / 2.0
for y in range(SIZE):
    c = mix(BG_TOP, BG_BOT, y / SIZE)
    fill_span(y, span(CX, CY, SIZE - 16, SIZE - 16, 210, y), c)

# 2. 三块积木（先画投影，再画本体 + 顶部高光）
def block(x, y, w, h, color, r=46):
    cy = y + h / 2.0
    cx = x + w / 2.0
    # 投影
    for yy in range(y + 10, y + h + 10):
        fill_span(yy, span(cx, cy + 10, w, h, r, yy - 10), shade(color, 0.35), alpha=120)
    # 本体
    for yy in range(y, y + h):
        hl = max(0.0, 1.0 - (yy - y) / h * 1.7)
        c = mix(color, (255, 255, 255), hl * 0.16)
        fill_span(yy, span(cx, cy, w, h, r, yy), c)

def notch(x, y, w, h, color):
    cx = x + w / 2.0
    cy = y + h / 2.0
    for yy in range(y, y + h):
        s = span(cx, cy, w, h, h / 2.0, yy)
        if s is None:
            continue
        x0 = max(0, int(s[0]))
        x1 = min(SIZE, int(math.ceil(s[1])))
        for xx in range(x0, x1):
            p = (yy * SIZE + xx) * 4
            bg = (pixels[p], pixels[p+1], pixels[p+2])
            c = mix(bg, color, 0.8)
            pixels[p] = c[0]; pixels[p+1] = c[1]; pixels[p+2] = c[2]

block(272, 300, 480, 150, MINT)
block(192, 470, 640, 150, AMBER)
block(312, 640, 400, 150, BLUE)

# 积木两侧的拼插凹口
notch(272, 330, 26, 90, BG_BOT)
notch(728, 330, 26, 90, BG_BOT)
notch(192, 500, 26, 90, BG_BOT)
notch(806, 500, 26, 90, BG_BOT)
notch(312, 670, 26, 90, BG_BOT)
notch(686, 670, 26, 90, BG_BOT)

def png_chunk(tag, data):
    chunk = struct.pack('>I', len(data)) + tag + data
    return chunk + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

rows = bytearray()
for y in range(SIZE):
    rows.append(0)  # filter type 0
    rows.extend(pixels[y * SIZE * 4:(y + 1) * SIZE * 4])

png = b'\x89PNG\r\n\x1a\n'
png += png_chunk(b'IHDR', struct.pack('>IIBBBBB', SIZE, SIZE, 8, 6, 0, 0, 0))
png += png_chunk(b'IDAT', zlib.compress(bytes(rows), 9))
png += png_chunk(b'IEND', b'')

with open('DylibLab/Assets.xcassets/AppIcon.appiconset/AppIcon.png', 'wb') as f:
    f.write(png)
print('AppIcon.png written:', len(png), 'bytes')
