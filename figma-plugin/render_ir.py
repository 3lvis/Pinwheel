#!/usr/bin/env python3
"""Render a captured Figma IR document back to a PNG so it can be diffed against the real iOS render.
Handles absolutely-positioned nodes (the containment / root=frame captures). Auto-layout children
(root=screen) don't carry absolute child coords, so this is a best-effort approximation for those."""
import json, sys, base64, io
from PIL import Image, ImageDraw, ImageFont

def rgba(c, default=(0, 0, 0, 255)):
    if not c:
        return default
    return (int(c['r'] * 255), int(c['g'] * 255), int(c['b'] * 255), int(c.get('a', 1) * 255))

def font(size):
    for path in ["/System/Library/Fonts/SFNSRounded.ttf", "/System/Library/Fonts/SFNS.ttf",
                 "/System/Library/Fonts/Supplemental/Arial.ttf"]:
        try:
            return ImageFont.truetype(path, max(int(size), 6))
        except Exception:
            continue
    return ImageFont.load_default()

def render(doc, scale=2):
    W, H = int(doc['width'] * scale), int(doc['height'] * scale)
    img = Image.new('RGBA', (W, H), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)

    def walk(node):
        # Containment-path nodes carry absolute canvas coordinates, so draw each at its own x/y.
        x, y = node['x'] * scale, node['y'] * scale
        w, h = node['w'] * scale, node['h'] * scale
        if node.get('fill'):
            r = node.get('radius', 0) * scale
            draw.rounded_rectangle([x, y, x + w, y + h], radius=min(r, w / 2, h / 2), fill=rgba(node['fill']))
        if node.get('image'):
            try:
                photo = Image.open(io.BytesIO(base64.b64decode(node['image']))).convert('RGBA')
                photo = photo.resize((max(int(w), 1), max(int(h), 1)))
                img.paste(photo, (int(x), int(y)), photo)
            except Exception:
                draw.rectangle([x, y, x + w, y + h], outline=(255, 0, 0, 255))
        for run in (node.get('texts') or []):
            f = node.get('font') or {}
            size = f.get('size', 15) * scale
            color = rgba(f.get('color'), (20, 20, 20, 255))
            tx, ty = run['x'] * scale, run['y'] * scale
            fnt = font(size)
            draw.text((tx, ty), run['text'], fill=color, font=fnt)
            tw = draw.textlength(run['text'], font=fnt)
            if f.get('strikethrough'):
                draw.line([tx, ty + size * 0.55, tx + tw, ty + size * 0.55], fill=color, width=max(int(scale), 1))
            if f.get('underline'):
                draw.line([tx, ty + size * 1.05, tx + tw, ty + size * 1.05], fill=color, width=max(int(scale), 1))
        for child in node.get('children', []):
            walk(child)

    root = doc['root']
    if root.get('fill'):
        draw.rectangle([0, 0, W, H], fill=rgba(root['fill']))
    for child in root.get('children', []):
        walk(child)
    return img

if __name__ == '__main__':
    path, out = sys.argv[1], sys.argv[2]
    doc = json.load(open(path))['document']
    render(doc).save(out)
    print('wrote', out, doc['width'], 'x', doc['height'], 'root=', doc['root']['tag'])
