## Dati del gioco: carte, aziende, tabelle delle regole (tutto in italiano).
class_name Dati
extends RefCounted

const CLASSI := ["WC", "MC", "CC", "ST"]
const NOMI_CLASSE := {"WC": "Classe Operaia", "MC": "Classe Media", "CC": "Classe Capitalista", "ST": "Stato"}
const NOMI_BREVI := {"WC": "Operai", "MC": "Ceto medio", "CC": "Capitalisti", "ST": "Stato"}
const COLORI := {"WC": Color("#e3262e"), "MC": Color("#f5bd0a"), "CC": Color("#1384cf"), "ST": Color("#a7a9ac")}
const POLITICHE := ["Politica fiscale", "Mercato del lavoro", "Tassazione", "Welfare: sanità e sussidi",
	"Welfare: istruzione", "Commercio estero", "Immigrazione"]
const POLITICHE_BREVI := ["Fiscale", "Lavoro", "Tasse", "Sanità", "Istruzione", "Commercio", "Immigrazione"]
const COLORI_POL := [Color("#1c8fc9"), Color("#7b73b3"), Color("#a8509c"), Color("#c8161d"), Color("#e5831b"), Color("#a07d55"), Color("#77787b")]
const SEZ := ["A", "B", "C"]
const RISORSE := ["cibo", "lus", "sal", "ist"]
const NOMI_RIS := {"cibo": "Cibo", "lus": "Lusso", "sal": "Salute", "ist": "Istruzione", "inf": "Influenza", "med": "Media"}
const INDUSTRIE := ["agr", "lus", "sal", "ist", "med"]
const NOMI_IND := {"agr": "Agricoltura", "lus": "Lusso", "sal": "Sanità", "ist": "Istruzione", "med": "Media", "u": "non qualificato"}
const COLORI_IND := {"agr": Color("#7a963a"), "lus": Color("#108ace"), "sal": Color("#f5c4b0"), "ist": Color("#f08c00"), "med": Color("#96328c"), "u": Color("#b9bbbe")}
## industria -> risorsa prodotta
const RIS_IND := {"agr": "cibo", "lus": "lus", "sal": "sal", "ist": "ist", "med": "inf"}
const IND_RIS := {"cibo": "agr", "lus": "lus", "sal": "sal", "ist": "ist", "inf": "med"}

# tasse sul reddito: [mercato lavoro A/B/C][tassazione A/B/C]
const TASSA_REDDITO := [[7, 6, 5], [4, 4, 4], [1, 2, 3]]
const SOGLIE_SOCIETA := [5, 10, 25, 50, 100, 200, 300]
const TASSA_SOCIETA := [[1, 2, 2], [5, 5, 4], [12, 10, 7], [24, 15, 10], [40, 30, 20], [100, 70, 40], [160, 120, 60]]
const RICCHEZZA := [10, 25, 50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500]
const PROSP_MC := [0, 1, 2, 3, 4, 5, 5, 6, 6, 7, 7]
const POL_INIZIALI := ["C", "B", "A", "B", "C", "B", "B"]
const POL_FMI := ["C", "C", "A", "B", "C", "B", "B"]
const VP_FINE_WC := [0, 1, 4, 8, 12, 18]
const VP_FINE_MC := [0, 1, 3, 6, 10, 15]
const VP_FINE_CC := [0, 1, 4, 8, 12, 18]

static var _d: Dictionary = {}

static func d() -> Dictionary:
	if _d.is_empty():
		var f := FileAccess.open("res://dati/carte.json", FileAccess.READ)
		_d = JSON.parse_string(f.get_as_text())
	return _d

static func az(id: String) -> Dictionary:
	var a: Dictionary = d()["aziende"]
	if id.begins_with("coop"):
		return a["coop"]
	return a[id]

static func carta(id: String) -> Dictionary:
	return d()["azioni"][id]

static func evento(id: String) -> Dictionary:
	for e in d()["eventi"]:
		if e["id"] == id:
			return e
	return {}

static func popolazione(n: int) -> int:
	if n < 10:
		return 3
	return mini(10, 3 + (n - 9) / 3)

static func indice_sez(s: String) -> int:
	return SEZ.find(s)
