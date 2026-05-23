from pathlib import Path
import math
import struct
import zlib

BG_TOP = (10, 5, 25, 255)
BG_BOTTOM = (18, 8, 42, 255)
CLOCK = (244, 247, 251, 255)
ACCENT = (69, 226, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


def blend(dst, src):
    sr, sg, sb, sa = src
    if sa <= 0:
        return dst
    if sa >= 255:
        return (sr, sg, sb, 255)
    dr, dg, db, da = dst
    a = sa / 255.0
    inv = 1.0 - a
    return (
        round(sr * a + dr * inv),
        round(sg * a + dg * inv),
        round(sb * a + db * inv),
        255,
    )


def mix(a, b, t):
    return tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(4))


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def write_png(path, size, pixels):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for pixel in row:
            raw.extend(pixel)

    def chunk(kind, data):
        return (
            struct.pack('>I', len(data))
            + kind
            + data
            + struct.pack('>I', zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    data = b'\x89PNG\r\n\x1a\n'
    data += chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
    data += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    data += chunk(b'IEND', b'')
    path.write_bytes(data)


def rounded_rect_alpha(x, y, size, radius):
    half = size / 2.0
    qx = abs(x - half) - (half - radius)
    qy = abs(y - half) - (half - radius)
    outside = math.hypot(max(qx, 0.0), max(qy, 0.0))
    inside = min(max(qx, qy), 0.0)
    dist = outside + inside - radius
    return 1.0 - smoothstep(-1.25, 1.25, dist)


def line_distance(px, py, ax, ay, bx, by):
    vx = bx - ax
    vy = by - ay
    wx = px - ax
    wy = py - ay
    denom = vx * vx + vy * vy
    t = 0.0 if denom == 0 else max(0.0, min(1.0, (wx * vx + wy * vy) / denom))
    cx = ax + t * vx
    cy = ay + t * vy
    return math.hypot(px - cx, py - cy)


def render(size, maskable=False):
    scale = 4
    source_size = size * scale
    cx = cy = source_size / 2.0
    safe = 0.58 if maskable else 0.66
    radius = source_size * safe * 0.5 * 0.58
    stroke = max(2.2 * scale, source_size * 0.030)
    hand_stroke = max(2.0 * scale, source_size * 0.026)
    pixels = [[TRANSPARENT for _ in range(source_size)] for __ in range(source_size)]

    for y in range(source_size):
        for x in range(source_size):
            t = y / max(1, source_size - 1)
            base = mix(BG_TOP, BG_BOTTOM, t)
            d = math.hypot(x - cx, y - cy) / (source_size * 0.55)
            glow = max(0.0, 1.0 - d) ** 2
            base = blend(base, (*ACCENT[:3], round(28 * glow)))
            a = rounded_rect_alpha(x + 0.5, y + 0.5, source_size, source_size * 0.21)
            pixels[y][x] = (*base[:3], round(255 * a))

    for y in range(source_size):
        for x in range(source_size):
            px = x + 0.5
            py = y + 0.5
            dist = math.hypot(px - cx, py - cy)

            shadow = 1.0 - smoothstep(
                stroke * 0.55,
                stroke * 0.55 + 2.0 * scale,
                abs(math.hypot(px - (cx + source_size * 0.012), py - (cy + source_size * 0.018)) - radius),
            )
            if shadow > 0:
                pixels[y][x] = blend(pixels[y][x], (0, 0, 0, round(76 * shadow)))

            ring = 1.0 - smoothstep(stroke * 0.46, stroke * 0.46 + 1.8 * scale, abs(dist - radius))
            if ring > 0:
                pixels[y][x] = blend(pixels[y][x], (*CLOCK[:3], round(245 * ring)))

            tick = 0.0
            for angle in (-math.pi / 2, 0, math.pi / 2, math.pi):
                ax = cx + math.cos(angle) * radius * 0.76
                ay = cy + math.sin(angle) * radius * 0.76
                bx = cx + math.cos(angle) * radius * 0.86
                by = cy + math.sin(angle) * radius * 0.86
                tick = max(tick, 1.0 - smoothstep(stroke * 0.36, stroke * 0.36 + 1.2 * scale, line_distance(px, py, ax, ay, bx, by)))
            if tick > 0:
                pixels[y][x] = blend(pixels[y][x], (*CLOCK[:3], round(215 * tick)))

            minute = line_distance(px, py, cx, cy, cx + radius * 0.50, cy - radius * 0.44)
            hour = line_distance(px, py, cx, cy, cx - radius * 0.34, cy - radius * 0.25)
            hand = max(
                1.0 - smoothstep(hand_stroke * 0.48, hand_stroke * 0.48 + 1.4 * scale, minute),
                1.0 - smoothstep(hand_stroke * 0.55, hand_stroke * 0.55 + 1.4 * scale, hour),
            )
            if hand > 0:
                pixels[y][x] = blend(pixels[y][x], (*ACCENT[:3], round(255 * hand)))

            dot = 1.0 - smoothstep(radius * 0.105, radius * 0.105 + 1.4 * scale, dist)
            if dot > 0:
                pixels[y][x] = blend(pixels[y][x], (*CLOCK[:3], round(255 * dot)))

    downsampled = []
    for y in range(size):
        row = []
        for x in range(size):
            acc = [0, 0, 0, 0]
            for sy in range(scale):
                for sx in range(scale):
                    pixel = pixels[y * scale + sy][x * scale + sx]
                    for i, value in enumerate(pixel):
                        acc[i] += value
            row.append(tuple(round(value / (scale * scale)) for value in acc))
        downsampled.append(row)
    return downsampled


def png_bytes(size):
    pixels = render(size)
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for pixel in row:
            raw.extend(pixel)

    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xFFFFFFFF)

    data = b'\x89PNG\r\n\x1a\n'
    data += chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
    data += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    data += chunk(b'IEND', b'')
    return data


def save(path, size, maskable=False):
    write_png(path, size, render(size, maskable=maskable))


for folder, size in {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}.items():
    save(f'android/app/src/main/res/{folder}/ic_launcher.png', size)

for filename, size in {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}.items():
    save(Path('ios/Runner/Assets.xcassets/AppIcon.appiconset') / filename, size)

for filename, size in {
    'app_icon_16.png': 16,
    'app_icon_32.png': 32,
    'app_icon_64.png': 64,
    'app_icon_128.png': 128,
    'app_icon_256.png': 256,
    'app_icon_512.png': 512,
    'app_icon_1024.png': 1024,
}.items():
    save(Path('macos/Runner/Assets.xcassets/AppIcon.appiconset') / filename, size)

save('web/icons/Icon-192.png', 192)
save('web/icons/Icon-512.png', 512)
save('web/icons/Icon-maskable-192.png', 192, maskable=True)
save('web/icons/Icon-maskable-512.png', 512, maskable=True)
save('web/favicon.png', 32)

ico_sizes = [16, 24, 32, 48, 64, 128, 256]
images = [png_bytes(size) for size in ico_sizes]
header = struct.pack('<HHH', 0, 1, len(images))
offset = 6 + 16 * len(images)
entries = bytearray()
for size, image in zip(ico_sizes, images):
    entries.extend(struct.pack('<BBBBHHII', 0 if size == 256 else size, 0 if size == 256 else size, 0, 0, 1, 32, len(image), offset))
    offset += len(image)
Path('windows/runner/resources').mkdir(parents=True, exist_ok=True)
Path('windows/runner/resources/app_icon.ico').write_bytes(header + bytes(entries) + b''.join(images))

branding = Path('assets/branding/to_the_moon_timer_logo.svg')
if branding.exists():
    branding.unlink()

print('Generated minimalistic clock launcher icons and removed unused in-app SVG logo asset.')
