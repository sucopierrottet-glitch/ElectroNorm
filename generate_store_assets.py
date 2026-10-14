import os
import math
from PIL import Image, ImageDraw, ImageFont

def generate_store_assets():
    out_dir = "store_assets"
    os.makedirs(out_dir, exist_ok=True)
    
    font_bold_path = "C:/Windows/Fonts/segoeuib.ttf"
    font_reg_path = "C:/Windows/Fonts/segoeui.ttf"
    
    # -------------------------------------------------------------
    # 1. ICON 512x512
    # -------------------------------------------------------------
    base_icon_path = "assets/icon/app_icon.png"
    if os.path.exists(base_icon_path):
        base_icon = Image.open(base_icon_path).convert("RGBA")
        icon_512 = base_icon.resize((512, 512), Image.Resampling.LANCZOS)
        icon_512.save(os.path.join(out_dir, "icon_512.png"), "PNG")
        print("Generated icon_512.png")
    
    # -------------------------------------------------------------
    # 2. FEATURE GRAPHIC 1024x500
    # -------------------------------------------------------------
    w_feat, h_feat = 1024, 500
    feat_img = Image.new("RGBA", (w_feat, h_feat), (0, 0, 0, 0))
    feat_draw = ImageDraw.Draw(feat_img)
    
    # Background gradient: Obsidian Dark #070B14 to #0F172A to #161F30
    for x in range(w_feat):
        ratio = x / w_feat
        r = int(7 + (22 - 7) * ratio)
        g = int(11 + (31 - 11) * ratio)
        b = int(20 + (48 - 20) * ratio)
        feat_draw.line([(x, 0), (x, h_feat)], fill=(r, g, b, 255))
        
    # Subtle ambient cyan/green glow circles
    glow_overlay = Image.new("RGBA", (w_feat, h_feat), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    glow_draw.ellipse([80, 50, 480, 450], fill=(0, 230, 118, 25))
    glow_draw.ellipse([600, -100, 1100, 400], fill=(41, 121, 255, 20))
    feat_img = Image.alpha_composite(feat_img, glow_overlay)
    feat_draw = ImageDraw.Draw(feat_img)
    
    # Embed resized app icon on the left
    if os.path.exists(base_icon_path):
        icon_for_feat = Image.open(base_icon_path).convert("RGBA").resize((320, 320), Image.Resampling.LANCZOS)
        feat_img.paste(icon_for_feat, (90, 90), icon_for_feat)
        
    # Text on the right
    f_badge = ImageFont.truetype(font_bold_path, 16)
    f_title = ImageFont.truetype(font_bold_path, 46)
    f_sub = ImageFont.truetype(font_reg_path, 21)
    f_tag = ImageFont.truetype(font_bold_path, 14)
    
    tx = 460
    
    # Badge Pill
    badge_text = "CÁLCULO & REPORTE ELÉCTRICO • NEC"
    feat_draw.rounded_rectangle([tx, 95, tx + 350, 130], radius=18, fill=(0, 230, 118, 35), outline=(0, 230, 118, 180), width=1)
    feat_draw.text((tx + 18, 103), badge_text, font=f_badge, fill=(0, 230, 118, 255))
    
    # Title
    feat_draw.text((tx, 145), "ELECTRONORM PRO", font=f_title, fill=(248, 250, 252, 255))
    
    # Subtitles
    feat_draw.text((tx, 210), "Llenado de Tuberías • Caída de Tensión", font=f_sub, fill=(203, 213, 225, 255))
    feat_draw.text((tx, 240), "Derateo Térmico & Memorias PDF Oficiales", font=f_sub, fill=(148, 163, 184, 255))
    
    # Standards Chips
    standards = ["NEC 2026/2023", "NOM-001-SEDE", "RETIE", "NBR 5410", "LOCAL-FIRST"]
    chip_x = tx
    chip_y = 300
    for std in standards:
        bbox = f_tag.getbbox(std)
        tw = bbox[2] - bbox[0] + 24
        feat_draw.rounded_rectangle([chip_x, chip_y, chip_x + tw, chip_y + 32], radius=8, fill=(22, 31, 48, 255), outline=(45, 60, 82, 255), width=1)
        feat_draw.text((chip_x + 12, chip_y + 7), std, font=f_tag, fill=(148, 163, 184, 255))
        chip_x += tw + 10
        if chip_x > 940:
            chip_x = tx
            chip_y += 42
            
    feat_img.save(os.path.join(out_dir, "feature_graphic_1024x500.png"), "PNG")
    print("Generated feature_graphic_1024x500.png")

    # -------------------------------------------------------------
    # 3. HIGH-RES PHONE SCREENSHOTS (1080x1920)
    # -------------------------------------------------------------
    def create_mockup(filename, banner_tag, main_title, subtitle, card_builder):
        w, h = 1080, 1920
        img = Image.new("RGBA", (w, h), (11, 15, 25, 255))
        draw = ImageDraw.Draw(img)
        
        # Subtle top gradient
        for y in range(400):
            ratio = y / 400
            alpha = int(35 * (1 - ratio))
            draw.line([(0, y), (w, y)], fill=(0, 230, 118, alpha))
            
        f_top_tag = ImageFont.truetype(font_bold_path, 28)
        f_top_title = ImageFont.truetype(font_bold_path, 64)
        f_top_sub = ImageFont.truetype(font_reg_path, 34)
        
        # Header text
        draw.text((70, 90), banner_tag.upper(), font=f_top_tag, fill=(0, 230, 118, 255))
        draw.text((70, 135), main_title, font=f_top_title, fill=(248, 250, 252, 255))
        draw.text((70, 220), subtitle, font=f_top_sub, fill=(148, 163, 184, 255))
        
        # Phone chassis mockup frame
        p_left, p_top, p_right, p_bottom = 80, 310, 1000, 1860
        # Phone border
        draw.rounded_rectangle([p_left, p_top, p_right, p_bottom], radius=54, fill=(16, 23, 37, 255), outline=(45, 60, 82, 255), width=4)
        
        # Screen area inside phone
        s_left, s_top, s_right, s_bottom = p_left + 16, p_top + 16, p_right - 16, p_bottom - 16
        draw.rounded_rectangle([s_left, s_top, s_right, s_bottom], radius=44, fill=(11, 15, 25, 255))
        
        # Phone top status bar & notch pill
        draw.rounded_rectangle([(w // 2) - 80, s_top + 14, (w // 2) + 80, s_top + 44], radius=15, fill=(7, 11, 20, 255))
        
        # Draw custom content inside the phone screen
        card_builder(draw, s_left, s_top + 60, s_right, s_bottom)
        
        img.save(os.path.join(out_dir, filename), "PNG")
        print(f"Generated {filename}")

    # --- Screen 1: Welcome Screen ---
    def draw_screen1(draw, sl, st, sr, sb):
        cx = (sl + sr) // 2
        f_b1 = ImageFont.truetype(font_bold_path, 42)
        f_b2 = ImageFont.truetype(font_reg_path, 26)
        f_btn = ImageFont.truetype(font_bold_path, 32)
        
        # App icon in center
        if os.path.exists(base_icon_path):
            ic = Image.open(base_icon_path).convert("RGBA").resize((220, 220), Image.Resampling.LANCZOS)
            img_x = cx - 110
            img_y = st + 220
            # Draw shadow
            draw.rounded_rectangle([img_x - 10, img_y - 10, img_x + 230, img_y + 230], radius=50, fill=(0, 230, 118, 30))
            # Paste will be done on the image directly
            
        draw.text((cx - 165, st + 490), "ELECTRONORM", font=f_b1, fill=(255, 255, 255, 255))
        draw.text((cx - 245, st + 555), "Cálculos Eléctricos & Reportes NEC", font=f_b2, fill=(148, 163, 184, 255))
        
        # Buttons
        by = st + 820
        # Button 1: Entrar
        draw.rounded_rectangle([sl + 60, by, sr - 60, by + 100], radius=24, fill=(0, 230, 118, 255))
        draw.text((cx - 50, by + 28), "Entrar", font=f_btn, fill=(0, 0, 0, 255))
        
        # Button 2: + Nuevo Cálculo
        draw.rounded_rectangle([sl + 60, by + 130, sr - 60, by + 230], radius=24, fill=(22, 31, 48, 255), outline=(45, 60, 82, 255), width=2)
        draw.text((cx - 130, by + 158), "+ Nuevo Cálculo", font=f_btn, fill=(248, 250, 252, 255))
        
        # Button 3: Proyectos Guardados
        draw.text((cx - 150, by + 280), "📁 Proyectos Guardados", font=f_b2, fill=(100, 116, 139, 255))

    create_mockup("1_pantalla_bienvenida.png", "Diseño Minimalista", "Acceso Rápido & Limpio", "Ideal para obra y campo sin elementos abrumadores", draw_screen1)

    # --- Screen 2: Conduit Fill Calculator ---
    def draw_screen2(draw, sl, st, sr, sb):
        f_h = ImageFont.truetype(font_bold_path, 34)
        f_sub = ImageFont.truetype(font_reg_path, 24)
        f_res = ImageFont.truetype(font_bold_path, 60)
        f_badge = ImageFont.truetype(font_bold_path, 22)
        
        # Top App Bar inside phone
        draw.rounded_rectangle([sl + 30, st + 20, sr - 30, st + 100], radius=16, fill=(22, 31, 48, 255))
        draw.text((sl + 60, st + 42), "⚡ ElectroNorm Pro — EMT 3/4\"", font=f_h, fill=(255, 255, 255, 255))
        
        # Vector Raceway Card
        rc_top = st + 130
        rc_bottom = rc_top + 450
        draw.rounded_rectangle([sl + 30, rc_top, sr - 30, rc_bottom], radius=24, fill=(16, 23, 37, 255), outline=(45, 60, 82, 255), width=2)
        
        # Conduit Circle representation
        cc_x, cc_y = (sl + sr) // 2, (rc_top + rc_bottom) // 2 - 20
        r_outer = 150
        r_inner = 130
        draw.ellipse([cc_x - r_outer, cc_y - r_outer, cc_x + r_outer, cc_y + r_outer], fill=(51, 65, 85, 255))
        draw.ellipse([cc_x - r_inner, cc_y - r_inner, cc_x + r_inner, cc_y + r_inner], fill=(7, 11, 20, 255))
        
        # 4 Packed conductors
        offsets = [(-45, -45, (66, 66, 66)), (45, -45, (213, 0, 0)), (45, 45, (41, 121, 255)), (-45, 45, (46, 125, 50))]
        for ox, oy, col in offsets:
            draw.ellipse([cc_x + ox - 40, cc_y + oy - 40, cc_x + ox + 40, cc_y + oy + 40], fill=col)
            draw.ellipse([cc_x + ox - 14, cc_y + oy - 14, cc_x + ox + 14, cc_y + oy + 14], fill=(180, 83, 9, 255))
            
        draw.text((sl + 60, rc_bottom - 50), "3x #10 AWG + 1x #12 AWG (Cu THHN)", font=f_sub, fill=(148, 163, 184, 255))
        
        # Results Card
        res_top = rc_bottom + 30
        draw.rounded_rectangle([sl + 30, res_top, sr - 30, res_top + 280], radius=24, fill=(22, 31, 48, 255), outline=(0, 230, 118, 180), width=2)
        
        draw.text((sl + 60, res_top + 30), "OCUPACIÓN DE TUBERÍA (NEC CAP. 9)", font=f_badge, fill=(0, 230, 118, 255))
        draw.text((sl + 60, res_top + 70), "32.8%", font=f_res, fill=(255, 255, 255, 255))
        draw.text((sl + 260, res_top + 95), "/ Máximo 40.0% permitido", font=f_sub, fill=(148, 163, 184, 255))
        
        # Compliant Badge
        draw.rounded_rectangle([sr - 240, res_top + 75, sr - 60, res_top + 130], radius=12, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
        draw.text((sr - 215, res_top + 88), "✓ CUMPLE", font=f_badge, fill=(0, 230, 118, 255))
        
        # Jam Ratio Indicator
        draw.text((sl + 60, res_top + 190), "Relación Jam Ratio: 3.42 (Seguro • Sin riesgo de atascamiento)", font=f_sub, fill=(148, 163, 184, 255))
        
        # Conductor schedule list preview
        sched_top = res_top + 310
        draw.rounded_rectangle([sl + 30, sched_top, sr - 30, sched_top + 220], radius=24, fill=(16, 23, 37, 255), outline=(45, 60, 82, 255), width=1)
        draw.text((sl + 60, sched_top + 25), "Conductores en Tubería", font=f_h, fill=(255, 255, 255, 255))
        draw.text((sl + 60, sched_top + 80), "• 3x Fase (A, B, C) — 10 AWG Copper THHN (0.0211 in² c/u)", font=f_sub, fill=(203, 213, 225, 255))
        draw.text((sl + 60, sched_top + 130), "• 1x Tierra — 12 AWG Copper THHN (0.0133 in²)", font=f_sub, fill=(203, 213, 225, 255))

    create_mockup("2_llenado_tuberia_nec.png", "Cálculo Normativo NEC", "Llenado de Tuberías en Vivo", "Cálculo instantáneo según Cap. 9 y detección de Jam Ratio", draw_screen2)

    # --- Screen 3: Voltage Drop & Derating ---
    def draw_screen3(draw, sl, st, sr, sb):
        f_h = ImageFont.truetype(font_bold_path, 34)
        f_sub = ImageFont.truetype(font_reg_path, 24)
        f_res = ImageFont.truetype(font_bold_path, 60)
        f_badge = ImageFont.truetype(font_bold_path, 22)
        
        # Card 1: Voltage Drop
        vd_top = st + 40
        draw.rounded_rectangle([sl + 30, vd_top, sr - 30, vd_top + 420], radius=24, fill=(22, 31, 48, 255), outline=(45, 60, 82, 255), width=2)
        draw.text((sl + 60, vd_top + 30), "ANÁLISIS DE CAÍDA DE TENSIÓN (NEC 210.19)", font=f_badge, fill=(56, 189, 248, 255))
        draw.text((sl + 60, vd_top + 70), "1.85%", font=f_res, fill=(255, 255, 255, 255))
        draw.text((sl + 260, vd_top + 95), "(-3.85 V sobre 208 V 3-Fases)", font=f_sub, fill=(148, 163, 184, 255))
        
        draw.rounded_rectangle([sr - 240, vd_top + 75, sr - 60, vd_top + 130], radius=12, fill=(0, 230, 118, 40), outline=(0, 230, 118, 255), width=2)
        draw.text((sr - 215, vd_top + 88), "✓ CUMPLE", font=f_badge, fill=(0, 230, 118, 255))
        
        draw.text((sl + 60, vd_top + 180), "• Longitud: 120 pies (36.5 metros)", font=f_sub, fill=(203, 213, 225, 255))
        draw.text((sl + 60, vd_top + 230), "• Corriente de Carga: 24.0 Amperios (FP 0.90)", font=f_sub, fill=(203, 213, 225, 255))
        draw.text((sl + 60, vd_top + 280), "• Canalización: Tubo de Acero Magnético (EMT)", font=f_sub, fill=(203, 213, 225, 255))
        draw.text((sl + 60, vd_top + 330), "• Impedancia Efectiva Z: 1.20 Ω/kft (NEC Tabla 9)", font=f_sub, fill=(148, 163, 184, 255))
        
        # Card 2: Thermal Derating
        dt_top = vd_top + 460
        draw.rounded_rectangle([sl + 30, dt_top, sr - 30, dt_top + 420], radius=24, fill=(22, 31, 48, 255), outline=(45, 60, 82, 255), width=2)
        draw.text((sl + 60, dt_top + 30), "DERATEO TÉRMICO Y AGRUPAMIENTO (NEC 310.15)", font=f_badge, fill=(255, 214, 0, 255))
        
        draw.text((sl + 60, dt_top + 70), "28.0 A", font=f_res, fill=(255, 255, 255, 255))
        draw.text((sl + 280, dt_top + 95), "Ampacidad Neta Corregida", font=f_sub, fill=(148, 163, 184, 255))
        
        draw.text((sl + 60, dt_top + 180), "• Ampacidad Base (75°C Terminales): 35.0 A", font=f_sub, fill=(203, 213, 225, 255))
        draw.text((sl + 60, dt_top + 230), "• Temp. Ambiente: 35°C (Factor Temp: 0.96)", font=f_sub, fill=(203, 213, 225, 255))
        draw.text((sl + 60, dt_top + 280), "• 3 Conductores Portadores de Corriente (Factor: 1.0)", font=f_sub, fill=(203, 213, 225, 255))
        draw.text((sl + 60, dt_top + 330), "• Exención Niple 24\": Disponible", font=f_sub, fill=(0, 230, 118, 255))

    create_mockup("3_caida_tension_derateo.png", "Caída de Tensión & Derateo", "Ingeniería de Circuitos en Campo", "Impedancia AC de conductores y corrección de ampacidad", draw_screen3)

    # --- Screen 4: Signed Technical Report PDF ---
    def draw_screen4(draw, sl, st, sr, sb):
        f_h = ImageFont.truetype(font_bold_path, 30)
        f_sub = ImageFont.truetype(font_reg_path, 22)
        f_badge = ImageFont.truetype(font_bold_path, 20)
        
        # Document sheet representation
        doc_top = st + 40
        doc_bottom = st + 1150
        draw.rounded_rectangle([sl + 40, doc_top, sr - 40, doc_bottom], radius=20, fill=(255, 255, 255, 255), outline=(200, 200, 200, 255), width=2)
        
        # PDF Header (Dark corporate banner)
        draw.rounded_rectangle([sl + 40, doc_top, sr - 40, doc_top + 120], radius=20, fill=(11, 15, 25, 255))
        draw.text((sl + 70, doc_top + 25), "MEMORIA DE CÁLCULO ELÉCTRICO", font=f_h, fill=(0, 230, 118, 255))
        draw.text((sl + 70, doc_top + 75), "Conforme a NEC 2026 / NFPA 70 • NOM-001 • RETIE", font=f_sub, fill=(203, 213, 225, 255))
        
        # Meta info
        draw.text((sl + 70, doc_top + 150), "PROYECTO: Alimentador Tablero Principal", font=f_badge, fill=(15, 23, 42, 255))
        draw.text((sl + 70, doc_top + 185), "FECHA: 14 Octubre 2026 | ID: EN-9482", font=f_sub, fill=(100, 116, 139, 255))
        draw.line([(sl + 70, doc_top + 230), (sr - 70, doc_top + 230)], fill=(226, 232, 240, 255), width=2)
        
        # Calculations table
        draw.text((sl + 70, doc_top + 255), "CANALIZACIÓN: EMT 3/4\" (Área Int: 0.533 in²)", font=f_badge, fill=(15, 23, 42, 255))
        draw.text((sl + 70, doc_top + 295), "• Ocupación Total: 32.8% [CUMPLE <= 40%]", font=f_sub, fill=(0, 128, 60, 255))
        draw.text((sl + 70, doc_top + 335), "• Caída de Tensión: 1.85% [CUMPLE <= 3%]", font=f_sub, fill=(0, 128, 60, 255))
        draw.text((sl + 70, doc_top + 375), "• Ampacidad Corregida: 28.0 A [CUMPLE]", font=f_sub, fill=(0, 128, 60, 255))
        
        # Mini cross-section inside PDF
        px, py = (sl + sr) // 2, doc_top + 550
        draw.ellipse([px - 100, py - 100, px + 100, py + 100], fill=(241, 245, 249, 255), outline=(71, 85, 105, 255), width=3)
        draw.ellipse([px - 35, py - 35, px + 35, py + 35], fill=(213, 0, 0, 255))
        draw.ellipse([px + 35, py - 35, px + 105, py + 35], fill=(41, 121, 255, 255))
        draw.ellipse([px - 35, py + 35, px + 35, py + 105], fill=(66, 66, 66, 255))
        draw.ellipse([px - 85, py - 5, px - 35, py + 45], fill=(46, 125, 50, 255))
        
        # Signature block
        sig_y = doc_top + 780
        draw.line([(sl + 70, sig_y), (sl + 420, sig_y)], fill=(15, 23, 42, 255), width=2)
        draw.text((sl + 70, sig_y + 10), "Firma del Ingeniero / Inspector", font=f_badge, fill=(15, 23, 42, 255))
        draw.text((sl + 70, sig_y + 40), "Matrícula Profesional / AHJ Cert.", font=f_sub, fill=(100, 116, 139, 255))
        
        # Simulated handwritten signature
        sig_points = [(sl + 100, sig_y - 30), (sl + 150, sig_y - 70), (sl + 180, sig_y - 20), (sl + 230, sig_y - 80), (sl + 350, sig_y - 30)]
        for i in range(len(sig_points) - 1):
            draw.line([sig_points[i], sig_points[i+1]], fill=(15, 23, 42, 255), width=3)

    create_mockup("4_memoria_tecnica_pdf.png", "Memorias de Cálculo PDF", "Reportes Formales Firmados", "Documentos técnicos listos para presentar ante inspectores y clientes", draw_screen4)

if __name__ == "__main__":
    generate_store_assets()
