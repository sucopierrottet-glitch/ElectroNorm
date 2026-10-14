import math
import os
from PIL import Image, ImageDraw, ImageFilter

def create_app_icon(output_path="assets/icon/app_icon.png"):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Base Background with Rounded Squircle (Industrial Obsidian Gradient)
    bg_margin = 32
    bg_radius = 220
    
    gradient_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(gradient_img)
    
    # Gradient: Deep obsidian #070B14 to dark slate navy #0F172A to #1E293B
    for y in range(size):
        ratio = y / size
        r = int(7 + (22 - 7) * ratio)
        g = int(11 + (32 - 11) * ratio)
        b = int(20 + (55 - 20) * ratio)
        grad_draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
        
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [bg_margin, bg_margin, size - bg_margin, size - bg_margin],
        radius=bg_radius,
        fill=255
    )
    img.paste(gradient_img, (0, 0), mask)
    
    # Outer subtle electric glow border
    draw.rounded_rectangle(
        [bg_margin, bg_margin, size - bg_margin, size - bg_margin],
        radius=bg_radius,
        outline=(56, 189, 248, 70), # Electric cyan glow
        width=5
    )

    # 2. Main Raceway Conduit Profile (Center = 512, 512)
    cx, cy = 512, 512
    conduit_outer_r = 380
    conduit_inner_r = 320
    
    # Raceway outer shadow
    draw.ellipse(
        [cx - conduit_outer_r - 12, cy - conduit_outer_r + 16,
         cx + conduit_outer_r + 12, cy + conduit_outer_r + 36],
        fill=(3, 7, 18, 160)
    )

    # Steel conduit outer wall with metallic gradient simulation
    draw.ellipse(
        [cx - conduit_outer_r, cy - conduit_outer_r,
         cx + conduit_outer_r, cy + conduit_outer_r],
        fill=(51, 65, 85, 255) # Slate 700
    )
    
    # Outer bevel highlight
    draw.ellipse(
        [cx - conduit_outer_r + 4, cy - conduit_outer_r + 4,
         cx + conduit_outer_r - 4, cy + conduit_outer_r - 4],
        outline=(148, 163, 184, 180), # Slate 400
        width=6
    )

    # Conduit inner bore (Dark mechanical void)
    draw.ellipse(
        [cx - conduit_inner_r, cy - conduit_inner_r,
         cx + conduit_inner_r, cy + conduit_inner_r],
        fill=(7, 11, 20, 255)
    )

    # Inner bevel shadow
    draw.ellipse(
        [cx - conduit_inner_r, cy - conduit_inner_r,
         cx + conduit_inner_r, cy + conduit_inner_r],
        outline=(15, 23, 42, 240),
        width=10
    )

    # Crosshair calibration ticks (Normative reference)
    tick_len = 22
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        x1 = cx + (conduit_inner_r - tick_len) * math.cos(rad)
        y1 = cy + (conduit_inner_r - tick_len) * math.sin(rad)
        x2 = cx + conduit_inner_r * math.cos(rad)
        y2 = cy + conduit_inner_r * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=(100, 116, 139, 180), width=4)

    # 3. Packed Phase Conductors inside Conduit (NEC Normative 4-Wire Configuration)
    # Positions: Top-Left (Phase A), Top-Right (Phase B), Bottom-Right (Phase C), Bottom-Left (Ground)
    cond_r = 135 # conductor radius
    offset = 145
    
    conductors = [
        # (cx_rel, cy_rel, fill_color, border_color, name)
        (-offset, -offset, (55, 65, 81), (226, 232, 240), "Phase A - Black/Silver"),
        (offset, -offset, (220, 38, 38), (248, 113, 113), "Phase B - Red"),
        (offset, offset, (37, 99, 235), (96, 165, 250), "Phase C - Blue"),
        (-offset, offset, (22, 163, 74), (74, 222, 128), "Ground - Green"),
    ]

    for c_dx, c_dy, c_fill, c_border, _ in conductors:
        wire_cx = cx + c_dx
        wire_cy = cy + c_dy
        
        # Conductor drop shadow
        draw.ellipse(
            [wire_cx - cond_r + 6, wire_cy - cond_r + 10,
             wire_cx + cond_r + 6, wire_cy + cond_r + 14],
            fill=(2, 6, 14, 180)
        )
        
        # Conductor insulation body
        draw.ellipse(
            [wire_cx - cond_r, wire_cy - cond_r,
             wire_cx + cond_r, wire_cy + cond_r],
            fill=c_fill
        )
        
        # High-contrast border rim
        draw.ellipse(
            [wire_cx - cond_r, wire_cy - cond_r,
             wire_cx + cond_r, wire_cy + cond_r],
            outline=c_border,
            width=7
        )

        # Metallic Copper Core center
        core_r = 52
        draw.ellipse(
            [wire_cx - core_r, wire_cy - core_r,
             wire_cx + core_r, wire_cy + core_r],
            fill=(180, 83, 9, 255) # Deep Copper #B45309
        )
        # Copper metallic shine
        draw.ellipse(
            [wire_cx - core_r + 4, wire_cy - core_r + 4,
             wire_cx + core_r - 4, wire_cy + core_r - 4],
            outline=(245, 158, 11, 200), # Bright Amber
            width=4
        )
        # Center core strand point
        draw.ellipse(
            [wire_cx - 14, wire_cy - 14, wire_cx + 14, wire_cy + 14],
            fill=(251, 191, 36, 255)
        )

    # 4. Floating High-Voltage Electric Lightning Bolt Badge (Centerpiece)
    # Floating circular badge
    badge_cx, badge_cy = cx, cy
    badge_r = 110
    
    # Badge shadow
    draw.ellipse(
        [badge_cx - badge_r - 8, badge_cy - badge_r + 14,
         badge_cx + badge_r + 8, badge_cy + badge_r + 26],
        fill=(2, 6, 14, 200)
    )
    # Badge surface (Obsidian with vibrant gold border)
    draw.ellipse(
        [badge_cx - badge_r, badge_cy - badge_r,
         badge_cx + badge_r, badge_cy + badge_r],
        fill=(15, 23, 42, 255)
    )
    draw.ellipse(
        [badge_cx - badge_r, badge_cy - badge_r,
         badge_cx + badge_r, badge_cy + badge_r],
        outline=(245, 158, 11, 255), # Amber gold border
        width=8
    )
    draw.ellipse(
        [badge_cx - badge_r + 10, badge_cy - badge_r + 10,
         badge_cx + badge_r - 10, badge_cy + badge_r - 10],
        outline=(251, 191, 36, 140),
        width=3
    )

    # Sharp Electric Lightning Bolt polygon
    # Points scaled relative to center (badge_cx, badge_cy)
    bolt_pts = [
        (badge_cx + 12, badge_cy - 72),  # top point
        (badge_cx - 44, badge_cy + 6),   # mid left
        (badge_cx - 4,  badge_cy + 6),   # mid inner notch
        (badge_cx - 20, badge_cy + 74),  # bottom tip
        (badge_cx + 42, badge_cy - 6),   # mid right
        (badge_cx + 4,  badge_cy - 6),   # mid inner return
    ]
    
    # Bolt glow shadow
    bolt_shadow = [(x + 3, y + 4) for (x, y) in bolt_pts]
    draw.polygon(bolt_shadow, fill=(180, 83, 9, 180))
    # Main vibrant electric bolt
    draw.polygon(bolt_pts, fill=(251, 191, 36, 255))
    
    # White-hot interior spark
    spark_pts = [
        (badge_cx + 8, badge_cy - 50),
        (badge_cx - 24, badge_cy + 4),
        (badge_cx,     badge_cy + 4),
        (badge_cx - 10, badge_cy + 48),
        (badge_cx + 24, badge_cy - 4),
        (badge_cx + 4,  badge_cy - 4),
    ]
    draw.polygon(spark_pts, fill=(255, 255, 255, 230))

    img.save(output_path, "PNG")
    print(f"Generated ElectroNorm Pro icon successfully at {output_path}")

if __name__ == "__main__":
    create_app_icon()
