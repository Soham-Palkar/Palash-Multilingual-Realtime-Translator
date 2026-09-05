import os
import struct
import zlib

def create_png(width, height, color):
    # Generates a minimal valid RGBA PNG
    raw_data = bytearray()
    r, g, b, a = color
    for y in range(height):
        raw_data.append(0) # filter type none
        for x in range(width):
            raw_data.extend([r, g, b, a])
    
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
    "assets/default_content/images/animals/elephant.webp": (100, 116, 139, 255),
    "assets/default_content/images/animals/tiger.webp": (249, 115, 22, 255),
    "assets/default_content/images/animals/cow.webp": (180, 83, 9, 255),
    "assets/default_content/images/animals/dog.webp": (217, 119, 6, 255),
    "assets/default_content/images/fruits/pomegranate.webp": (225, 29, 72, 255),
    "assets/default_content/images/fruits/mango.webp": (234, 179, 8, 255),
    "assets/default_content/images/fruits/banana.webp": (250, 204, 21, 255),
    "assets/default_content/images/vegetables/potato.webp": (146, 64, 14, 255),
    "assets/default_content/images/colors/red.webp": (239, 68, 68, 255),
    "assets/default_content/images/colors/green.webp": (34, 197, 94, 255),
    "assets/default_content/images/family/child.webp": (59, 130, 246, 255),
    "assets/default_content/images/family/father.webp": (30, 58, 138, 255),
    "assets/default_content/images/family/mother.webp": (219, 39, 119, 255),
    "assets/default_content/images/classroom/chair.webp": (107, 114, 128, 255),
    "assets/default_content/images/classroom/book.webp": (14, 165, 233, 255),
    "assets/default_content/images/classroom/pencil.webp": (245, 158, 11, 255),
    "assets/default_content/images/mathematics/number_1.webp": (99, 102, 241, 255),
    "assets/default_content/images/mathematics/number_2.webp": (139, 92, 246, 255),
    "assets/default_content/images/mathematics/number_3.webp": (168, 85, 247, 255),
    "assets/default_content/images/mathematics/stars.webp": (234, 179, 8, 255),
    "assets/default_content/images/mathematics/plus.webp": (16, 185, 129, 255),
    "assets/default_content/images/mathematics/minus.webp": (244, 63, 94, 255),
    "assets/default_content/images/mathematics/circle.webp": (59, 130, 246, 255),
    "assets/default_content/images/mathematics/triangle.webp": (168, 85, 247, 255),
    "assets/default_content/images/mathematics/scale.webp": (20, 184, 166, 255),
    "assets/default_content/images/mathematics/length.webp": (236, 72, 153, 255),
    "assets/default_content/images/common/lotus.webp": (244, 114, 182, 255),
    "assets/default_content/images/common/water.webp": (6, 182, 212, 255),
    "assets/default_content/images/common/sun.webp": (245, 158, 11, 255),
    "assets/default_content/images/common/tree.webp": (22, 163, 74, 255),
    "assets/default_content/images/common/house.webp": (180, 83, 9, 255),
    "assets/default_content/images/common/conversation.webp": (99, 102, 241, 255),
    "assets/default_content/images/common/namaste.webp": (249, 115, 22, 255),
}

for filepath, color in asset_map.items():
    dir_name = os.path.dirname(filepath)
    os.makedirs(dir_name, exist_ok=True)
    png_bytes = create_png(64, 64, color)
    with open(filepath, 'wb') as f:
        f.write(png_bytes)
    print(f"Created: {filepath}")

print("All asset files created successfully.")
