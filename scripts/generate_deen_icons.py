import os
import shutil
from PIL import Image, ImageDraw

def generate_icons():
    source_path = "/home/deep/Downloads/banner.png"
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Loading source logo from {source_path}...")
    source_img = Image.open(source_path).convert("RGBA")
    
    # 1. Flutter app asset (copy original 1:1 with zero distortion)
    assets_dir = os.path.join(base_dir, "assets", "images")
    os.makedirs(assets_dir, exist_ok=True)
    asset_logo_path = os.path.join(assets_dir, "logo.png")
    shutil.copyfile(source_path, asset_logo_path)
    print(f"Saved Flutter asset 1:1: {asset_logo_path}")

    # Target 1024x1024 master
    master_size = 1024
    master_square = source_img.resize((master_size, master_size), Image.Resampling.LANCZOS)
    master_round = master_square

    # 2. Android mipmaps (Legacy + Adaptive)
    android_res = os.path.join(base_dir, "android", "app", "src", "main", "res")
    android_densities = {
        "mipmap-mdpi": (48, 108, 76),
        "mipmap-hdpi": (72, 162, 114),
        "mipmap-xhdpi": (96, 216, 152),
        "mipmap-xxhdpi": (144, 324, 228),
        "mipmap-xxxhdpi": (192, 432, 304),
    }
    for folder, (legacy_size, canvas_size, fg_logo_size) in android_densities.items():
        out_dir = os.path.join(android_res, folder)
        os.makedirs(out_dir, exist_ok=True)
        
        # Legacy Square launcher (Full bleed black square)
        sq_path = os.path.join(out_dir, "ic_launcher.png")
        master_square.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS).save(sq_path, "PNG")
        
        # Legacy Round launcher
        rd_path = os.path.join(out_dir, "ic_launcher_round.png")
        master_round.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS).save(rd_path, "PNG")
        
        # Adaptive Icon Foreground (108dp canvas with logo centered in safe zone)
        fg_canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        scaled_logo = master_square.resize((fg_logo_size, fg_logo_size), Image.Resampling.LANCZOS)
        offset = ((canvas_size - fg_logo_size) // 2, (canvas_size - fg_logo_size) // 2)
        fg_canvas.paste(scaled_logo, offset, scaled_logo)
        
        fg_path = os.path.join(out_dir, "ic_launcher_foreground.png")
        fg_canvas.save(fg_path, "PNG")
        print(f"Saved Android {folder} (legacy {legacy_size}px, adaptive fg {canvas_size}px)")

    # 3. iOS AppIcon
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
        resized = master_square.resize((s, s), Image.Resampling.LANCZOS)
        if filename == "Icon-App-1024x1024@1x.png":
            rgb_bg = Image.new("RGB", (s, s), (0, 0, 0))
            rgb_bg.paste(resized, (0, 0), resized)
            rgb_bg.save(out_path, "PNG")
        else:
            resized.save(out_path, "PNG")
        print(f"Saved iOS {filename} ({s}x{s})")

    print("DEEN icons generated successfully!")

if __name__ == "__main__":
    generate_icons()
