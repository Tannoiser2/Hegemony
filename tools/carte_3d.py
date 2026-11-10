#!/usr/bin/env python3
"""Disegna in italiano le carte che stanno sul tavolo 3D (aziende, eventi, export, accordi, agende).
Uso: python3 tools/carte_3d.py <cartella ritagli del modulo TTS>
Scrive in assets/carte3d/*.webp. Le posizioni degli slot dei lavoratori sono le stesse di scripts/tavolo3d.gd."""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CROP = sys.argv[1] if len(sys.argv) > 1 else None
OUT = os.path.join(R, "assets", "carte3d")
os.makedirs(OUT, exist_ok=True)
D = json.load(open(os.path.join(R, "dati", "carte.json"), encoding="utf-8"))
F = {k: os.path.join(R, "assets", "font", f"Montserrat-{k}.ttf") for k in ("Regular", "SemiBold", "Bold", "ExtraBold")}

def font(peso, size):
    return ImageFont.truetype(F[peso], size)

ICONE = {}
def icona(n, d):
    k = (n, d)
    if k not in ICONE:
        ICONE[k] = Image.open(os.path.join(R, "assets", "icone", n + ".png")).convert("RGBA").resize((d, d), Image.LANCZOS)
    return ICONE[k]

COL_IND = {"agr": (122, 150, 58), "lus": (16, 138, 206), "sal": (200, 22, 29), "ist": (240, 140, 0), "med": (150, 50, 140), "u": (150, 152, 156)}
COL_POL = [(28, 143, 201), (123, 115, 179), (168, 80, 156), (200, 22, 29), (229, 131, 27), (160, 125, 85), (119, 120, 123)]
NOMI_IND = {"agr": "AGRICOLTURA", "lus": "LUSSO", "sal": "SANITÀ", "ist": "ISTRUZIONE", "med": "MEDIA"}
RIS_IND = {"agr": "cibo", "lus": "lus", "sal": "sal", "ist": "ist", "med": "inf"}
W, H = 360, 500
SCURO = (34, 38, 44)

# slot dei lavoratori: frazioni (x, y) della carta, uguali in tavolo3d.gd
def posizioni_slot(n, dip):
    tot = n + (1 if dip else 0)
    passo = 0.24 if tot <= 3 else 0.2
    x0 = 0.5 - passo * (tot - 1) / 2
    return [(x0 + i * passo, 0.64) for i in range(tot)]

def a_capo(d, testo, f, larg):
    righe, riga = [], ""
    for p in testo.split():
        t = (riga + " " + p).strip()
        if d.textlength(t, font=f) <= larg:
            riga = t
        else:
            if riga:
                righe.append(riga)
            riga = p
    if riga:
        righe.append(riga)
    return righe

def centra(d, y, testo, f, col, x0=0, x1=W):
    w = d.textlength(testo, font=f)
    d.text(((x0 + x1 - w) / 2, y), testo, font=f, fill=col)

def testo_icone(img, d, x, y, larg, testo, f, col, interl=1.25):
    """Testo con segnaposto {cibo} {V} ... resi come icone; ritorna la y finale."""
    alt = int(f.size * interl)
    sost = {"{V}": "soldi", "{VP}": "vp", "{cibo}": "cibo", "{lus}": "lus", "{sal}": "sal", "{ist}": "ist", "{inf}": "inf", "{mac}": "mac"}
    parole = []
    for p in testo.replace("{V}", " {V}").replace("{VP}", " {VP}").split():
        for k in sost:
            if k in p and p != k:
                a, b = p.split(k, 1)
                parole += [w for w in (a, k, b) if w]
                break
        else:
            parole.append(p)
    cx = x
    for p in parole:
        if p in sost:
            w = f.size + 2
        else:
            w = d.textlength(p, font=f)
        if cx + w > x + larg and cx > x:
            cx = x
            y += alt
        if p in sost:
            ic = icona(sost[p], f.size + 2)
            img.alpha_composite(ic, (int(cx), int(y + 1)))
        else:
            d.text((cx, y), p, font=f, fill=col)
        cx += w + d.textlength(" ", font=f)
    return y + alt

