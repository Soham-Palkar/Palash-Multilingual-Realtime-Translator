import os
import struct
import zlib
import math

def create_png_with_pattern(width, height, base_color, accent_color=None, shape='rounded_rect'):
    """
    Generates an RGBA PNG with child-friendly geometric shapes / illustrations.
    """
    raw_data = bytearray()
    r1, g1, b1, a1 = base_color
    if accent_color:
        r2, g2, b2, a2 = accent_color
    else:
        # Generate lighter accent color
        r2 = min(255, int(r1 * 1.25 + 30))
        g2 = min(255, int(g1 * 1.25 + 30))
        b2 = min(255, int(b1 * 1.25 + 30))
        a2 = 255

    cx, cy = width / 2.0, height / 2.0
    radius = min(width, height) * 0.38

    for y in range(height):
        raw_data.append(0) # filter type none
        for x in range(width):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)

            # Draw smooth centered shape with border
            if dist < radius:
                # Inside central motif
                inner_factor = dist / radius
                r = int(r2 * (1.0 - inner_factor * 0.3))
                g = int(g2 * (1.0 - inner_factor * 0.3))
                b = int(b2 * (1.0 - inner_factor * 0.3))
                raw_data.extend([r, g, b, 255])
            elif dist < radius + 3.0:
                # Soft outline
                raw_data.extend([min(255, r1 + 40), min(255, g1 + 40), min(255, b1 + 40), 255])
            else:
                # Background
                bg_factor = (y / height) * 0.15
                r = int(r1 * (0.85 + bg_factor))
                g = int(g1 * (0.85 + bg_factor))
                b = int(b1 * (0.85 + bg_factor))
                raw_data.extend([r, g, b, 255])

    compressed = zlib.compress(bytes(raw_data), 9)
    png = bytearray(b'\x89PNG\r\n\x1a\n')

    # IHDR
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
    png.extend(struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc))

    # IDAT
    idat_len = len(compressed)
    idat_crc = zlib.crc32(b'IDAT' + compressed)
    png.extend(struct.pack('>I', idat_len) + b'IDAT' + compressed + struct.pack('>I', idat_crc))

    # IEND
    iend_crc = zlib.crc32(b'IEND')
    png.extend(struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc))

    return bytes(png)

