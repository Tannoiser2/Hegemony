#!/usr/bin/env python3
"""Costruisce dati/carte.json e le immagini delle carte dal modulo TTS estratto.
Uso: python3 tools/costruisci_dati.py <cartella ritagli>   (ritagli fatti da tools/ritaglia.py)"""
import json, os, sys
from PIL import Image
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(R, 'tools', 'sorgenti')
CROP = sys.argv[1] if len(sys.argv) > 1 else None
def carica(nome, var):
    ns = {}; exec(open(os.path.join(SRC, nome + '.py'), encoding='utf-8').read(), ns); return ns[var]

# ---------------- aziende
# (id, nome it, nome en, industria, costo, slot, prod, bonus macchinario, salari L1,L2,L3, automatica, partenza)
CC = [
("c00","Supermercato","Supermarket","agr",16,["agr","u"],4,1,(15,20,25),False,True),
("c01","Centro commerciale","Shopping Mall","lus",16,["lus","u"],6,2,(15,20,25),False,True),
("c02","Collegio universitario","College","ist",16,["ist","u"],6,2,(10,20,30),False,True),
("c03","Clinica","Clinic","sal",16,["sal","u"],6,2,(10,20,30),False,True),
("c04","Allevamento ittico","Fish Farm","agr",20,["agr","u","u"],6,1,(25,30,35),False,False),
("c05","Azienda orticola","Vegetable Farm","agr",15,["u","u","u"],5,0,(20,25,30),False,False),
("c06","Supermercato","Supermarket","agr",16,["agr","u"],4,1,(15,20,25),False,False),
("c07","Catena di fast food","Fast Food Chain","agr",8,["u","u"],3,0,(10,15,20),False,False),
("c08","Azienda cerealicola automatizzata","Automated Grain Farm","agr",25,[],2,0,(0,0,0),True,False),
("c09","Caseificio automatizzato","Automated Dairy Farm","agr",45,[],3,0,(0,0,0),True,False),
("c10","Stadio","Stadium","lus",20,["lus","u","u"],8,3,(25,30,35),False,False),
("c11","Hotel","Hotel","lus",15,["u","u","u"],7,0,(20,25,30),False,False),
("c12","Centro commerciale","Shopping Mall","lus",16,["lus","u"],6,2,(15,20,25),False,False),
("c13","Casa di moda","Fashion Company","lus",8,["u","u"],4,2,(10,15,20),False,False),
("c14","Fabbrica di elettronica","Electronics Manufacturer","lus",25,[],3,0,(0,0,0),True,False),
("c15","Fabbrica di automobili","Car Manufacturer","lus",45,[],5,0,(0,0,0),True,False),
("c16","Azienda farmaceutica","Pharmaceutical Company","sal",20,["sal","u","u"],8,3,(20,30,40),False,False),
("c17","Villaggio medico","Medical Village","sal",24,["sal","u","u"],9,2,(20,30,40),False,False),
("c18","Clinica","Clinic","sal",16,["sal","u"],6,2,(10,20,30),False,False),
("c19","Ospedale","Hospital","sal",20,["sal","u"],7,0,(10,20,30),False,False),
("c20","Politecnico","Institute of Technology","ist",20,["ist","u","u"],8,3,(20,30,40),False,False),
("c21","Università","University","ist",24,["ist","u","u"],9,2,(20,30,40),False,False),
("c22","Collegio universitario","College","ist",16,["ist","u"],6,2,(10,20,30),False,False),
("c23","Accademia","Academy","ist",20,["ist","u"],7,0,(10,20,30),False,False),
("c24","Emittente televisiva","TV Station","med",24,["med","u","u"],4,0,(20,30,40),False,False),
("c25","Casa editrice","Publishing House","med",12,["u","u","u"],3,0,(20,25,30),False,False),
("c26","Società di lobbying","Lobbying Firm","med",16,["med","u"],3,0,(10,20,30),False,False),
("c27","Stazione radio","Radio Station","med",8,["u","u"],2,0,(10,15,20),False,False),
]
# (id, it, en, ind, costo, slot classe media, slot dipendente, prod, bonus dipendente, salari, partenza)
MC = [
("m00","Minimarket","Convenience Store","agr",14,["agr"],"u",2,1,(6,8,10),True),
("m01","Studio medico","Doctor's Office","sal",12,["sal"],"u",2,2,(6,8,10),True),
("m02","Fast food","Fast Food Restaurant","agr",20,["agr","u"],"",3,0,(0,0,0),False),
("m03","Minimarket","Convenience Store","agr",14,["agr"],"u",2,1,(6,8,10),False),
("m04","Fattoria biologica","Organic Farm","agr",20,["agr"],"agr",2,2,(9,12,15),False),
("m05","Gioielleria","Jewelry Store","lus",16,["lus","u"],"",4,0,(0,0,0),False),
("m06","Negozio di videogiochi","Game Store","lus",12,["lus"],"u",2,2,(6,8,10),False),
("m07","Negozio di elettronica","Electronics Store","lus",20,["lus"],"lus",2,4,(9,12,15),False),
("m08","Farmacia","Pharmacy","sal",16,["sal","u"],"",4,0,(0,0,0),False),
("m09","Studio medico","Doctor's Office","sal",12,["sal"],"u",2,2,(6,8,10),False),
("m10","Laboratorio di analisi","Medical Laboratory","sal",20,["sal"],"sal",2,4,(9,12,15),False),
("m11","Centro di formazione","Training Center","ist",16,["ist","u"],"",4,0,(0,0,0),False),
("m12","Centro ripetizioni","Tutoring Company","ist",12,["ist"],"u",2,2,(6,8,10),False),
("m13","Scuola privata","Private School","ist",20,["ist"],"ist",2,4,(9,12,15),False),
("m14","Agenzia di PR","PR Agency","med",20,["med","u"],"",3,0,(0,0,0),False),
("m15","Giornale locale","Local Newspaper","med",14,["med"],"u",2,1,(6,8,10),False),
("m16","Radio regionale","Regional Radio Station","med",20,["med"],"med",2,2,(9,12,15),False),
]
# pubbliche: (id, it, en, ind, costo, slot, prod, salari, gruppo: "p"=partenza 3-4 giocatori, "x"=solo 2 giocatori, "r"=riga 2-3)
PUB = [
("p00","Policlinico universitario","University Hospital","sal",30,["sal","u","u"],6,(25,30,35),"p"),
("p01","Ospedale pubblico","Public Hospital","sal",20,["sal","u"],4,(15,20,25),"x"),
("p02","Ospedale pubblico","Public Hospital","sal",20,["sal","u"],4,(15,20,25),"r"),
("p03","Ospedale pubblico","Public Hospital","sal",20,["sal","u"],4,(15,20,25),"r"),
("p04","Università tecnica","Technical University","ist",30,["ist","u","u"],6,(25,30,35),"p"),
("p05","Università pubblica","Public University","ist",20,["ist","u"],4,(15,20,25),"x"),
("p06","Università pubblica","Public University","ist",20,["ist","u"],4,(15,20,25),"r"),
("p07","Università pubblica","Public University","ist",20,["ist","u"],4,(15,20,25),"r"),
("p08","Televisione pubblica nazionale","National Public Broadcasting","med",30,["med","u","u"],4,(25,30,35),"p"),
("p09","TV regionale","Regional TV Station","med",20,["med","u"],3,(15,20,25),"x"),
("p10","TV regionale","Regional TV Station","med",20,["med","u"],3,(15,20,25),"r"),
("p11","TV regionale","Regional TV Station","med",20,["med","u"],3,(15,20,25),"r"),
]
aziende = {}
for (i,it,en,ind,co,sl,pr,bm,sa,au,st) in CC:
    aziende[i] = dict(id=i,n=it,en=en,ind=ind,costo=co,tipo="CC",slot=sl,prod=pr,mac=bm,sal=list(sa),auto=au,start=st)
