from PIL import Image, ImageDraw, ImageFont
import math

def draw_controller():
    # Dimensiones estilo celular en landscape
    w, h = 2400, 1080
    img = Image.new('RGB', (w, h), color=(30, 30, 30))
    draw = ImageDraw.Draw(img)
    
    # Try to load a font, fallback to default if not found
    try:
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
        font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 30)
    except IOError:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()

    # Helpers
    def draw_circle(x, y, r, color, outline=None, width=0):
        draw.ellipse([x-r, y-r, x+r, y+r], fill=color, outline=outline, width=width)
        
    def draw_round_rect(x, y, bw, bh, color, radius=20):
        draw.rounded_rectangle([x, y, x+bw, y+bh], radius=radius, fill=color)

    # 1. Left Joystick (Throttle+Yaw)
    # x: 18%, y: 60%, size: 28% of width (~672px outer)
    lx, ly = int(w * 0.18), int(h * 0.60)
    lr_outer = int(w * 0.28 / 2)
    lr_inner = int(lr_outer * 0.38)
    draw_circle(lx, ly, lr_outer, (50, 50, 50), outline=(80, 80, 80), width=4)
    # Para FPV Mode 2, el throttle (stick izquierdo) suele estar abajo por defecto
    draw_circle(lx, ly + int(lr_outer*0.6), lr_inner, (100, 100, 100))
    
    draw.text((lx - 80, ly - lr_outer - 50), "Throttle + Yaw", fill=(200, 200, 200), font=font_medium)

    # 2. Right Joystick (Pitch+Roll)
    # x: 82%, y: 60%, size: 28%
    rx, ry = int(w * 0.82), int(h * 0.60)
    draw_circle(rx, ry, lr_outer, (50, 50, 50), outline=(80, 80, 80), width=4)
    # Right stick centrado por defecto
    draw_circle(rx, ry, lr_inner, (100, 100, 100))
    
    draw.text((rx - 80, ry - lr_outer - 50), "Pitch + Roll", fill=(200, 200, 200), font=font_medium)

    # 3. Botones ABXY (Arriba a la derecha del stick derecho)
    # y: 35%, spacing: 12%, size: 10% (~240px)
    face_y = int(h * 0.35)
    btn_r = int(w * 0.10 / 2)
    spacing = int(w * 0.12)
    
    # A (ARM) - Abajo
    ax, ay = rx, face_y + spacing
    draw_circle(ax, ay, btn_r, (255, 68, 68)) # Red
    draw.text((ax-45, ay-20), "ARM", fill=(255,255,255), font=font_large)
    
    # B (ANG) - Derecha
    bx, by = rx + spacing, face_y
    draw_circle(bx, by, btn_r, (68, 170, 255)) # Blue
    draw.text((bx-45, by-20), "ANG", fill=(255,255,255), font=font_large)
    
    # X (ACRO) - Izquierda
    xx, xy = rx - spacing, face_y
    draw_circle(xx, xy, btn_r, (255, 136, 0)) # Orange
    draw.text((xx-55, xy-20), "ACRO", fill=(255,255,255), font=font_large)
    
    # Y (BEEP) - Arriba
    yx, yy = rx, face_y - spacing
    draw_circle(yx, yy, btn_r, (68, 221, 136)) # Green
    draw.text((yx-55, yy-20), "BEEP", fill=(255,255,255), font=font_large)

    # 4. Triggers & Bumpers
    # triggerY = 8%, lbY = 18%, w=14%, h=7%
    tw, th = int(w * 0.14), int(h * 0.07)
    lty, lby = int(h * 0.08), int(h * 0.18)
    lx_trig, rx_trig = int(w * 0.05), int(w * 0.81)

    draw_round_rect(lx_trig, lty, tw, th, (80, 80, 80))
    draw.text((lx_trig + tw//2 - 20, lty + th//2 - 20), "LT", fill=(255,255,255), font=font_medium)
    
    draw_round_rect(lx_trig, lby, tw, th, (100, 100, 100))
    draw.text((lx_trig + tw//2 - 20, lby + th//2 - 20), "LB", fill=(255,255,255), font=font_medium)

    draw_round_rect(rx_trig, lty, tw, th, (80, 80, 80))
    draw.text((rx_trig + tw//2 - 20, lty + th//2 - 20), "RT", fill=(255,255,255), font=font_medium)
    
    draw_round_rect(rx_trig, lby, tw, th, (100, 100, 100))
    draw.text((rx_trig + tw//2 - 20, lby + th//2 - 20), "RB", fill=(255,255,255), font=font_medium)

    # 5. Start / Select (Centro)
    # Y = 22%, X = 40% & 52%, size = 8%
    mx1, mx2 = int(w * 0.40), int(w * 0.52)
    my = int(h * 0.22)
    mr = int(w * 0.08 / 2)
    
    draw_circle(mx1, my, mr, (70, 70, 70))
    draw.text((mx1-10, my-20), "...", fill=(255,255,255), font=font_large)
    
    draw_circle(mx2, my, mr, (70, 70, 70))
    draw.text((mx2-15, my-20), "=", fill=(255,255,255), font=font_large)

    img.save('/home/johndeivid/.gemini/antigravity-ide/brain/5c2415da-93ab-484c-af45-360b689c0201/fpv_layout_preview.jpg')

if __name__ == '__main__':
    draw_controller()
