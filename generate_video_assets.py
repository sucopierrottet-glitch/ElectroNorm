import os
import shutil
from PIL import Image, ImageDraw, ImageFont

def create_video_assets():
    out_dir = "store_assets"
    os.makedirs(out_dir, exist_ok=True)
    
    font_bold = "C:/Windows/Fonts/segoeuib.ttf"
    font_reg = "C:/Windows/Fonts/segoeui.ttf"
    font_black = "C:/Windows/Fonts/arialbd.ttf"
    
    base_icon_path = "assets/icon/app_icon.png"
    if not os.path.exists(base_icon_path):
        raise FileNotFoundError(f"Base icon not found at {base_icon_path}")
    base_icon = Image.open(base_icon_path).convert("RGBA")

    # Helper: draw horizontal gradient
    def draw_hgradient(draw, w, h, c_left, c_right):
        for x in range(w):
            r = x / w
            red = int(c_left[0] + (c_right[0] - c_left[0]) * r)
            green = int(c_left[1] + (c_right[1] - c_left[1]) * r)
            blue = int(c_left[2] + (c_right[2] - c_left[2]) * r)
            draw.line([(x, 0), (x, h)], fill=(red, green, blue, 255))

    # Helper: draw radial glow
    def add_glow(img, cx, cy, radius, color_rgb, max_alpha=40):
        w, h = img.size
        overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        # concentric circles
        steps = 25
        for i in range(steps, 0, -1):
            cur_r = int(radius * (i / steps))
            alpha = int(max_alpha * (1.0 - (i / steps)))
            draw.ellipse([cx - cur_r, cy - cur_r, cx + cur_r, cy + cur_r], fill=(color_rgb[0], color_rgb[1], color_rgb[2], alpha))
        return Image.alpha_composite(img, overlay)

    print("Generating Google Ads Video Assets...")

    # =========================================================================
    # 1. LOGO SQUARE (1200x1200) - Exact size requested by Google Ads Video Builder
    # =========================================================================
    w, h = 1200, 1200
    logo_sq = Image.new("RGBA", (w, h), (7, 11, 20, 255))
    logo_sq = add_glow(logo_sq, 600, 600, 550, (0, 230, 118), max_alpha=35)
    logo_sq = add_glow(logo_sq, 600, 600, 400, (41, 121, 255), max_alpha=25)
    
    # Resize base app icon with smooth LANCZOS to 960x960 centered
    icon_resized = base_icon.resize((960, 960), Image.Resampling.LANCZOS)
    logo_sq.paste(icon_resized, (120, 120), icon_resized)
    
    logo_sq_path = os.path.join(out_dir, "logo_1200x1200.png")
    logo_sq.save(logo_sq_path, "PNG")
    print(f"-> Saved: {logo_sq_path} (1200x1200)")

    # Also save as transparent version if preferred
    logo_sq_trans = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    logo_sq_trans.paste(icon_resized, (120, 120), icon_resized)
    logo_sq_trans_path = os.path.join(out_dir, "logo_transparent_1200x1200.png")
    logo_sq_trans.save(logo_sq_trans_path, "PNG")
    print(f"-> Saved: {logo_sq_trans_path} (1200x1200)")

    # =========================================================================
    # 2. LOGO LANDSCAPE 4:1 (1200x300) - For Video Overlays & Banners
    # =========================================================================
    w, h = 1200, 300
    logo_land = Image.new("RGBA", (w, h), (11, 15, 25, 255))
    draw_l = ImageDraw.Draw(logo_land)
    draw_hgradient(draw_l, w, h, (7, 11, 20), (22, 31, 48))
    logo_land = add_glow(logo_land, 150, 150, 200, (0, 230, 118), max_alpha=40)
    
    # Place icon on the left
    ic_240 = base_icon.resize((240, 240), Image.Resampling.LANCZOS)
    logo_land.paste(ic_240, (30, 30), ic_240)
    
    draw_l = ImageDraw.Draw(logo_land)
    f_title_l = ImageFont.truetype(font_bold, 72)
    f_sub_l = ImageFont.truetype(font_reg, 32)
    f_badge_l = ImageFont.truetype(font_bold, 22)
    
    # Text
    draw_l.text((310, 50), "ELECTRONORM PRO", font=f_title_l, fill=(248, 250, 252, 255))
    draw_l.text((315, 145), "Cálculos Eléctricos & Reportes NEC", font=f_sub_l, fill=(148, 163, 184, 255))
    
    # Pill
    draw_l.rounded_rectangle([315, 200, 580, 245], radius=10, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
    draw_l.text((335, 208), "NEC 2026 • 100% OFFLINE", font=f_badge_l, fill=(0, 230, 118, 255))
    
    logo_land_path = os.path.join(out_dir, "logo_landscape_1200x300.png")
    logo_land.save(logo_land_path, "PNG")
    print(f"-> Saved: {logo_land_path} (1200x300)")

    # =========================================================================
    # 3. VIDEO SCENE 1: HERO / INTRO (1920x1080 Full HD 16:9)
    # =========================================================================
    w, h = 1920, 1080
    s1 = Image.new("RGBA", (w, h), (7, 11, 20, 255))
    draw1 = ImageDraw.Draw(s1)
    draw_hgradient(draw1, w, h, (5, 9, 16), (15, 23, 42))
    s1 = add_glow(s1, 400, 540, 500, (0, 230, 118), max_alpha=45)
    s1 = add_glow(s1, 1400, 300, 600, (41, 121, 255), max_alpha=30)
    
    # Left Hero Icon
    ic_hero = base_icon.resize((560, 560), Image.Resampling.LANCZOS)
    s1.paste(ic_hero, (160, 260), ic_hero)
    
    draw1 = ImageDraw.Draw(s1)
    f_badge1 = ImageFont.truetype(font_bold, 28)
    f_h1 = ImageFont.truetype(font_bold, 88)
    f_sub1 = ImageFont.truetype(font_reg, 38)
    f_tag1 = ImageFont.truetype(font_bold, 24)
    
    tx = 820
    # Top Category Pill
    draw1.rounded_rectangle([tx, 250, tx + 560, 315], radius=24, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
    draw1.text((tx + 30, 266), "HERRAMIENTA PROFESIONAL NEC", font=f_badge1, fill=(0, 230, 118, 255))
    
    # Title
    draw1.text((tx, 350), "ElectroNorm Pro", font=f_h1, fill=(248, 250, 252, 255))
    
    # Subtitles
    draw1.text((tx, 470), "Calculadora Normativa Eléctrica de Alta Precisión", font=f_sub1, fill=(203, 213, 225, 255))
    draw1.text((tx, 530), "Para Electricistas, Contratistas e Inspectores", font=f_sub1, fill=(148, 163, 184, 255))
    
    # Feature checklist pills
    features = [
        "✓ Ocupación de Tubería (Cap. 9)",
        "✓ Caída de Tensión AC (210.19)",
        "✓ Derateo Térmico (310.15)",
        "✓ Memorias PDF con Firma Digital",
        "✓ 100% Fiable Sin Conexión",
    ]
    fy = 640
    for feat in features:
        draw1.rounded_rectangle([tx, fy, tx + 620, fy + 54], radius=14, fill=(22, 31, 48, 230), outline=(45, 60, 82, 255), width=1)
        draw1.text((tx + 24, fy + 12), feat, font=f_tag1, fill=(248, 250, 252, 255))
        fy += 68

    s1_path = os.path.join(out_dir, "video_16x9_hero_1920x1080.png")
    s1.save(s1_path, "PNG")
    print(f"-> Saved: {s1_path} (1920x1080)")

    # =========================================================================
    # 4. VIDEO SCENE 2: CONDUIT FILL LIVE (1920x1080 Full HD 16:9)
    # =========================================================================
    s2 = Image.new("RGBA", (w, h), (7, 11, 20, 255))
    draw2 = ImageDraw.Draw(s2)
    draw_hgradient(draw2, w, h, (10, 15, 28), (20, 30, 50))
    s2 = add_glow(s2, 480, 540, 450, (0, 230, 118), max_alpha=35)
    
    draw2 = ImageDraw.Draw(s2)
    
    # Left Card: Conduit Cross Section Simulation
    c_left, c_top, c_right, c_bottom = 120, 140, 840, 940
    draw2.rounded_rectangle([c_left, c_top, c_right, c_bottom], radius=32, fill=(16, 23, 37, 255), outline=(45, 60, 82, 255), width=2)
    
    # Header inside left card
    f_card_h = ImageFont.truetype(font_bold, 36)
    draw2.text((c_left + 40, c_top + 40), "⚡ Canalización: EMT 3/4\" (Área: 0.533 in²)", font=f_card_h, fill=(255, 255, 255, 255))
    
    # Giant circular raceway
    cx, cy = (c_left + c_right) // 2, (c_top + c_bottom) // 2 + 30
    r_out, r_in = 260, 230
    draw2.ellipse([cx - r_out, cy - r_out, cx + r_out, cy + r_out], fill=(51, 65, 85, 255))
    draw2.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], fill=(7, 11, 20, 255))
    
    # Conductors (Fases A, B, C, Tierra)
    c_offsets = [(-75, -75, (66, 66, 66)), (75, -75, (213, 0, 0)), (75, 75, (41, 121, 255)), (-75, 75, (46, 125, 50))]
    for ox, oy, col in c_offsets:
        draw2.ellipse([cx + ox - 65, cy + oy - 65, cx + ox + 65, cy + oy + 65], fill=col)
        draw2.ellipse([cx + ox - 22, cy + oy - 22, cx + ox + 22, cy + oy + 22], fill=(217, 119, 6, 255)) # Copper core
        
    draw2.text((c_left + 60, c_bottom - 70), "Configuración: 3x #10 AWG + 1x #12 AWG Cu THHN", font=f_tag1, fill=(148, 163, 184, 255))

    # Right Content: Metrics & Standards
    rx = 940
    f_lg_num = ImageFont.truetype(font_bold, 110)
    f_res_sub = ImageFont.truetype(font_bold, 34)
    
    # Metric Card 1: Fill
    draw2.rounded_rectangle([rx, 140, rx + 860, 480], radius=30, fill=(22, 31, 48, 255), outline=(0, 230, 118, 220), width=3)
    draw2.text((rx + 50, 180), "OCUPACIÓN DE TUBERÍA (NEC CAPÍTULO 9)", font=f_badge1, fill=(0, 230, 118, 255))
    draw2.text((rx + 50, 235), "32.8%", font=f_lg_num, fill=(255, 255, 255, 255))
    draw2.text((rx + 420, 310), "/ 40.0% Máx. Permitido", font=f_res_sub, fill=(148, 163, 184, 255))
    
    # Pass Badge
    draw2.rounded_rectangle([rx + 620, 260, rx + 810, 340], radius=18, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
    draw2.text((rx + 650, 282), "✓ CUMPLE", font=f_badge1, fill=(0, 230, 118, 255))
    
    draw2.text((rx + 50, 400), "Área ocupada: 0.1748 in² | Espacio libre de seguridad disponible", font=f_tag1, fill=(203, 213, 225, 255))

    # Metric Card 2: Jam Ratio
    draw2.rounded_rectangle([rx, 520, rx + 860, 740], radius=30, fill=(22, 31, 48, 255), outline=(56, 189, 248, 200), width=2)
    draw2.text((rx + 50, 560), "DETECCIÓN AUTOMÁTICA DE ATASCAMIENTO (JAM RATIO)", font=f_badge1, fill=(56, 189, 248, 255))
    draw2.text((rx + 50, 615), "3.42", font=f_lg_num, fill=(255, 255, 255, 255))
    draw2.text((rx + 310, 680), "Rango Seguro (Fuera de zona crítica 2.8 - 3.2)", font=f_res_sub, fill=(56, 189, 248, 255))

    # Metric Card 3: Standards info
    draw2.rounded_rectangle([rx, 780, rx + 860, 940], radius=24, fill=(16, 23, 37, 255), outline=(45, 60, 82, 255), width=1)
    draw2.text((rx + 50, 810), "Compatibilidad Normativa Multi-País:", font=f_tag1, fill=(248, 250, 252, 255))
    draw2.text((rx + 50, 860), "• NEC 2026/2023 (USA) • NOM-001-SEDE (México) • RETIE (Colombia) • NBR 5410 (Brasil)", font=f_tag1, fill=(0, 230, 118, 255))

    s2_path = os.path.join(out_dir, "video_16x9_conduit_1920x1080.png")
    s2.save(s2_path, "PNG")
    print(f"-> Saved: {s2_path} (1920x1080)")

    # =========================================================================
    # 5. VIDEO SCENE 3: VOLTAGE DROP & DERATING (1920x1080 Full HD 16:9)
    # =========================================================================
    s3 = Image.new("RGBA", (w, h), (7, 11, 20, 255))
    draw3 = ImageDraw.Draw(s3)
    draw_hgradient(draw3, w, h, (6, 10, 18), (18, 27, 44))
    s3 = add_glow(s3, 500, 540, 500, (56, 189, 248), max_alpha=35)
    s3 = add_glow(s3, 1400, 540, 500, (255, 214, 0), max_alpha=30)
    
    draw3 = ImageDraw.Draw(s3)
    
    # Title at top
    draw3.text((120, 80), "INGENIERÍA ELÉCTRICA COMPLETA EN CAMPO", font=f_badge1, fill=(0, 230, 118, 255))
    f_banner_h = ImageFont.truetype(font_bold, 54)
    draw3.text((120, 130), "Caída de Tensión e Impedancia AC + Derateo Térmico", font=f_banner_h, fill=(248, 250, 252, 255))

    # Card 1 (Left): Voltage Drop
    c1_l, c1_r = 120, 980
    draw3.rounded_rectangle([c1_l, 230, c1_r, 960], radius=32, fill=(22, 31, 48, 255), outline=(56, 189, 248, 220), width=3)
    draw3.text((c1_l + 50, 275), "CAÍDA DE TENSIÓN (NEC 210.19 / 215.2)", font=f_badge1, fill=(56, 189, 248, 255))
    
    draw3.text((c1_l + 50, 335), "1.85%", font=f_lg_num, fill=(255, 255, 255, 255))
    draw3.text((c1_l + 410, 410), "(-3.85 V sobre 208V)", font=f_res_sub, fill=(148, 163, 184, 255))
    
    # Pass Badge
    draw3.rounded_rectangle([c1_l + 660, 360, c1_l + 810, 440], radius=16, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
    draw3.text((c1_l + 685, 382), "✓ PASA", font=f_badge1, fill=(0, 230, 118, 255))
    
    f_item = ImageFont.truetype(font_reg, 30)
    items_vd = [
        "• Longitud del Circuito: 120 pies (36.5 metros)",
        "• Corriente de Carga: 24.0 Amperios (FP 0.90)",
        "• Tensión Nominal: 208 V Trifásico (3-Phase)",
        "• Impedancia Efectiva Z: 1.20 Ω/kft (NEC Tabla 9)",
        "• Canalización: Tubo de Acero Magnético (EMT)",
        "• Límite Recomendado: <= 3.0% para Ramales",
    ]
    iy = 510
    for it in items_vd:
        draw3.text((c1_l + 50, iy), it, font=f_item, fill=(203, 213, 225, 255))
        iy += 68

    # Card 2 (Right): Thermal Derating
    c2_l, c2_r = 1040, 1800
    draw3.rounded_rectangle([c2_l, 230, c2_r, 960], radius=32, fill=(22, 31, 48, 255), outline=(255, 214, 0, 220), width=3)
    draw3.text((c2_l + 50, 275), "CORRECCIÓN Y DERATEO TÉRMICO (NEC 310.15)", font=f_badge1, fill=(255, 214, 0, 255))
    
    draw3.text((c2_l + 50, 335), "28.0 A", font=f_lg_num, fill=(255, 255, 255, 255))
    draw3.text((c2_l + 440, 410), "Ampacidad Neta", font=f_res_sub, fill=(148, 163, 184, 255))
    
    items_dt = [
        "• Ampacidad Base a 75°C: 35.0 A (Terminal Clamp)",
        "• Temp. Ambiente: 35°C (Factor Corrección: 0.96)",
        "• Conductores Portadores de Corriente: 3 CCC",
        "• Factor de Ajuste por Agrupamiento: 1.00",
        "• Exención Niple 24\": Disponible (60% Fill)",
        "• Protección Adecuada para Interruptor 30A",
    ]
    iy = 510
    for it in items_dt:
        draw3.text((c2_l + 50, iy), it, font=f_item, fill=(203, 213, 225, 255))
        iy += 68

    s3_path = os.path.join(out_dir, "video_16x9_voltage_1920x1080.png")
    s3.save(s3_path, "PNG")
    print(f"-> Saved: {s3_path} (1920x1080)")

    # =========================================================================
    # 6. VIDEO SCENE 4: SIGNED TECHNICAL PDF REPORTS (1920x1080 Full HD 16:9)
    # =========================================================================
    s4 = Image.new("RGBA", (w, h), (7, 11, 20, 255))
    draw4 = ImageDraw.Draw(s4)
    draw_hgradient(draw4, w, h, (8, 12, 22), (20, 28, 45))
    s4 = add_glow(s4, 520, 540, 500, (0, 230, 118), max_alpha=40)
    
    draw4 = ImageDraw.Draw(s4)
    
    # Left: White High-End Document Mockup
    doc_l, doc_t, doc_r, doc_b = 140, 100, 860, 980
    draw4.rounded_rectangle([doc_l, doc_t, doc_r, doc_b], radius=24, fill=(255, 255, 255, 255), outline=(226, 232, 240, 255), width=2)
    
    # Document Dark Top Header
    draw4.rounded_rectangle([doc_l, doc_t, doc_r, doc_t + 130], radius=24, fill=(11, 15, 25, 255))
    f_doc_title = ImageFont.truetype(font_bold, 36)
    f_doc_sub = ImageFont.truetype(font_reg, 24)
    draw4.text((doc_l + 40, doc_t + 30), "MEMORIA TÉCNICA OFICIAL NEC", font=f_doc_title, fill=(0, 230, 118, 255))
    draw4.text((doc_l + 40, doc_t + 80), "Conforme a NFPA 70 / NEC 2026 • NOM-001 • RETIE", font=f_doc_sub, fill=(203, 213, 225, 255))
    
    # PDF Body details
    f_doc_sec = ImageFont.truetype(font_bold, 24)
    f_doc_txt = ImageFont.truetype(font_reg, 22)
    
    draw4.text((doc_l + 40, doc_t + 160), "PROYECTO: Tablero Principal MDP-1 | ID: EN-9482", font=f_doc_sec, fill=(15, 23, 42, 255))
    draw4.text((doc_l + 40, doc_t + 195), "CLIENTE: Subestación Industrial Norte | FECHA: 10 Nov 2026", font=f_doc_txt, fill=(100, 116, 139, 255))
    draw4.line([(doc_l + 40, doc_t + 240), (doc_r - 40, doc_t + 240)], fill=(226, 232, 240, 255), width=2)
    
    draw4.text((doc_l + 40, doc_t + 265), "CANALIZACIÓN: EMT 3/4\" (Ocupación: 32.8% <= 40%)", font=f_doc_sec, fill=(15, 23, 42, 255))
    draw4.text((doc_l + 40, doc_t + 305), "✓ Caída de Tensión: 1.85% [Pasa <= 3%]", font=f_doc_txt, fill=(16, 185, 129, 255))
    draw4.text((doc_l + 40, doc_t + 345), "✓ Ampacidad Corregida: 28.0 A [Conductor 10 AWG THHN]", font=f_doc_txt, fill=(16, 185, 129, 255))
    draw4.text((doc_l + 40, doc_t + 385), "✓ Relación Jam Ratio: 3.42 [Sin riesgo de atascamiento]", font=f_doc_txt, fill=(16, 185, 129, 255))

    # Cross section inside PDF
    p_cx, p_cy = (doc_l + doc_r) // 2, doc_t + 540
    draw4.ellipse([p_cx - 100, p_cy - 100, p_cx + 100, p_cy + 100], fill=(241, 245, 249, 255), outline=(71, 85, 105, 255), width=2)
    draw4.ellipse([p_cx - 35, p_cy - 35, p_cx + 35, p_cy + 35], fill=(213, 0, 0, 255))
    draw4.ellipse([p_cx + 35, p_cy - 35, p_cx + 105, p_cy + 35], fill=(41, 121, 255, 255))
    draw4.ellipse([p_cx - 35, p_cy + 35, p_cx + 35, p_cy + 105], fill=(66, 66, 66, 255))
    draw4.ellipse([p_cx - 85, p_cy - 5, p_cx - 35, p_cy + 45], fill=(46, 125, 50, 255))

    # Digital Signature Box
    sig_y = doc_t + 740
    draw4.line([(doc_l + 50, sig_y), (doc_l + 450, sig_y)], fill=(15, 23, 42, 255), width=2)
    draw4.text((doc_l + 50, sig_y + 12), "Firma Digital del Ingeniero / Inspector AHJ", font=f_doc_sec, fill=(15, 23, 42, 255))
    draw4.text((doc_l + 50, sig_y + 45), "Certificación Profesional Aprobada", font=f_doc_txt, fill=(100, 116, 139, 255))
    
    # Signature line
    sig_pts = [(doc_l + 80, sig_y - 25), (doc_l + 130, sig_y - 70), (doc_l + 170, sig_y - 15), (doc_l + 230, sig_y - 80), (doc_l + 370, sig_y - 20)]
    for i in range(len(sig_pts) - 1):
        draw4.line([sig_pts[i], sig_pts[i+1]], fill=(15, 23, 42, 255), width=3)

    # Right Column: Pitch & Benefits
    tx4 = 960
    draw4.rounded_rectangle([tx4, 180, tx4 + 480, 240], radius=18, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
    draw4.text((tx4 + 25, 196), "REPORTES PARA INSPECCIÓN AHJ", font=f_badge1, fill=(0, 230, 118, 255))
    
    f_h4 = ImageFont.truetype(font_bold, 64)
    draw4.text((tx4, 270), "Exporta Memorias en PDF\nFirmadas y Listas", font=f_h4, fill=(248, 250, 252, 255))
    
    f_sub4 = ImageFont.truetype(font_reg, 32)
    pdf_points = [
        "• Generación instantánea en tu dispositivo sin internet.",
        "• Firma digitalizada en pantalla para peritos e inspectores.",
        "• Sección transversal vectorial a escala con código de colores.",
        "• Tablas completas de cumplimiento normativo NEC.",
        "• Comparte por WhatsApp, correo o imprime en obra.",
    ]
    py = 480
    for pt in pdf_points:
        draw4.text((tx4, py), pt, font=f_sub4, fill=(203, 213, 225, 255))
        py += 75

    s4_path = os.path.join(out_dir, "video_16x9_reports_1920x1080.png")
    s4.save(s4_path, "PNG")
    print(f"-> Saved: {s4_path} (1920x1080)")

    # =========================================================================
    # 7. VIDEO SCENE 5: CALL TO ACTION (CTA) END-CARD (1920x1080 Full HD 16:9)
    # =========================================================================
    s5 = Image.new("RGBA", (w, h), (7, 11, 20, 255))
    draw5 = ImageDraw.Draw(s5)
    draw_hgradient(draw5, w, h, (5, 9, 16), (15, 23, 42))
    s5 = add_glow(s5, 960, 400, 600, (0, 230, 118), max_alpha=55)
    
    # Centered Logo
    ic_cta = base_icon.resize((320, 320), Image.Resampling.LANCZOS)
    s5.paste(ic_cta, (960 - 160, 140), ic_cta)
    
    draw5 = ImageDraw.Draw(s5)
    f_cta_h = ImageFont.truetype(font_bold, 74)
    f_cta_sub = ImageFont.truetype(font_reg, 36)
    f_cta_btn = ImageFont.truetype(font_bold, 42)
    
    draw5.text((960 - 360, 480), "ElectroNorm Pro", font=f_cta_h, fill=(248, 250, 252, 255))
    draw5.text((960 - 460, 570), "La Herramienta Definitiva para Instaladores Eléctricos", font=f_cta_sub, fill=(148, 163, 184, 255))
    
    # Big Green CTA Button
    btn_l, btn_t, btn_r, btn_b = 960 - 350, 670, 960 + 350, 770
    draw5.rounded_rectangle([btn_l, btn_t, btn_r, btn_b], radius=28, fill=(0, 230, 118, 255))
    draw5.text((960 - 240, 695), "Descargar en Google Play", font=f_cta_btn, fill=(0, 0, 0, 255))
    
    # Sub CTA
    draw5.text((960 - 330, 810), "★ 14 Días de Prueba Gratuita • 100% Sin Anuncios ★", font=f_badge1, fill=(0, 230, 118, 255))
    draw5.text((960 - 280, 870), "Disponible para Teléfonos, Tablets y Pantallas Grandes", font=f_tag1, fill=(100, 116, 139, 255))

    s5_path = os.path.join(out_dir, "video_16x9_cta_1920x1080.png")
    s5.save(s5_path, "PNG")
    print(f"-> Saved: {s5_path} (1920x1080)")

    # =========================================================================
    # 8. SQUARE MARKETING ASSETS (1200x1200) - For Video Templates & Ad Grid
    # =========================================================================
    def create_square_feature(fname, title, subtitle, badge_txt, icon_element_type):
        sq = Image.new("RGBA", (1200, 1200), (10, 15, 28, 255))
        d_sq = ImageDraw.Draw(sq)
        draw_hgradient(d_sq, 1200, 1200, (7, 11, 20), (22, 31, 48))
        sq = add_glow(sq, 600, 600, 500, (0, 230, 118), max_alpha=35)
        d_sq = ImageDraw.Draw(sq)
        
        # Top Pill
        f_sq_b = ImageFont.truetype(font_bold, 30)
        d_sq.rounded_rectangle([100, 90, 720, 160], radius=20, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
        d_sq.text((130, 108), badge_txt.upper(), font=f_sq_b, fill=(0, 230, 118, 255))
        
        # Title & Subtitle
        f_sq_h = ImageFont.truetype(font_bold, 60)
        f_sq_s = ImageFont.truetype(font_reg, 32)
        d_sq.text((100, 190), title, font=f_sq_h, fill=(248, 250, 252, 255))
        d_sq.text((100, 270), subtitle, font=f_sq_s, fill=(148, 163, 184, 255))
        
        # Center Hero Graphic
        if icon_element_type == "icon":
            ic = base_icon.resize((480, 480), Image.Resampling.LANCZOS)
            sq.paste(ic, (360, 380), ic)
        elif icon_element_type == "conduit":
            # Circular conduit
            cx, cy = 600, 620
            d_sq.ellipse([cx - 240, cy - 240, cx + 240, cy + 240], fill=(51, 65, 85, 255))
            d_sq.ellipse([cx - 210, cy - 210, cx + 210, cy + 210], fill=(7, 11, 20, 255))
            for ox, oy, col in [(-65, -65, (66, 66, 66)), (65, -65, (213, 0, 0)), (65, 65, (41, 121, 255)), (-65, 65, (46, 125, 50))]:
                d_sq.ellipse([cx + ox - 60, cy + oy - 60, cx + ox + 60, cy + oy + 60], fill=col)
                d_sq.ellipse([cx + ox - 20, cy + oy - 20, cx + ox + 20, cy + oy + 20], fill=(217, 119, 6, 255))
        
        # Bottom Card
        d_sq.rounded_rectangle([100, 920, 1100, 1100], radius=24, fill=(22, 31, 48, 255), outline=(0, 230, 118, 200), width=2)
        f_sq_btn = ImageFont.truetype(font_bold, 36)
        d_sq.text((140, 955), "⚡ ElectroNorm Pro • Descarga en Google Play", font=f_sq_btn, fill=(255, 255, 255, 255))
        d_sq.text((140, 1020), "14 Días de Prueba Gratis • Cálculos NEC 100% Offline", font=f_sq_s, fill=(0, 230, 118, 255))
        
        p = os.path.join(out_dir, fname)
        sq.save(p, "PNG")
        print(f"-> Saved: {p} (1200x1200)")

    create_square_feature("video_1x1_feature_1200x1200.png", "Cálculo Eléctrico NEC", "Llenado de Tuberías y Caída de Tensión", "Herramienta Profesional", "icon")
    create_square_feature("video_1x1_conduit_1200x1200.png", "Ocupación de Canalizaciones", "Cálculo instantáneo según NEC Cap. 9", "Conduit Fill en Vivo", "conduit")

    # =========================================================================
    # 9. COPY CONVENIENT ASSETS DIRECTLY TO DOWNLOADS
    # =========================================================================
    user_downloads = os.path.expanduser("~/Downloads")
    dl_video_dir = os.path.join(user_downloads, "ElectroNorm_Google_Ads_Assets")
    os.makedirs(dl_video_dir, exist_ok=True)
    
    files_to_copy = [
        "logo_1200x1200.png",
        "logo_transparent_1200x1200.png",
        "logo_landscape_1200x300.png",
        "video_16x9_hero_1920x1080.png",
        "video_16x9_conduit_1920x1080.png",
        "video_16x9_voltage_1920x1080.png",
        "video_16x9_reports_1920x1080.png",
        "video_16x9_cta_1920x1080.png",
        "video_1x1_feature_1200x1200.png",
        "video_1x1_conduit_1200x1200.png",
    ]
    
    for f in files_to_copy:
        src = os.path.join(out_dir, f)
        dst = os.path.join(dl_video_dir, f)
        shutil.copy2(src, dst)
        
    print(f"\nAll assets successfully copied to Downloads: {dl_video_dir}")

if __name__ == "__main__":
    create_video_assets()