for (i,it,en,ind,co,sl,dip,pr,bd,sa,st) in MC:
    aziende[i] = dict(id=i,n=it,en=en,ind=ind,costo=co,tipo="MC",slot=sl,dip=dip,prod=pr,bonus=bd,sal=list(sa),auto=False,start=st,mac=0)
for (i,it,en,ind,co,sl,pr,sa,gr) in PUB:
    aziende[i] = dict(id=i,n=it,en=en,ind=ind,costo=co,tipo="PUB",slot=sl,prod=pr,sal=list(sa),auto=False,gruppo=gr,mac=0)
aziende["coop"] = dict(id="coop",n="Cooperativa agricola",en="Cooperative Farm",ind="agr",costo=0,tipo="COOP",slot=["u","u","u"],prod=2,sal=[0,0,0],auto=False,mac=0)

# ---------------- carte azione
azioni = {}
for cls, f, mazzo, let in (("WC","azioni_wc",118,"w"),("MC","azioni_mc",117,"a"),("CC","azioni_cc",115,"k"),("ST","azioni_st",116,"s")):
    for c in carica(f, "C"):
        cid = f"{cls}{c['i'][0]:02d}"
        leg = [list(x) for x in c.get("leg", [])]
        azioni[cid] = dict(id=cid, cls=cls, it=c["it"], en=c["en"], t=c["t"], req=c.get("req", []), leg=leg, fx=c["fx"],
                           copie=len(c["i"]), img=f"{let}{c['i'][0]:02d}")
