import os
from PIL import Image, ImageDraw, ImageFilter

def create_master_icon(size=2048):
    # Base image with RGBA
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background squircle / rounded rect with dark luxury gradient
    # Deep dark charcoal / obsidian: #101014 -> #0B0B0E
    bg = Image.new("RGBA", (size, size), (16, 16, 20, 255))
    bg_draw = ImageDraw.Draw(bg)

    # Subtle radial glow from top-center
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_center = (size // 2, int(size * 0.45))
    glow_radius = int(size * 0.6)
    glow_draw.ellipse(
        [
            (glow_center[0] - glow_radius, glow_center[1] - glow_radius),
            (glow_center[0] + glow_radius, glow_center[1] + glow_radius),
        ],
        fill=(229, 9, 20, 45) # Deep red ambient glow
    )
    glow = glow.filter(ImageFilter.GaussianBlur(int(size * 0.15)))
    bg.paste(glow, (0, 0), glow)

    # Outer border / subtle rim light
    bg_draw.rounded_rectangle(
        [(int(size * 0.04), int(size * 0.04)), (int(size * 0.96), int(size * 0.96))],
        radius=int(size * 0.22),
        outline=(255, 255, 255, 22),
        width=int(size * 0.012)
    )

    # 2. Sleek Crimson Red Emblem Pill / Circle in Center
    emblem_center = (size // 2, size // 2)
    emblem_radius = int(size * 0.32)
    
    # Shadow under emblem
    emblem_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    es_draw = ImageDraw.Draw(emblem_shadow)
    es_draw.ellipse(
        [
            (emblem_center[0] - emblem_radius, emblem_center[1] - emblem_radius + int(size * 0.04)),
            (emblem_center[0] + emblem_radius, emblem_center[1] + emblem_radius + int(size * 0.04)),
        ],
        fill=(0, 0, 0, 140)
    )
    emblem_shadow = emblem_shadow.filter(ImageFilter.GaussianBlur(int(size * 0.05)))
    bg.paste(emblem_shadow, (0, 0), emblem_shadow)

    # Red gradient badge: #FF3B30 to #E50914
    badge = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    badge_draw = ImageDraw.Draw(badge)
    badge_draw.ellipse(
        [
            (emblem_center[0] - emblem_radius, emblem_center[1] - emblem_radius),
            (emblem_center[0] + emblem_radius, emblem_center[1] + emblem_radius),
        ],
        fill=(229, 9, 20, 255)
    )
    
    # Subtle top highlight inside emblem
    badge_highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bh_draw = ImageDraw.Draw(badge_highlight)
    bh_draw.ellipse(
        [
            (emblem_center[0] - int(emblem_radius * 0.85), emblem_center[1] - int(emblem_radius * 0.85)),
            (emblem_center[0] + int(emblem_radius * 0.85), emblem_center[1] - int(emblem_radius * 0.1)),
        ],
        fill=(255, 100, 100, 70)
    )
    badge_highlight = badge_highlight.filter(ImageFilter.GaussianBlur(int(size * 0.04)))
    badge.paste(badge_highlight, (0, 0), badge_highlight)

    bg.paste(badge, (0, 0), badge)

    # 3. Stylized Play Triangle & Anime Star
    # White play triangle pointing right, centered
    play = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    play_draw = ImageDraw.Draw(play)
    
    # Slightly shifted to optical center
    cx = size // 2 + int(size * 0.02)
    cy = size // 2
    r = int(size * 0.16)
    
    # Vertices of equilateral triangle
    p1 = (cx - int(r * 0.75), cy - int(r * 1.15))
    p2 = (cx + int(r * 1.2), cy)
    p3 = (cx - int(r * 0.75), cy + int(r * 1.15))
    
    play_draw.polygon([p1, p2, p3], fill=(255, 255, 255, 255))
    
    # Overlay star sparkle in top right of emblem
    sx = emblem_center[0] + int(emblem_radius * 0.65)
    sy = emblem_center[1] - int(emblem_radius * 0.65)
    sr = int(size * 0.04)
    # 4-point sparkle star
    star_points = [
        (sx, sy - sr * 2),
        (sx + sr * 0.4, sy - sr * 0.4),
        (sx + sr * 2, sy),
        (sx + sr * 0.4, sy + sr * 0.4),
        (sx, sy + sr * 2),
        (sx - sr * 0.4, sy + sr * 0.4),
        (sx - sr * 2, sy),
        (sx - sr * 0.4, sy - sr * 0.4),
    ]
    play_draw.polygon(star_points, fill=(255, 255, 255, 240))

    bg.paste(play, (0, 0), play)

    return bg

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Generating AnimeStream icons in {base_dir}...")
    master = create_master_icon(2048)

    # Android mipmaps
    android_res = os.path.join(base_dir, "android", "app", "src", "main", "res")
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, s in android_sizes.items():
        out_dir = os.path.join(android_res, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "ic_launcher.png")
        resized = master.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(out_path, "PNG")
        print(f"Saved Android {folder}/ic_launcher.png ({s}x{s})")

    # iOS AppIcon.appiconset
    ios_iconset = os.path.join(base_dir, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    ios_files = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, s in ios_files.items():
        out_path = os.path.join(ios_iconset, filename)
        resized = master.resize((s, s), Image.Resampling.LANCZOS)
        # iOS App Store / AppIcon doesn't allow transparency on 1024x1024, ensure RGB
        if filename == "Icon-App-1024x1024@1x.png":
            rgb_bg = Image.new("RGB", (s, s), (16, 16, 20))
            rgb_bg.paste(resized, (0, 0), resized)
            rgb_bg.save(out_path, "PNG")
        else:
            resized.save(out_path, "PNG")
        print(f"Saved iOS {filename} ({s}x{s})")

    print("App icon generation complete!")

if __name__ == "__main__":
    main()