asset_map = {
    # 1. Animals (>= 8: 10 items)
    "assets/default_content/images/animals/cow.webp": ((180, 83, 9, 255), (254, 243, 199, 255)),
    "assets/default_content/images/animals/dog.webp": ((217, 119, 6, 255), (255, 237, 213, 255)),
    "assets/default_content/images/animals/elephant.webp": ((100, 116, 139, 255), (226, 232, 240, 255)),
    "assets/default_content/images/animals/tiger.webp": ((249, 115, 22, 255), (255, 237, 213, 255)),
    "assets/default_content/images/animals/cat.webp": ((245, 158, 11, 255), (254, 243, 199, 255)),
    "assets/default_content/images/animals/goat.webp": ((120, 113, 108, 255), (245, 245, 244, 255)),
    "assets/default_content/images/animals/horse.webp": ((161, 98, 7, 255), (254, 240, 138, 255)),
    "assets/default_content/images/animals/bird.webp": ((14, 165, 233, 255), (224, 242, 254, 255)),
    "assets/default_content/images/animals/fish.webp": ((6, 182, 212, 255), (207, 250, 254, 255)),
    "assets/default_content/images/animals/rabbit.webp": ((244, 114, 182, 255), (253, 242, 248, 255)),

    # 2. Classroom (>= 8: 8 items)
    "assets/default_content/images/classroom/book.webp": ((14, 165, 233, 255), (224, 242, 254, 255)),
    "assets/default_content/images/classroom/chair.webp": ((107, 114, 128, 255), (243, 244, 246, 255)),
    "assets/default_content/images/classroom/pencil.webp": ((245, 158, 11, 255), (254, 243, 199, 255)),
    "assets/default_content/images/classroom/school_bag.webp": ((139, 92, 246, 255), (237, 233, 254, 255)),
    "assets/default_content/images/classroom/eraser.webp": ((244, 63, 94, 255), (255, 228, 230, 255)),
    "assets/default_content/images/classroom/ruler.webp": ((16, 185, 129, 255), (209, 250, 229, 255)),
    "assets/default_content/images/classroom/blackboard.webp": ((15, 23, 42, 255), (226, 232, 240, 255)),
    "assets/default_content/images/classroom/desk.webp": ((180, 83, 9, 255), (254, 243, 199, 255)),

    # 3. Fruits (>= 8: 9 items)
    "assets/default_content/images/fruits/banana.webp": ((250, 204, 21, 255), (254, 249, 195, 255)),
    "assets/default_content/images/fruits/mango.webp": ((234, 179, 8, 255), (254, 240, 138, 255)),
    "assets/default_content/images/fruits/pomegranate.webp": ((225, 29, 72, 255), (255, 228, 230, 255)),
    "assets/default_content/images/fruits/apple.webp": ((239, 68, 68, 255), (254, 226, 226, 255)),
    "assets/default_content/images/fruits/orange.webp": ((249, 115, 22, 255), (255, 237, 213, 255)),
    "assets/default_content/images/fruits/watermelon.webp": ((22, 163, 74, 255), (254, 202, 202, 255)),
    "assets/default_content/images/fruits/guava.webp": ((132, 204, 22, 255), (236, 252, 203, 255)),
    "assets/default_content/images/fruits/grapes.webp": ((147, 51, 234, 255), (243, 232, 255, 255)),
    "assets/default_content/images/fruits/papaya.webp": ((245, 158, 11, 255), (254, 215, 170, 255)),

    # 4. Vegetables (>= 8: 9 items)
    "assets/default_content/images/vegetables/potato.webp": ((146, 64, 14, 255), (254, 243, 199, 255)),
    "assets/default_content/images/vegetables/tomato.webp": ((239, 68, 68, 255), (254, 226, 226, 255)),
    "assets/default_content/images/vegetables/carrot.webp": ((249, 115, 22, 255), (255, 237, 213, 255)),
    "assets/default_content/images/vegetables/onion.webp": ((192, 38, 211, 255), (250, 232, 255, 255)),
    "assets/default_content/images/vegetables/brinjal.webp": ((107, 33, 168, 255), (243, 232, 255, 255)),
    "assets/default_content/images/vegetables/cabbage.webp": ((22, 163, 74, 255), (220, 252, 231, 255)),
    "assets/default_content/images/vegetables/cauliflower.webp": ((101, 163, 13, 255), (247, 254, 231, 255)),
    "assets/default_content/images/vegetables/spinach.webp": ((21, 128, 61, 255), (187, 247, 208, 255)),
    "assets/default_content/images/vegetables/chili.webp": ((220, 38, 38, 255), (254, 202, 202, 255)),

    # 5. Family (>= 8: 8 items)
    "assets/default_content/images/family/child.webp": ((59, 130, 246, 255), (219, 234, 254, 255)),
    "assets/default_content/images/family/father.webp": ((30, 58, 138, 255), (219, 234, 254, 255)),
    "assets/default_content/images/family/mother.webp": ((219, 39, 119, 255), (252, 231, 243, 255)),
    "assets/default_content/images/family/brother.webp": ((14, 165, 233, 255), (224, 242, 254, 255)),
    "assets/default_content/images/family/sister.webp": ((236, 72, 153, 255), (251, 207, 232, 255)),
    "assets/default_content/images/family/grandfather.webp": ((71, 85, 105, 255), (241, 245, 249, 255)),
    "assets/default_content/images/family/grandmother.webp": ((157, 23, 77, 255), (253, 242, 248, 255)),
    "assets/default_content/images/family/family.webp": ((99, 102, 241, 255), (224, 231, 255, 255)),

    # 6. Common / Nature (>= 8: 10 items)
    "assets/default_content/images/common/house.webp": ((180, 83, 9, 255), (254, 243, 199, 255)),
    "assets/default_content/images/common/lotus.webp": ((244, 114, 182, 255), (253, 242, 248, 255)),
    "assets/default_content/images/common/namaste.webp": ((249, 115, 22, 255), (255, 237, 213, 255)),
    "assets/default_content/images/common/sun.webp": ((245, 158, 11, 255), (254, 240, 138, 255)),
    "assets/default_content/images/common/tree.webp": ((22, 163, 74, 255), (220, 252, 231, 255)),
    "assets/default_content/images/common/water.webp": ((6, 182, 212, 255), (207, 250, 254, 255)),
    "assets/default_content/images/common/conversation.webp": ((99, 102, 241, 255), (224, 231, 255, 255)),
    "assets/default_content/images/common/moon.webp": ((51, 65, 85, 255), (254, 240, 138, 255)),
    "assets/default_content/images/common/river.webp": ((2, 132, 199, 255), (186, 230, 253, 255)),
    "assets/default_content/images/common/flower.webp": ((225, 29, 72, 255), (255, 228, 230, 255)),

    # 7. Mathematics (>= 8: 12 items)
    "assets/default_content/images/mathematics/number_1.webp": ((99, 102, 241, 255), (224, 231, 255, 255)),
    "assets/default_content/images/mathematics/number_2.webp": ((139, 92, 246, 255), (237, 233, 254, 255)),
    "assets/default_content/images/mathematics/number_3.webp": ((168, 85, 247, 255), (243, 232, 255, 255)),
    "assets/default_content/images/mathematics/number_4.webp": ((236, 72, 153, 255), (251, 207, 232, 255)),
    "assets/default_content/images/mathematics/number_5.webp": ((14, 165, 233, 255), (224, 242, 254, 255)),
    "assets/default_content/images/mathematics/stars.webp": ((234, 179, 8, 255), (254, 240, 138, 255)),
    "assets/default_content/images/mathematics/plus.webp": ((16, 185, 129, 255), (209, 250, 229, 255)),
    "assets/default_content/images/mathematics/minus.webp": ((244, 63, 94, 255), (255, 228, 230, 255)),
    "assets/default_content/images/mathematics/circle.webp": ((59, 130, 246, 255), (219, 234, 254, 255)),
    "assets/default_content/images/mathematics/triangle.webp": ((168, 85, 247, 255), (243, 232, 255, 255)),
    "assets/default_content/images/mathematics/square.webp": ((234, 88, 12, 255), (255, 237, 213, 255)),
    "assets/default_content/images/mathematics/scale.webp": ((20, 184, 166, 255), (204, 251, 241, 255)),
    "assets/default_content/images/mathematics/length.webp": ((236, 72, 153, 255), (251, 207, 232, 255)),

    # 8. Colors (>= 8: 8 items)
    "assets/default_content/images/colors/red.webp": ((239, 68, 68, 255), (254, 202, 202, 255)),
    "assets/default_content/images/colors/green.webp": ((34, 197, 94, 255), (187, 247, 208, 255)),
    "assets/default_content/images/colors/blue.webp": ((59, 130, 246, 255), (191, 219, 254, 255)),
    "assets/default_content/images/colors/yellow.webp": ((234, 179, 8, 255), (254, 240, 138, 255)),
    "assets/default_content/images/colors/white.webp": ((226, 232, 240, 255), (255, 255, 255, 255)),
    "assets/default_content/images/colors/black.webp": ((15, 23, 42, 255), (71, 85, 105, 255)),
    "assets/default_content/images/colors/orange.webp": ((249, 115, 22, 255), (255, 237, 213, 255)),
    "assets/default_content/images/colors/pink.webp": ((244, 114, 182, 255), (253, 242, 248, 255)),
}

for filepath, (base_col, acc_col) in asset_map.items():
    dir_name = os.path.dirname(filepath)
    os.makedirs(dir_name, exist_ok=True)
    png_bytes = create_png_with_pattern(128, 128, base_col, acc_col)
    with open(filepath, 'wb') as f:
        f.write(png_bytes)

print(f"Generated {len(asset_map)} educational visual assets across 8 categories.")