eventi = []
for e in carica("eventi", "E"):
    eventi.append(dict(id=f"e{e['i']:02d}", it=e["it"], en=e["en"], t=e["t"], fx=e["fx"], pen=e["pen"], sc=e["sc"], r2=e.get("r2", False)))
export = []
for k, x in enumerate(carica("export", "X")):
    export.append({r: [list(t) for t in x[r]] for r in ("cibo","lus","sal","ist")})
accordi = [dict(cibo=a[0], lus=a[1], costo=a[2], dazio=[a[3], a[4], 0]) for a in carica("accordi", "B")]
agende = [["C","B","A","B","C"],["B","C","A","B","A"],["C","B","B","A","B"],["B","C","B","A","B"],["C","A","A","C","B"],
          ["A","B","C","B","C"],["B","A","C","C","A"],["C","B","B","B","A"],["A","C","B","C","A"],["B","A","C","A","C"]]
immigrazione = [["u","ist"],["sal","u"],["ist","u"],["u","lus"],["lus","u"],["u","ist"],["u","ist"],["ist","u"],["u","lus"],
    ["lus","u"],["u","lus"],["u","med"],["sal","u"],["u","sal"],["u","sal"],["u","sal"],["agr","u"],["u","med"],
    ["u","med"],["u","agr"],["med","u"],["med","u"],["u","agr"],["agr","u"],["u","agr"]]
out = dict(aziende=aziende, azioni=azioni, eventi=eventi, export=export, accordi=accordi, agende=agende, immigrazione=immigrazione)
json.dump(out, open(os.path.join(R, 'dati', 'carte.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(len(aziende), "aziende,", len(azioni), "azioni,", len(eventi), "eventi")

if CROP:
    # illustrazioni delle carte azione (parte alta) e delle aziende
    for cid, a in azioni.items():
        sub = {"w":"wc","a":"mca","k":"cca","s":"sta"}[a["img"][0]]
        im = Image.open(os.path.join(CROP, sub, a["img"] + ".png")).convert("RGB")
        w, h = im.size
        im.crop((0, 0, w, int(h * 0.505))).resize((320, int(320 * h * 0.505 / w)), Image.LANCZOS).save(os.path.join(R, "assets/carte", cid + ".webp"), quality=82)
    for aid, a in aziende.items():
        if aid == "coop":
            src = os.path.join(CROP, "..", "coop.png")
        else:
            sub = {"c":"cap","m":"mc","p":"pub"}[aid[0]]
            src = os.path.join(CROP, sub, aid + ".png")
        im = Image.open(src).convert("RGB"); w, h = im.size
        im.crop((0, int(h*0.125), w, int(h * 0.495))).resize((300, int(300 * h * 0.37 / w)), Image.LANCZOS).save(os.path.join(R, "assets/aziende", aid + ".webp"), quality=82)