def base(bordo):
    img = Image.new("RGBA", (W, H), (246, 245, 241, 255))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, W - 1, H - 1], radius=18, outline=bordo, width=8)
    return img, d

def illustrazione(img, aid, box):
    if CROP is None:
        return
    if aid == "coop":
        src = os.path.join(CROP, "..", "coop.png")
    else:
        sub = {"c": "cap", "m": "mc", "p": "pub"}[aid[0]]
        src = os.path.join(CROP, sub, aid + ".png")
    im = Image.open(src).convert("RGB")
    w, h = im.size
    im = im.crop((int(w * 0.04), int(h * 0.125), int(w * 0.96), int(h * 0.495)))
    bw, bh = box[2] - box[0], box[3] - box[1]
    r = max(bw / im.size[0], bh / im.size[1])
    im = im.resize((int(im.size[0] * r) + 1, int(im.size[1] * r) + 1), Image.LANCZOS)
    im = im.crop(((im.size[0] - bw) // 2, (im.size[1] - bh) // 2, (im.size[0] - bw) // 2 + bw, (im.size[1] - bh) // 2 + bh))
    img.paste(im, box[:2])

def azienda(aid, a):
    col = COL_IND[a["ind"]]
    img, d = base(col)
    illustrazione(img, aid, (12, 12, W - 12, 178))
    # fascia del nome
    d.rectangle([8, 178, W - 8, 246], fill=col)
    nome = a["n"].upper()
    f = font("ExtraBold", 24)
    righe = a_capo(d, nome, f, W - 30)
    if len(righe) > 2:
        f = font("ExtraBold", 19)
        righe = a_capo(d, nome, f, W - 30)
    y = 212 - len(righe) * f.size * 0.62
    for r in righe:
        centra(d, y, r, f, (255, 255, 255))
        y += f.size * 1.18
    # costo e tipo
    proprietario = {"CC": "CAPITALISTA", "MC": "CLASSE MEDIA", "PUB": "PUBBLICA", "COOP": "COOPERATIVA"}[a["tipo"]]
    d.text((18, 256), proprietario, font=font("Bold", 15), fill=(110, 114, 120))
    if a["costo"]:
        t = str(a["costo"])
        f2 = font("ExtraBold", 26)
        w = d.textlength(t, font=f2)
        img.alpha_composite(icona("soldi", 24), (int(W - 24 - w - 30), 254))
        d.text((W - 20 - w, 251), t, font=f2, fill=SCURO)
    # slot dei lavoratori
    dip = a.get("dip", "") if a["tipo"] == "MC" else ""
    slot = list(a["slot"])
    if a["auto"]:
        img.alpha_composite(icona("mac", 64), (W // 2 - 32, 274))
        centra(d, 338, "AUTOMATIZZATA", font("Bold", 17), (90, 94, 100))
    else:
        tutti = slot + ([dip] if dip else [])
        pos = posizioni_slot(len(slot), bool(dip))
        for i, (sk, (fx, fy)) in enumerate(zip(tutti, pos)):
            cx, cy = fx * W, fy * H
            c = COL_IND[sk]
            dipendente = dip and i == len(tutti) - 1
            d.ellipse([cx - 31, cy - 31, cx + 31, cy + 31], fill=(255, 255, 255), outline=c, width=7)
            if dipendente:
                d.ellipse([cx - 37, cy - 37, cx + 37, cy + 37], outline=(227, 38, 46), width=3)
            if sk != "u":
                img.alpha_composite(icona(RIS_IND[sk] if sk != "med" else "inf", 30), (int(cx - 15), int(cy - 15)))
        if dip:
            x = (pos[-2][0] + pos[-1][0]) / 2 * W
            centra(d, 0.64 * H - 16, "+", font("ExtraBold", 26), SCURO, x - 20, x + 20)
    # produzione
    y0 = 370
    d.line([16, y0 - 8, W - 16, y0 - 8], fill=(210, 210, 205), width=2)
    ris = RIS_IND[a["ind"]]
    t = str(a["prod"])
    f3 = font("ExtraBold", 40)
    d.text((24, y0), t, font=f3, fill=SCURO)
    x = 24 + d.textlength(t, font=f3) + 6
    img.alpha_composite(icona(ris, 40), (int(x), y0 + 5))
    x += 48
    bonus = a.get("mac", 0) if a["tipo"] == "CC" else a.get("bonus", 0)
    if bonus:
        s = f"+{bonus}"
        d.text((x, y0 + 8), s, font=font("Bold", 26), fill=SCURO)
        x += d.textlength(s, font=font("Bold", 26)) + 4
        ic = icona("mac" if a["tipo"] == "CC" else "lavoratore", 28).copy()
        if a["tipo"] != "CC":
            ic = Image.composite(Image.new("RGBA", ic.size, (227, 38, 46, 255)), Image.new("RGBA", ic.size, (0, 0, 0, 0)), ic.split()[3])
        img.alpha_composite(ic, (int(x), y0 + 10))
    # salari L1 L2 L3 (x delle caselle: 0.2, 0.5, 0.8 della carta; y 0.9)
    if not a["auto"] and a["sal"][0] > 0:
        for i, v in enumerate(a["sal"]):
            cx = W * (0.2 + 0.3 * i)
            d.rounded_rectangle([cx - 46, 428, cx + 46, 482], radius=10, fill=(232, 231, 226), outline=(190, 190, 186), width=2)
            centra(d, 430, f"L{i + 1}", font("Bold", 15), (110, 114, 120), cx - 46, cx + 46)
            centra(d, 448, str(v), font("ExtraBold", 26), SCURO, cx - 46, cx + 46)
    elif a["tipo"] == "COOP":
        centra(d, 440, "NIENTE SALARI", font("Bold", 17), (110, 114, 120))
    img.convert("RGB").save(os.path.join(OUT, aid + ".webp"), quality=86)

def evento(e):
    img, d = base((240, 167, 46))
    f = font("ExtraBold", 21)
    righe = a_capo(d, e["it"].upper(), f, W - 40)
    alto = 52 + len(righe[:3]) * (f.size + 3)
    d.rectangle([8, 8, W - 8, alto], fill=(43, 49, 57))
    d.rounded_rectangle([18, 18, 120, 42], radius=8, fill=(240, 167, 46))
    centra(d, 21, "ULTIM'ORA", font("ExtraBold", 13), SCURO, 18, 120)
    y = 48
    for r in righe[:3]:
        d.text((20, y), r, font=f, fill=(255, 255, 255))
        y += f.size + 3
    y = alto + 14
    y = testo_icone(img, d, 20, y, W - 40, e["t"], font("SemiBold", 21), SCURO)
    y = max(y + 8, 300)
    d.line([16, y, W - 16, y], fill=(210, 210, 205), width=2)
    y += 8
    nomi = {"WC": "Operai", "MC": "Ceto medio", "CC": "Capitalisti"}
    if isinstance(e["pen"], str):
        pen = "-1 Legittimità a due classi"
    else:
        pen = ", ".join(f"{int(x[1])} {nomi[x[0]]}" for x in e["pen"])
    d.text((20, y), "SENZA AZIONE:", font=font("ExtraBold", 14), fill=(200, 22, 29))
    y += 18
    y = testo_icone(img, d, 20, y, W - 40, pen, font("SemiBold", 15), SCURO) + 4
    d.text((20, y), "RICOMPENSE:", font=font("ExtraBold", 14), fill=(46, 125, 50))
    y += 18
    premi = []
    for k, v in e["sc"].items():
        premi.append(f"{nomi.get(k, k)}: {descrivi_premio(v)}")
    testo_icone(img, d, 20, y, W - 40, "; ".join(premi), font("SemiBold", 15), SCURO)
    img.convert("RGB").save(os.path.join(OUT, e["id"] + ".webp"), quality=86)

def descrivi_premio(pr):
    f = pr.split(":") + ["", "", ""]
    if f[0] == "vp_per":
        return f"{f[3] or 1} PV ogni {f[1]}"
    return {"tok": "gettone Legittimità", "leg": f"+{f[-1]} Legittimità", "leg_per": f"+1 Legittimità ogni {f[1]}",
            "tok_per": f"gettone ogni {f[1]}", "vp_per": f"{f[3] if len(f) > 3 else 1} PV ogni {f[1]}", "vp": f"{f[-1]} PV",
            "leg_tutte": "+1 Legittimità a tutte"}.get(f[0], pr)

def export(i, x):
    img, d = base((160, 125, 85))
    d.rectangle([8, 8, W - 8, 70], fill=(43, 49, 57))
    centra(d, 24, "ESPORTAZIONI", font("ExtraBold", 26), (255, 255, 255))
    y = 92
    for r in ("cibo", "lus", "sal", "ist"):
        img.alpha_composite(icona(r, 56), (24, y + 10))
        for k in range(2):
            q, s = x[r][k]
            cx = 150 + k * 108
            d.rounded_rectangle([cx - 4, y, cx + 96, y + 78], radius=10, fill=(232, 231, 226))
            centra(d, y + 4, f"{q}", font("ExtraBold", 28), SCURO, cx - 4, cx + 96)
            centra(d, y + 40, f"per {s}", font("Bold", 20), (110, 80, 30), cx - 4, cx + 96)
        y += 98
    img.convert("RGB").save(os.path.join(OUT, f"x{i:02d}.webp"), quality=86)

def accordo(i, a):
    img, d = base((16, 138, 206))
    d.rectangle([8, 8, W - 8, 70], fill=(43, 49, 57))
    centra(d, 14, "ACCORDO", font("ExtraBold", 24), (255, 255, 255))
    centra(d, 42, "COMMERCIALE", font("ExtraBold", 18), (240, 167, 46))
    y = 100
    for r in ("cibo", "lus"):
        if a[r]:
            t = str(a[r])
            f = font("ExtraBold", 64)
            w = d.textlength(t, font=f) + 80
            x = (W - w) / 2
            d.text((x, y), t, font=f, fill=SCURO)
            img.alpha_composite(icona(r, 70), (int(x + w - 76), y + 8))
            y += 96
    y = max(y, 300)
    centra(d, y, "COSTO", font("Bold", 18), (110, 114, 120))
    centra(d, y + 22, str(a["costo"]), font("ExtraBold", 44), SCURO)
    centra(d, y + 84, "DAZI  6A %d · 6B %d · 6C 0" % (a["dazio"][0], a["dazio"][1]), font("Bold", 18), (110, 114, 120))
    img.convert("RGB").save(os.path.join(OUT, f"b{i:02d}.webp"), quality=86)

def agenda(i, ag):
    img, d = base((167, 169, 172))
    d.rectangle([8, 8, W - 8, 70], fill=(43, 49, 57))
    centra(d, 14, "AGENDA", font("ExtraBold", 24), (255, 255, 255))
    centra(d, 42, "POLITICA", font("ExtraBold", 18), (240, 167, 46))
    y = 90
    nomi = ["Fiscale", "Lavoro", "Tasse", "Sanità", "Istruzione"]
    for k in range(5):
        d.rounded_rectangle([24, y, W - 24, y + 68], radius=12, fill=COL_POL[k])
        d.text((40, y + 12), f"{k + 1}{ag[k]}", font=font("ExtraBold", 36), fill=(255, 255, 255))
        d.text((130, y + 22), nomi[k].upper(), font=font("Bold", 20), fill=(255, 255, 255))
        y += 80
    img.convert("RGB").save(os.path.join(OUT, f"g{i:02d}.webp"), quality=86)

for aid, a in D["aziende"].items():
    azienda(aid, a)
for e in D["eventi"]:
    evento(e)
for i, x in enumerate(D["export"]):
    export(i, x)
for i, a in enumerate(D["accordi"]):
    accordo(i, a)
for i, ag in enumerate(D["agende"]):
    agenda(i, ag)
print(len(os.listdir(OUT)), "carte")
