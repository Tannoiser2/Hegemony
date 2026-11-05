## Regole di Hegemony. Tutto lo stato è in un dizionario (s); ogni decisione è la scelta di un'opzione
## fra quelle proposte dall'attesa corrente. Stessa sequenza di decisioni = stessa partita su ogni dispositivo.
class_name Motore
extends RefCounted

const WC := 0
const MC := 1
const CC := 2
const ST := 3

var s: Dictionary = {}

# ================================================================ avvio
func nuova_partita(cfg: Dictionary) -> void:
	var D := Dati.d()
	s = {
		"rng": int(cfg.get("seme", 12345)) & 0x7FFFFFFF, "decisioni": 0, "round": 1, "fase": "azioni", "turno": 0,
		"attivo": 0, "fine": false, "vincitore": -1, "log": [], "eventi": [], "attesa": {}, "pila": [],
		"nomi": cfg.get("nomi", ["Classe Operaia", "Classe Media", "Classe Capitalista", "Stato"]),
		"ia": cfg.get("ia", [true, true, true, true]),
		"pol": Dati.POL_INIZIALI.duplicate(), "prop": [null, null, null, null, null, null, null],
		"borsa": [8, 8, 8], "riserva": [17, 17, 17], "aziende": {}, "priv_cc": [], "priv_mc": [], "pub": [], "pub_giu": [],
		"lav": {}, "next_wid": 1, "servizi": {"sal": 6, "ist": 6, "inf": 4}, "dimostr": false,
		"export": -1, "mazzo_exp": [], "accordi_tav": [], "mazzo_acc": [], "eventi_tav": [], "mazzo_ev": [],
		"mazzo_imm": [], "lm_tasse": "", "voto": {}, "g": [], "storico": [], "ultimo": {},
	}
	for i in 4:
		s["g"].append({"vp": 0, "prestiti": 0, "inf": 1, "mano": [], "mazzo": [], "scarti": [], "soldi": 0, "bill": 3})
	# mazzi
	for cid in D["azioni"]:
		var c: Dictionary = D["azioni"][cid]
		var i: int = Dati.CLASSI.find(c["cls"])
		for k in int(c["copie"]):
			G(i)["mazzo"].append(cid)
	for i in 4:
		_mescola(G(i)["mazzo"])
	s["mazzo_exp"] = range(16)
	_mescola(s["mazzo_exp"])
	s["mazzo_acc"] = range(20)
	_mescola(s["mazzo_acc"])
	s["mazzo_imm"] = range(25)
	_mescola(s["mazzo_imm"])
	for e in D["eventi"]:
		s["mazzo_ev"].append(e["id"])
	_mescola(s["mazzo_ev"])
	# aziende di partenza
	for id in ["c00", "c01", "c02", "c03"]:
		_crea_azienda(id, "CC", 2)
		s["priv_cc"].append(id)
	for id in ["m00", "m01"]:
		_crea_azienda(id, "MC", 2)
		s["priv_mc"].append(id)
	for id in ["p00", "p04", "p08"]:
		_crea_azienda(id, "ST", 2)
		s["pub"].append(id)
	for id in ["p02", "p06", "p10", "p03", "p07", "p11"]:
		_crea_azienda(id, "ST", 2)
		s["pub_giu"].append(id)
	# Classe Operaia
	var gw := G(WC)
	gw["soldi"] = 30
	gw["prosp"] = 0
	gw["beni"] = {"cibo": 0, "lus": 0, "sal": 0, "ist": 0}
	gw["sind"] = {"agr": "", "lus": "", "sal": "", "ist": "", "med": ""}
	gw["coop"] = 0
	_metti(_nuovo_lav(WC, "agr"), "c00", 0)
	_metti(_nuovo_lav(WC, "u"), "c00", 1)
	_metti(_nuovo_lav(WC, "ist"), "c02", 0)
	_metti(_nuovo_lav(WC, "u"), "c02", 1)
	_metti(_nuovo_lav(WC, "sal"), "p00", 0)
	_metti(_nuovo_lav(WC, "u"), "p00", 1)
	_metti(_nuovo_lav(WC, "u"), "p00", 2)
	_nuovo_lav(WC, "u")
	for k in 2:
		_immigrato(WC)
	# Classe Media
	var gm := G(MC)
	gm["soldi"] = 40
	gm["prosp"] = 0
	gm["beni"] = {"cibo": 0, "lus": 0, "sal": 0, "ist": 0}
	gm["mag"] = {"cibo": 1, "lus": 0, "sal": 1, "ist": 0}
	gm["prezzi"] = {"cibo": 12, "lus": 8, "sal": 8, "ist": 8}
	gm["extra"] = {"cibo": false, "lus": false, "sal": false, "ist": false}
	gm["mazzo_az"] = []
	for id in D["aziende"]:
		if id.begins_with("m") and not D["aziende"][id]["start"]:
			gm["mazzo_az"].append(id)
	_mescola(gm["mazzo_az"])
	gm["mercato"] = []
	for k in 3:
		gm["mercato"].append(gm["mazzo_az"].pop_back())
	_metti(_nuovo_lav(MC, "ist"), "p04", 0)
	_metti(_nuovo_lav(MC, "u"), "p04", 1)
	_metti(_nuovo_lav(MC, "u"), "p04", 2)
	_metti(_nuovo_lav(MC, "lus"), "c01", 0)
	_metti(_nuovo_lav(MC, "u"), "c01", 1)
	_metti(_nuovo_lav(MC, "agr"), "m00", 0)
	_metti(_nuovo_lav(MC, "sal"), "m01", 0)
	_nuovo_lav(MC, _abilita_mercato_mc())
	for k in 2:
		_immigrato(MC)
	# Classe Capitalista
	var gc := G(CC)
	gc["rev"] = 120
	gc["cap"] = 0
	gc["ricchezza"] = 0
	gc["mag"] = {"cibo": 1, "lus": 2, "sal": 0, "ist": 2}
	gc["prezzi"] = {"cibo": 12, "lus": 8, "sal": 8, "ist": 8}
	gc["ftz"] = {"cibo": 0, "lus": 0}
	gc["extra"] = {"cibo": false, "lus": false, "sal": false, "ist": false}
	gc["mazzo_az"] = []
	for id in D["aziende"]:
		if id.begins_with("c") and not D["aziende"][id].get("start", false) and id != "coop":
			gc["mazzo_az"].append(id)
	_mescola(gc["mazzo_az"])
	gc["mercato"] = []
	for k in 4:
		gc["mercato"].append(gc["mazzo_az"].pop_back())
	# Stato
	var gs := G(ST)
	gs["soldi"] = 120
	gs["leg"] = [2, 2, 2]
	gs["tok"] = [0, 0, 0]
	gs["ben"] = [_ben_vuoto(), _ben_vuoto(), _ben_vuoto()]
	gs["mag"] = {"cibo": 0, "lus": 0}
	gs["agenda"] = -1
	gs["mazzo_ag"] = range(10)
	_mescola(gs["mazzo_ag"])
	gs["agenda"] = gs["mazzo_ag"].pop_back()
	_nuovi_eventi()
	# mercato estero
	s["accordi_tav"] = [s["mazzo_acc"].pop_back()]
	s["export"] = s["mazzo_exp"].pop_back()
	for i in 4:
		for k in 7:
			_pesca(i)
	_log("Inizia la partita: round 1.")
	_spingi({"k": "round"})
	_avanza()

func carica(stato: Dictionary) -> void:
	s = stato

func _ben_vuoto() -> Dictionary:
	return {"soldi": 0, "cibo": 0, "lus": 0, "sal": 0, "ist": 0, "inf": 0, "cubi": 0}

# ================================================================ casualità (deterministica)
func _rand(n: int) -> int:
	s["rng"] = (int(s["rng"]) * 1103515245 + 12345) & 0x7FFFFFFF
	return (int(s["rng"]) >> 8) % maxi(1, n)

func _mescola(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _rand(i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

# ================================================================ pila dei passi
func _spingi(p: Dictionary) -> void:
	s["pila"].append(p)

func attesa() -> Dictionary:
	return s["attesa"]

func scegli(i: int) -> void:
	var a: Dictionary = s["attesa"]
	if a.is_empty():
		return
	var ops: Array = a["opzioni"]
	i = clampi(i, 0, ops.size() - 1)
	var passo: Dictionary = a["passo"]
	s["attesa"] = {}
	s["decisioni"] = int(s["decisioni"]) + 1
	passo["r"] = ops[i]["v"]
	_spingi(passo)
	_avanza()

func _chiedi(passo: Dictionary, g: int, testo: String, opzioni: Array, tipo := "") -> void:
	if opzioni.is_empty():
		opzioni = [{"t": "Continua", "v": null}]
	s["attesa"] = {"g": g, "testo": testo, "opzioni": opzioni, "passo": passo, "tipo": tipo}

func _avanza() -> void:
	var guard := 0
	while s["attesa"].is_empty() and not s["pila"].is_empty() and not s["fine"]:
		guard += 1
		if guard > 50000:
			push_error("ciclo infinito nel motore")
			return
		var p: Dictionary = s["pila"].pop_back()
		call("_p_" + str(p["k"]), p)

func _r(p: Dictionary):
	if p.has("r"):
		var v = p["r"]
		p.erase("r")
		return v
	return null

func _ha_r(p: Dictionary) -> bool:
	return p.has("r")

# ================================================================ utilità
func G(i: int) -> Dictionary:
	return s["g"][i]

func _log(t: String) -> void:
	s["log"].append(t)
	if s["log"].size() > 400:
		s["log"].pop_front()

func _ev(e: Dictionary) -> void:
	s["eventi"].append(e)
	if s["eventi"].size() > 200:
		s["eventi"].pop_front()

func nome(i: int) -> String:
	return Dati.NOMI_CLASSE[Dati.CLASSI[i]]

func pol(k: int) -> String:
	return s["pol"][k]

func polx(k: int) -> int:
	return Dati.SEZ.find(s["pol"][k])

func req_ok(cid: String) -> bool:
	var c := Dati.carta(cid)
	var req: Array = c["req"]
	if req.is_empty():
		return true
	for r in req:
		var k := int(str(r)[0]) - 1
		if pol(k) == str(r)[1]:
			return true
	return false

func moltiplicatore() -> int:
	var base: int = [3, 2, 1][polx(2)]
	var fatt: int = [2, 1, 0][polx(2)]
	var m: int = base
	m += fatt * [2, 1, 0][polx(3)]
	m += fatt * [2, 1, 0][polx(4)]
	return m

func prezzo_pubblico(r: String) -> int:
	if r == "inf":
		return 10
	var k := 3 if r == "sal" else 4
	return [0, 5, 10][polx(k)]

func dazio(r: String) -> int:
	var x := polx(5)
	if r == "cibo":
		return [10, 5, 0][x]
	if r == "lus":
		return [6, 3, 0][x]
	return 0

func prezzo_estero(r: String) -> int:
	return 10 if r == "cibo" else 6

func vp(i: int, n: int, motivo := "") -> void:
	if n == 0:
		return
	G(i)["vp"] = int(G(i)["vp"]) + n
	if motivo != "":
		_log("%s: %+d PV (%s)" % [nome(i), n, motivo])
	_ev({"tipo": "vp", "g": i, "n": n})

# ---------------------------------------------------------------- denaro
func soldi(i: int) -> int:
	if i == CC:
		return int(G(CC)["rev"]) + int(G(CC)["cap"])
	return int(G(i)["soldi"])

func dai_soldi(i: int, n: int) -> void:
	if n <= 0:
		return
	if i == CC:
		G(CC)["rev"] = int(G(CC)["rev"]) + n
	else:
		G(i)["soldi"] = int(G(i)["soldi"]) + n

## Pagamento obbligatorio: se non bastano i soldi si prendono Prestiti (50 ciascuno).
func paga(i: int, n: int, dal_capitale := false) -> void:
	if n <= 0:
		return
	while soldi(i) < n:
		_prestito(i)
	if i == CC:
		var g := G(CC)
		if dal_capitale:
			var a := mini(n, int(g["cap"]))
			g["cap"] = int(g["cap"]) - a
			g["rev"] = int(g["rev"]) - (n - a)
		else:
			var a := mini(n, int(g["rev"]))
			g["rev"] = int(g["rev"]) - a
			g["cap"] = int(g["cap"]) - (n - a)
	else:
		G(i)["soldi"] = int(G(i)["soldi"]) - n

## Trasferimento obbligatorio da i a j.
func trasferisci(i: int, j: int, n: int) -> void:
	if n <= 0:
		return
	paga(i, n)
	dai_soldi(j, n)

func puo_pagare(i: int, n: int) -> bool:
	return soldi(i) >= n

func _prestito(i: int) -> void:
	G(i)["prestiti"] = int(G(i)["prestiti"]) + 1
	if i == CC:
		G(CC)["cap"] = int(G(CC)["cap"]) + 50
	else:
		G(i)["soldi"] = int(G(i)["soldi"]) + 50
	_log("%s deve prendere un Prestito (+50)." % nome(i))
	_ev({"tipo": "prestito", "g": i})

# ---------------------------------------------------------------- carte
func _pesca(i: int) -> void:
	var g := G(i)
	if g["mazzo"].is_empty():
		g["mazzo"] = g["scarti"]
		g["scarti"] = []
		_mescola(g["mazzo"])
	if not g["mazzo"].is_empty():
		g["mano"].append(g["mazzo"].pop_back())

func _nuovi_eventi() -> void:
	var gs := G(ST)
	var tent := 0
	while s["eventi_tav"].size() < 2 and not s["mazzo_ev"].is_empty() and tent < 40:
		tent += 1
		var e: String = s["mazzo_ev"].pop_back()
		if int(s["round"]) == 1 and Dati.evento(e)["r2"]:
			s["mazzo_ev"].insert(0, e)
			continue
		s["eventi_tav"].append(e)

# ================================================================ lavoratori
func _nuovo_lav(c: int, sk: String) -> String:
	var id := "w%d" % int(s["next_wid"])
	s["next_wid"] = int(s["next_wid"]) + 1
	s["lav"][id] = {"id": id, "c": c, "sk": sk, "loc": "", "sl": -1, "imp": false}
	return id

func _immigrato(c: int) -> void:
	var k: int = s["mazzo_imm"].pop_front()
	s["mazzo_imm"].append(k)
	var sk: String = Dati.d()["immigrazione"][k][c]
	_nuovo_lav(c, sk)
	_log("%s: arriva un lavoratore %s." % [nome(c), Dati.NOMI_IND[sk]])

func lav(id: String) -> Dictionary:
	return s["lav"][id]

func lavoratori(c: int) -> Array:
	var out := []
	for id in s["lav"]:
		if int(s["lav"][id]["c"]) == c:
			out.append(id)
	return out

func disoccupati(c: int) -> Array:
	var out := []
	for id in s["lav"]:
		var w: Dictionary = s["lav"][id]
		if int(w["c"]) == c and w["loc"] == "":
			out.append(id)
	return out

func occupati(c: int) -> Array:
	var out := []
	for id in s["lav"]:
		var w: Dictionary = s["lav"][id]
		if int(w["c"]) == c and w["loc"] != "":
			out.append(id)
	return out

func popolazione(c: int) -> int:
	return Dati.popolazione(lavoratori(c).size())

## Mette il lavoratore nello slot (sl = -2: slot del dipendente nelle aziende della Classe Media).
func _metti(wid: String, aid: String, sl: int, impegna := false) -> void:
	_togli(wid)
	var w := lav(wid)
	var a: Dictionary = s["aziende"][aid]
	if sl == -2:
		a["dip"] = wid
	else:
		a["lav"][sl] = wid
	w["loc"] = aid
	w["sl"] = sl
	w["imp"] = impegna

func _togli(wid: String) -> void:
	var w := lav(wid)
	var loc: String = w["loc"]
	if loc == "":
		return
	if loc.begins_with("sind:"):
		G(WC)["sind"][loc.substr(5)] = ""
	elif s["aziende"].has(loc):
		var a: Dictionary = s["aziende"][loc]
		if int(w["sl"]) == -2:
			a["dip"] = ""
		else:
			a["lav"][int(w["sl"])] = ""
	w["loc"] = ""
	w["sl"] = -1

## Licenzia tutti i lavoratori di un'azienda (vanno fra i disoccupati).
func _svuota(aid: String) -> void:
	var a: Dictionary = s["aziende"][aid]
	for wid in a["lav"]:
		if wid != "":
			_togli(wid)
			lav(wid)["imp"] = false
	if a.get("dip", "") != "":
		var d: String = a["dip"]
		_togli(d)
		lav(d)["imp"] = false
	a["sc"] = false

## Dopo uno spostamento: le aziende rimaste incomplete perdono i lavoratori; sindacati senza 4 lavoratori si sciolgono.
func _controlla_aziende() -> void:
	for aid in s["aziende"]:
		var a: Dictionary = s["aziende"][aid]
		var d := Dati.az(aid)
		if d["auto"]:
			continue
		var pieni := 0
		for wid in a["lav"]:
			if wid != "":
				pieni += 1
		if pieni > 0 and pieni < a["lav"].size():
			for wid in a["lav"]:
				if wid != "":
					_togli(wid)
					lav(wid)["imp"] = false
		# dipendente senza titolare della Classe Media
		if d["tipo"] == "MC" and pieni < a["lav"].size() and a.get("dip", "") != "":
			var dd: String = a["dip"]
			_togli(dd)
			lav(dd)["imp"] = false
		if not operativa(aid):
			a["sc"] = false
		elif d["tipo"] == "MC" and a.get("dip", "") == "":
			a["sc"] = false
	for ind in Dati.INDUSTRIE:
		var wid: String = G(WC)["sind"][ind]
		if wid != "" and lavoratori_industria(ind) < 4:
			_togli(wid)
			lav(wid)["imp"] = false
			_log("Il sindacato %s si scioglie." % Dati.NOMI_IND[ind])

## Lavoratori della Classe Operaia impiegati in aziende di un'industria (sindacati esclusi).
func lavoratori_industria(ind: String) -> int:
	var n := 0
	for id in s["lav"]:
		var w: Dictionary = s["lav"][id]
		if int(w["c"]) != WC:
			continue
		var loc: String = w["loc"]
		if loc != "" and s["aziende"].has(loc) and Dati.az(loc)["ind"] == ind:
			n += 1
	return n

func sindacati() -> int:
	var n := 0
	for ind in Dati.INDUSTRIE:
		if G(WC)["sind"][ind] != "":
			n += 1
	return n

# ================================================================ aziende
func _crea_azienda(id: String, own: String, salario: int) -> void:
	var d := Dati.az(id)
	var sl := []
	for x in d["slot"]:
		sl.append("")
	s["aziende"][id] = {"id": id, "own": own, "sal": salario, "lav": sl, "dip": "", "mac": false, "sc": false}

func az(id: String) -> Dictionary:
	return s["aziende"][id]

func proprietario(aid: String) -> int:
	return Dati.CLASSI.find(s["aziende"][aid]["own"])

func aziende_di(i: int) -> Array:
	match i:
		CC:
			return s["priv_cc"]
		MC:
			return s["priv_mc"]
		ST:
			return s["pub"]
		WC:
			var o := []
			for k in int(G(WC)["coop"]):
				o.append("coop%d" % (k + 1))
			return o
	return []

func operativa(aid: String) -> bool:
	var d := Dati.az(aid)
	if d["auto"]:
		return true
	for wid in s["aziende"][aid]["lav"]:
		if wid == "":
			return false
	return true

## Pienamente operativa (Classe Media: anche il dipendente, se previsto).
func piena(aid: String) -> bool:
	if not operativa(aid):
		return false
	var d := Dati.az(aid)
	if d["tipo"] == "MC" and d["dip"] != "":
		return s["aziende"][aid]["dip"] != ""
	return true

func operative(i: int) -> int:
	var n := 0
	for aid in aziende_di(i):
		if operativa(aid):
			n += 1
	return n

func lavoratori_in(aid: String) -> Array:
	var o := []
	for wid in s["aziende"][aid]["lav"]:
		if wid != "":
			o.append(wid)
	if s["aziende"][aid].get("dip", "") != "":
		o.append(s["aziende"][aid]["dip"])
	return o

func classe_lavoratori(aid: String) -> int:
	for wid in s["aziende"][aid]["lav"]:
		if wid != "":
			return int(lav(wid)["c"])
	return -1

func impegnata(aid: String) -> bool:
	for wid in lavoratori_in(aid):
		if lav(wid)["imp"]:
			return true
	return false

func salario_minimo() -> int:
	return [3, 2, 1][polx(1)]

func salario(aid: String) -> int:
	var d := Dati.az(aid)
	return int(d["sal"][int(s["aziende"][aid]["sal"]) - 1])

func produzione(aid: String) -> int:
	var d := Dati.az(aid)
	var n: int = d["prod"]
	if s["aziende"][aid].get("mac", false):
		n += int(d["mac"])
	return n

## Limite di stoccaggio.
func capienza(i: int, r: String) -> int:
	if i == CC:
		if r == "inf":
			return 999
		var base := 8 if r == "cibo" else 12
		return base * (2 if G(CC)["extra"][r] else 1)
	if i == MC:
		if r == "inf":
			return 999
		var b2 := 8
		if G(MC)["extra"][r]:
			b2 += 8 if r == "cibo" else 12
		return b2
	if i == ST:
		return capienza_pubblica(r)
	return 999

func capienza_pubblica(r: String) -> int:
	if r in ["cibo", "lus"]:
		var n := 6
		for aid in s["pub"]:
			if Dati.RIS_IND[Dati.az(aid)["ind"]] == r:
				n += Dati.az(aid)["prod"]
		return n
	var ind: String = Dati.IND_RIS[r]
	var t := 6
	for aid in s["pub"]:
		if Dati.az(aid)["ind"] == ind:
			t += produzione(aid)
	return t

## Aggiunge risorse al magazzino del giocatore (l'eccesso si perde o va nella zona franca).
func immagazzina(i: int, r: String, n: int, ftz_ok := true) -> int:
	if n <= 0:
		return 0
	if r == "inf":
		if i == ST:
			var lim := capienza_pubblica("inf")
			var prima: int = s["servizi"]["inf"]
			s["servizi"]["inf"] = mini(lim, prima + n)
			return int(s["servizi"]["inf"]) - prima
		G(i)["inf"] = int(G(i)["inf"]) + n
		return n
	if i == ST:
		if r in ["sal", "ist"]:
			var lim2 := capienza_pubblica(r)
			var p2: int = s["servizi"][r]
			s["servizi"][r] = mini(lim2, p2 + n)
			return int(s["servizi"][r]) - p2
		var lim3 := capienza_pubblica(r)
		var p3: int = G(ST)["mag"][r]
		G(ST)["mag"][r] = mini(lim3, p3 + n)
		return int(G(ST)["mag"][r]) - p3
	if i == WC:
		G(WC)["beni"][r] = int(G(WC)["beni"][r]) + n
		return n
	var g := G(i)
	var cap := capienza(i, r)
	var dentro := mini(n, cap - int(g["mag"][r]))
	dentro = maxi(0, dentro)
	g["mag"][r] = int(g["mag"][r]) + dentro
	var resto := n - dentro
	if i == CC and resto > 0 and r in ["cibo", "lus"] and ftz_ok:
		var lf := 8 if r == "cibo" else 12
		var f := mini(resto, lf - int(g["ftz"][r]))
		g["ftz"][r] = int(g["ftz"][r]) + f
		dentro += f
	return dentro

## Quanto un giocatore ha in vendita di una risorsa (per gli altri giocatori).
func disponibile(i: int, r: String) -> int:
	match i:
		MC, CC:
			if r == "inf":
				return 0
			return int(G(i)["mag"][r])
		ST:
			if r in ["sal", "ist", "inf"]:
				return int(s["servizi"][r])
			return int(G(ST)["mag"][r])
	return 0

func prezzo(i: int, r: String) -> int:
	match i:
		MC, CC:
			return int(G(i)["prezzi"][r])
		ST:
			if r == "cibo":
				return 12
			if r == "lus":
				return 8
			return prezzo_pubblico(r)
	return 0

func _togli_ris(i: int, r: String, n: int) -> void:
	if i == ST:
		if r in ["sal", "ist", "inf"]:
			s["servizi"][r] = int(s["servizi"][r]) - n
		else:
			G(ST)["mag"][r] = int(G(ST)["mag"][r]) - n
	else:
		G(i)["mag"][r] = int(G(i)["mag"][r]) - n

# ---------------------------------------------------------------- legittimità
func legit(c: int, n: int) -> void:
	if n == 0:
		return
	var l: Array = G(ST)["leg"]
	l[c] = clampi(int(l[c]) + n, 1, 10)
	_ev({"tipo": "leg", "c": c, "n": n})

func gettone(c: int) -> void:
	G(ST)["tok"][c] = int(G(ST)["tok"][c]) + 1
	legit(c, 1)
	_log("Lo Stato ottiene un gettone Legittimità (%s)." % nome(c))

func min_leg() -> int:
	var l: Array = G(ST)["leg"]
	return mini(int(l[0]), mini(int(l[1]), int(l[2])))

# ---------------------------------------------------------------- prosperità
func prosperita(i: int, n := 1) -> void:
	for k in n:
		var g := G(i)
		g["prosp"] = mini(10, int(g["prosp"]) + 1)
		var v: int = g["prosp"] if i == WC else Dati.PROSP_MC[int(g["prosp"])]
		vp(i, v, "Prosperità %d" % int(g["prosp"]))

## Benefici del valore di un'azione a metà prezzo/gratuita dallo Stato.
func _benefici_pubblici(compratore: int, r: String, n: int, prezzo_base: int) -> void:
	if n <= 0 or not r in ["sal", "ist"]:
		return
	if prezzo_base == 5:
		vp(ST, 1, "servizio pubblico a prezzo ridotto")
	elif prezzo_base == 0 and compratore in [WC, MC]:
		legit(compratore, n / 3)

# ================================================================ struttura del round
func _p_round(_p: Dictionary) -> void:
	_ev({"tipo": "round", "n": s["round"]})
	_spingi({"k": "fine_round"})
	_spingi({"k": "punteggio"})
	_spingi({"k": "elezioni"})
	_spingi({"k": "produzione"})
	_spingi({"k": "azioni", "t": 0, "i": 0})
	if int(s["round"]) > 1:
		_spingi({"k": "prep_lavoratori"})
		_spingi({"k": "prep_mercato", "c": MC})
		_spingi({"k": "prep_mercato", "c": CC})
		_spingi({"k": "prep"})

func _p_prep(_p: Dictionary) -> void:
	s["fase"] = "preparazione"
	_log("--- Round %d: preparazione ---" % int(s["round"]))
	for i in 4:
		var n: int = G(i)["prestiti"]
		if n > 0:
			if i == CC:
				paga(CC, 5 * n, true)
			else:
				paga(i, 5 * n)
			_log("%s paga %d di interessi." % [nome(i), 5 * n])
	G(WC)["prosp"] = maxi(0, int(G(WC)["prosp"]) - 1)
	G(MC)["prosp"] = maxi(0, int(G(MC)["prosp"]) - 2)
	# eventi e agenda politica
	s["eventi_tav"] = []
	_nuovi_eventi()
	var gs := G(ST)
	if gs["mazzo_ag"].is_empty():
		gs["mazzo_ag"] = range(10)
		_mescola(gs["mazzo_ag"])
	gs["agenda"] = gs["mazzo_ag"].pop_back()
	for i in 4:
		while G(i)["mano"].size() < 7:
			var prima: int = G(i)["mano"].size()
			_pesca(i)
			if G(i)["mano"].size() == prima:
				break
	# accordi commerciali ed export
	s["accordi_tav"] = []
	var na := polx(5)
	for k in na:
		if s["mazzo_acc"].is_empty():
			s["mazzo_acc"] = range(20)
			_mescola(s["mazzo_acc"])
		s["accordi_tav"].append(s["mazzo_acc"].pop_back())
	_nuovo_export()
	for i in 4:
		G(i)["bill"] = 3

func _nuovo_export() -> void:
	if s["mazzo_exp"].is_empty():
		s["mazzo_exp"] = range(16)
		s["mazzo_exp"].erase(s["export"])
		_mescola(s["mazzo_exp"])
	s["export"] = s["mazzo_exp"].pop_back()

func _p_prep_mercato(p: Dictionary) -> void:
	var c: int = p["c"]
	var g := G(c)
	var max_m := 4 if c == CC else 3
	if not _ha_r(p):
		if g["mercato"].size() >= max_m and not g["mazzo_az"].is_empty():
			var ops := [{"t": "Tieni il Mercato", "v": "tieni"}, {"t": "Scarta il Mercato e pesca nuove Aziende", "v": "nuovo"}]
			_chiedi(p, c, "Mercato delle Aziende: tenerlo o rinnovarlo?", ops, "mercato")
			return
	var r = _r(p)
	if r is String and r == "nuovo":
		g["mercato"] = []
	while g["mercato"].size() < max_m and not g["mazzo_az"].is_empty():
		g["mercato"].append(g["mazzo_az"].pop_back())

func _p_prep_lavoratori(p: Dictionary) -> void:
	if not _ha_r(p):
		_nuovo_lav(WC, "u")
		_nuovo_lav(WC, "u")
		var n := polx(6)
		for k in n:
			_immigrato(WC)
		var ops := []
		for ind in Dati.INDUSTRIE:
			ops.append({"t": "Lavoratore qualificato: " + Dati.NOMI_IND[ind], "v": ind})
		_chiedi(p, MC, "Classe Media: scegli il nuovo lavoratore qualificato.", ops, "abilita")
		return
	var sk: String = str(_r(p))
	_nuovo_lav(MC, "u")
	_nuovo_lav(MC, sk)
	for k in polx(6):
		_immigrato(MC)

## Abilità utile per la Classe Media (setup): quella richiesta più spesso dal suo mercato.
func _abilita_mercato_mc() -> String:
	var cont := {}
	for aid in G(MC)["mercato"]:
		var ind: String = Dati.az(aid)["ind"]
		cont[ind] = int(cont.get(ind, 0)) + 1
	var best := "agr"
	var bv := -1
	for k in cont:
		if int(cont[k]) > bv:
			bv = cont[k]
			best = k
	return best

# ---------------------------------------------------------------- fase azioni
func _p_azioni(p: Dictionary) -> void:
	var t: int = p["t"]
	var i: int = p["i"]
	if t >= 5:
		return
	s["fase"] = "azioni"
	s["turno"] = t
	s["attivo"] = i
	s.erase("ben_turno")
	var ni := i + 1
	var nt := t
	if ni >= 4:
		ni = 0
		nt += 1
	_spingi({"k": "azioni", "t": nt, "i": ni})
	if G(i)["mano"].is_empty():
		return
	_spingi({"k": "turno", "c": i, "lib": false})

func _p_turno(p: Dictionary) -> void:
	var c: int = p["c"]
	var g := G(c)
	if not _ha_r(p):
		var ops := []
		var visti := []
		for cid in g["mano"]:
			if cid in visti:
				continue
			visti.append(cid)
			if req_ok(cid) and fx_possibile(c, cid):
				ops.append({"t": "Gioca: " + Dati.carta(cid)["it"], "v": ["eff", cid]})
		ops.append({"t": "Scarta una carta per un'Azione base", "v": ["base"]})
		if not p["lib"] and not p.get("vista", false) and not opzioni_libere(c).is_empty():
			ops.append({"t": "Prima un'Azione gratuita", "v": ["lib"]})
		_chiedi(p, c, "Turno %d di 5: scegli l'azione principale." % (int(s["turno"]) + 1), ops, "turno")
		return
	var r: Array = _r(p)
	match str(r[0]):
		"eff":
			var cid: String = r[1]
			g["mano"].erase(cid)
			g["scarti"].append(cid)
			_log("%s gioca «%s»." % [nome(c), Dati.carta(cid)["it"]])
			_ev({"tipo": "carta", "g": c, "c": cid})
			s["ultimo"] = {"g": c, "c": cid}
			_spingi({"k": "turno_fine", "c": c, "lib": p["lib"]})
			_spingi({"k": "legit_carta", "c": c, "cid": cid})
			_spingi({"k": "fx", "c": c, "cid": cid})
		"base":
			_spingi({"k": "turno_fine", "c": c, "lib": p["lib"]})
			_spingi({"k": "base", "c": c})
		"lib":
			_spingi({"k": "turno", "c": c, "lib": false, "vista": true})
			_spingi({"k": "libera", "c": c, "pre": true})

func _p_base(p: Dictionary) -> void:
	var c: int = p["c"]
	var g := G(c)
	if not p.has("carta"):
		if not _ha_r(p):
			var ops := []
			var visti := []
			for cid in g["mano"]:
				if cid in visti:
					continue
				visti.append(cid)
				ops.append({"t": "Scarta: " + Dati.carta(cid)["it"], "v": cid})
			_chiedi(p, c, "Quale carta scarti per l'Azione base?", ops, "scarta")
			return
		p["carta"] = _r(p)
		g["mano"].erase(p["carta"])
		g["scarti"].append(p["carta"])
	if not _ha_r(p):
		_chiedi(p, c, "Scegli l'Azione base.", opzioni_base(c), "base")
		return
	var a: String = str(_r(p))
	_log("%s: %s." % [nome(c), NOMI_AZIONI.get(a, a)])
	s["ultimo"] = {"g": c, "a": a}
	_ev({"tipo": "azione", "g": c, "a": a})
	_spingi({"k": "a_" + a, "c": c})

func _p_turno_fine(p: Dictionary) -> void:
	var c: int = p["c"]
	if p["lib"]:
		return
	var libere := opzioni_libere(c)
	if libere.is_empty():
		return
	if not _ha_r(p):
		var ops := [{"t": "Fine turno", "v": ""}]
		ops.append_array(libere)
		_chiedi(p, c, "Vuoi fare un'Azione gratuita?", ops, "libera")
		return
	var a: String = str(_r(p))
	if a == "":
		return
	_spingi({"k": "l_" + a, "c": c})

func _p_libera(p: Dictionary) -> void:
	var c: int = p["c"]
	if not _ha_r(p):
		var ops := [{"t": "Nessuna (torna indietro)", "v": ""}]
		ops.append_array(opzioni_libere(c))
		_chiedi(p, c, "Quale Azione gratuita?", ops, "libera")
		return
	var a: String = str(_r(p))
	if a == "":
		return
	# l'azione gratuita è stata usata: il turno non la riproporrà
	for q in s["pila"]:
		if q["k"] == "turno" and int(q["c"]) == c:
			q["lib"] = true
	_spingi({"k": "l_" + a, "c": c})

const NOMI_AZIONI := {
	"proponi": "Proporre una Legge", "assegna": "Assegnare Lavoratori", "compra": "Acquistare Beni & Servizi",
	"sciopero": "Sciopero", "manifestazione": "Manifestazione", "pressione": "Esercitare Pressione Politica",
	"costruisci": "Costruire un'Azienda", "vendi_az": "Vendere un'Azienda", "estero": "Vendere al Mercato Estero",
	"turno_extra": "Turno Extra", "accordo": "Fare un Accordo Commerciale", "lobby": "Lobby",
	"evento": "Azione Evento", "incontro": "Incontrare i parlamentari di un partito", "tassa_extra": "Tassa straordinaria",
	"campagna": "Campagna mediatica",
}
const NOMI_LIBERE := {
	"sanita": "Usare l'Assistenza Sanitaria", "istruzione": "Usare l'Istruzione", "lusso": "Usare il Lusso",
	"scambia": "Scambiare Lavoratori", "benefici": "Ricevere i Benefici", "prestito": "Estinguere un Prestito",
	"prezzi": "Adeguare i Prezzi", "salari": "Adeguare i Salari", "bonus": "Dare un Premio",
	"magazzino": "Acquistare un Magazzino",
}

func opzioni_base(c: int) -> Array:
	var o := []
	var add := func(k: String): o.append({"t": NOMI_AZIONI[k], "v": k})
	if puo_proporre(c, false):
		add.call("proponi")
	match c:
		WC:
			if not bersagli_assegna(WC, 3, false).is_empty():
				add.call("assegna")
			if pop_compra_possibile(WC):
				add.call("compra")
			if not bersagli_sciopero().is_empty():
				add.call("sciopero")
			if manifestazione_possibile():
				add.call("manifestazione")
		MC:
			if not bersagli_assegna(MC, 3, false).is_empty():
				add.call("assegna")
			if not costruibili(MC, 0).is_empty():
				add.call("costruisci")
			if not vendibili(MC).is_empty():
				add.call("vendi_az")
			if not transazioni_export(MC, {}).is_empty():
				add.call("estero")
			if pop_compra_possibile(MC):
				add.call("compra")
			if not bersagli_turno_extra(MC).is_empty():
				add.call("turno_extra")
		CC:
			if not costruibili(CC, 0).is_empty():
				add.call("costruisci")
			if not vendibili(CC).is_empty():
				add.call("vendi_az")
			if not transazioni_export(CC, {}).is_empty():
				add.call("estero")
			if not s["accordi_tav"].is_empty():
				add.call("accordo")
			if puo_pagare(CC, 30):
				add.call("lobby")
		ST:
			if not s["eventi_tav"].is_empty() and not eventi_eseguibili().is_empty():
				add.call("evento")
			if not transazioni_export(ST, {}).is_empty():
				add.call("estero")
			if int(G(ST)["inf"]) >= 2:
				add.call("incontro")
			if int(G(ST)["leg"][0]) + int(G(ST)["leg"][1]) + int(G(ST)["leg"][2]) > 3:
				add.call("tassa_extra")
			if int(s["servizi"]["inf"]) > 0:
				add.call("campagna")
	if c != ST and int(s["riserva"][c]) > 0:
		add.call("pressione")
	if o.is_empty():
		add.call("pressione")
	return o

func opzioni_libere(c: int) -> Array:
	var o := []
	var add := func(k: String): o.append({"t": NOMI_LIBERE[k], "v": k})
	var g := G(c)
	if c in [WC, MC]:
		var pp := popolazione(c)
		if int(g["beni"]["sal"]) >= pp:
			add.call("sanita")
		if int(g["beni"]["ist"]) >= pp:
			add.call("istruzione")
		if int(g["beni"]["lus"]) >= pp:
			add.call("lusso")
		if not coppie_scambio(c).is_empty():
			add.call("scambia")
	if c in [MC, CC]:
		add.call("prezzi")
	if c in [MC, CC, ST] and not aziende_salario(c).is_empty():
		add.call("salari")
	if c == CC:
		var ok := false
		for aid in s["priv_cc"]:
			if operativa(aid) and not Dati.az(aid)["auto"]:
				ok = true
		if ok:
			add.call("bonus")
		if puo_pagare(CC, 20):
			for r in Dati.RISORSE:
				if not G(CC)["extra"][r] and produce(CC, r):
					add.call("magazzino")
					break
	if c != ST:
		var b: Dictionary = G(ST)["ben"][c]
		for k in b:
			if int(b[k]) > 0:
				add.call("benefici")
				break
	if int(g["prestiti"]) > 0 and puo_pagare(c, 50):
		add.call("prestito")
	return o

func produce(i: int, r: String) -> bool:
	for aid in aziende_di(i):
		if Dati.RIS_IND[Dati.az(aid)["ind"]] == r:
			return true
	return false

# ================================================================ azioni base comuni
## Proposta di legge. Opzioni del passo: pol (fissa), radicale, voto_gratis, no_immediato, cubi (5 cubi già rivelati).
func puo_proporre(c: int, radicale: bool, solo_pol := -1) -> bool:
	if int(G(c)["bill"]) <= 0:
		return false
	for k in 7:
		if solo_pol >= 0 and k != solo_pol:
			continue
		if s["prop"][k] == null and not sezioni_proponibili(k, radicale).is_empty():
			return true
	return false

func sezioni_proponibili(k: int, radicale: bool) -> Array:
	var x := polx(k)
	var o := []
	for j in 3:
		if j == x:
			continue
		if radicale or absi(j - x) == 1:
			o.append(Dati.SEZ[j])
	return o

func _p_a_proponi(p: Dictionary) -> void:
	var c: int = p["c"]
	var radicale: bool = p.get("radicale", false)
	if not p.has("pol"):
		if not _ha_r(p):
			var ops := []
			for k in 7:
				if s["prop"][k] == null and not sezioni_proponibili(k, radicale).is_empty():
					ops.append({"t": "%d. %s (ora %s)" % [k + 1, Dati.POLITICHE[k], pol(k)], "v": k})
			if ops.is_empty() or int(G(c)["bill"]) <= 0:
				_log("%s non può proporre leggi." % nome(c))
				return
			_chiedi(p, c, "Su quale Politica proponi una Legge?", ops, "proponi_pol")
			return
		p["pol"] = int(_r(p))
	var k: int = p["pol"]
	if s["prop"][k] != null or int(G(c)["bill"]) <= 0:
		_log("%s non può proporre una legge su %s." % [nome(c), Dati.POLITICHE[k]])
		return
	if not p.has("sez"):
		var sz := sezioni_proponibili(k, radicale)
		if sz.is_empty():
			return
		if sz.size() == 1:
			p["sez"] = sz[0]
		else:
			if not _ha_r(p):
				var ops2 := []
				for x in sz:
					ops2.append({"t": "Sezione %d%s" % [k + 1, x], "v": x})
				_chiedi(p, c, "%s: in quale sezione?" % Dati.POLITICHE[k], ops2, "proponi_sez")
				return
			p["sez"] = str(_r(p))
	var gratis: bool = p.get("voto_gratis", false)
	var puo_imm: bool = not p.get("no_immediato", false) and (gratis or int(G(c)["inf"]) >= 1)
	if puo_imm and not p.has("imm"):
		if not _ha_r(p):
			var costo := "senza spendere Influenza" if gratis else "spendendo 1 Influenza"
			var ops3 := [{"t": "No, si vota nella Fase Elezioni", "v": false}, {"t": "Votazione Immediata (%s)" % costo, "v": true}]
			_chiedi(p, c, "Legge %d%s: chiedi una Votazione Immediata?" % [k + 1, p["sez"]], ops3, "immediata")
			return
		p["imm"] = bool(_r(p))
	G(c)["bill"] = int(G(c)["bill"]) - 1
	s["prop"][k] = {"c": c, "sez": p["sez"]}
	_log("%s propone la Legge %d%s (%s)." % [nome(c), k + 1, p["sez"], Dati.POLITICHE[k]])
	_ev({"tipo": "legge", "g": c, "pol": k, "sez": p["sez"]})
	if p.get("imm", false):
		if not gratis:
			G(c)["inf"] = int(G(c)["inf"]) - 1
		_spingi({"k": "voto", "pol": k, "fase": "dich", "idx": 0, "imm": true, "cubi": p.get("cubi", [])})
	elif not p.get("cubi", []).is_empty():
		for x in p["cubi"]:
			s["borsa"][int(x)] = int(s["borsa"][int(x)]) + 1

func _p_a_pressione(p: Dictionary) -> void:
	aggiungi_cubi(p["c"], 3)

func aggiungi_cubi(c: int, n: int) -> int:
	if c >= 3:
		return 0
	var k := mini(n, int(s["riserva"][c]))
	s["riserva"][c] = int(s["riserva"][c]) - k
	s["borsa"][c] = int(s["borsa"][c]) + k
	if k > 0:
		_log("%s aggiunge %d cubi Voto al sacchetto." % [nome(c), k])
		_ev({"tipo": "cubi", "g": c, "n": k})
	return k

## Pesca cubi a caso dal sacchetto (li toglie). Se il sacchetto è vuoto lo riempie due volte.
func pesca_cubi(n: int) -> Array:
	var o := []
	for k in n:
		var tot := int(s["borsa"][0]) + int(s["borsa"][1]) + int(s["borsa"][2])
		if tot == 0:
			_riempi_sacchetto(false)
			_riempi_sacchetto(false)
			tot = int(s["borsa"][0]) + int(s["borsa"][1]) + int(s["borsa"][2])
			if tot == 0:
				break
		var x := _rand(tot)
		for c in 3:
			if x < int(s["borsa"][c]):
				o.append(c)
				s["borsa"][c] = int(s["borsa"][c]) - 1
				break
			x -= int(s["borsa"][c])
	return o

func _riempi_sacchetto(con_stato: bool) -> void:
	aggiungi_cubi(WC, (popolazione(WC) + 1) / 2)
	aggiungi_cubi(CC, (operative(CC) + 1) / 2)
	aggiungi_cubi(MC, maxi((popolazione(MC) + 1) / 2, (operative(MC) + 1) / 2))
	if con_stato:
		var l := min_leg()
		var inf: int = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5][l]
		G(ST)["inf"] = int(G(ST)["inf"]) + inf
		if inf > 0:
			_log("Lo Stato ottiene %d Influenza dalla Legittimità." % inf)

# ---------------------------------------------------------------- assegnare lavoratori
## Sceglie i lavoratori della classe c per gli slot richiesti. Restituisce [] se non si può.
func scegli_lavoratori(c: int, req: Array, solo_dis: bool, escludi_az := "", esclusi := []) -> Array:
	var liberi := []
	for wid in s["lav"]:
		var w: Dictionary = s["lav"][wid]
		if int(w["c"]) != c or w["imp"] or wid in esclusi:
			continue
		var loc: String = w["loc"]
		if loc == escludi_az and loc != "":
			continue
		if loc != "" and (solo_dis or loc.begins_with("sind:")):
			continue
		if loc != "" and s["aziende"].has(loc) and impegnata(loc):
			continue
		liberi.append(wid)
	# disoccupati prima
	liberi.sort_custom(func(a, b):
		var la: int = 0 if lav(a)["loc"] == "" else 1
		var lb: int = 0 if lav(b)["loc"] == "" else 1
		if la != lb:
			return la < lb
		return str(a) < str(b))
	var presi := []
	var ordine := []
	for k in req.size():
		if req[k] != "u":
			ordine.append(k)
	for k in req.size():
		if req[k] == "u":
			ordine.append(k)
	var scelta := []
	scelta.resize(req.size())
	var servono := {}
	for x in req:
		if x != "u":
			servono[x] = int(servono.get(x, 0)) + 1
	for k in ordine:
		var sk: String = req[k]
		var trovato := ""
		if sk != "u":
			for wid in liberi:
				if not wid in presi and lav(wid)["sk"] == sk:
					trovato = wid
					break
		else:
			# non qualificati liberi, poi qualificati disoccupati, poi chiunque
			for fase in 3:
				for wid in liberi:
					if wid in presi:
						continue
					var w: Dictionary = lav(wid)
					var dis: bool = w["loc"] == ""
					if fase == 0 and w["sk"] == "u":
						trovato = wid
					elif fase == 1 and dis:
						trovato = wid
					elif fase == 2:
						trovato = wid
					if trovato != "":
						break
				if trovato != "":
					break
		if trovato == "":
			return []
		presi.append(trovato)
		scelta[k] = trovato
	return scelta

## Possibili destinazioni per Assegnare Lavoratori della classe c con al massimo budget lavoratori.
## filtro: "" tutte, "proprie" solo aziende proprie (Classe Media), "nonop_cc" aziende non operative della CC...
func bersagli_assegna(c: int, budget: int, solo_dis: bool, filtro := "") -> Array:
	var o := []
	if budget <= 0:
		return o
	var lista := []
	if filtro in ["", "cc_pub"]:
		lista.append_array(s["priv_cc"])
		lista.append_array(s["pub"])
	if c == WC and filtro in ["", "mc_dip"]:
		lista.append_array(s["priv_mc"])
	if c == MC and filtro in ["", "proprie"]:
		lista.append_array(s["priv_mc"])
	if c == WC and filtro == "":
		lista.append_array(aziende_di(WC))
	for aid in lista:
		var d := Dati.az(aid)
		if d["auto"]:
			continue
		var a: Dictionary = s["aziende"][aid]
		if d["tipo"] == "MC":
			if c == MC:
				if operativa(aid) or d["slot"].size() > budget:
					continue
				var ws := scegli_lavoratori(MC, d["slot"], solo_dis, aid)
				if not ws.is_empty():
					o.append({"t": "%s (%d lav.)" % [d["n"], ws.size()], "v": {"aid": aid, "dip": false, "w": ws}})
			else:
				if d["dip"] == "" or not operativa(aid) or a["dip"] != "":
					continue
				var ws2 := scegli_lavoratori(WC, [d["dip"]], solo_dis, aid)
				if not ws2.is_empty():
					o.append({"t": "%s (dipendente, %s)" % [d["n"], nome(MC)], "v": {"aid": aid, "dip": true, "w": ws2}})
			continue
		if operativa(aid) or d["slot"].size() > budget:
			continue
		if d["tipo"] == "COOP" and c != WC:
			continue
		var ws3 := scegli_lavoratori(c, d["slot"], solo_dis, aid)
		if not ws3.is_empty():
			var chi: String = Dati.NOMI_BREVI[a["own"]] if d["tipo"] != "COOP" else "Classe Operaia"
			o.append({"t": "%s di %s (%d lav., salario %d)" % [d["n"], chi, ws3.size(), salario(aid)], "v": {"aid": aid, "dip": false, "w": ws3}})
	if c == WC and filtro == "":
		for ind in Dati.INDUSTRIE:
			if G(WC)["sind"][ind] != "" or lavoratori_industria(ind) < 4:
				continue
			var ws4 := scegli_lavoratori(WC, [ind], solo_dis, "")
			if ws4.is_empty():
				continue
			var w4: Dictionary = lav(ws4[0])
			if w4["loc"] != "" and s["aziende"].has(w4["loc"]) and Dati.az(w4["loc"])["ind"] == ind and lavoratori_industria(ind) <= 4:
				continue
			o.append({"t": "Sindacato %s" % Dati.NOMI_IND[ind], "v": {"aid": "sind:" + ind, "dip": false, "w": ws4}})
	return o

func _esegui_assegna(c: int, v: Dictionary, impegna := true) -> int:
	var aid: String = v["aid"]
	var ws: Array = v["w"]
	if aid.begins_with("sind:"):
		var wid: String = ws[0]
		_togli(wid)
		var w := lav(wid)
		w["loc"] = aid
		w["sl"] = -1
		w["imp"] = true
		G(WC)["sind"][aid.substr(5)] = wid
		_log("La Classe Operaia fonda il sindacato %s." % Dati.NOMI_IND[aid.substr(5)])
	elif v["dip"]:
		_metti(ws[0], aid, -2, impegna)
	else:
		for k in ws.size():
			_metti(ws[k], aid, k, impegna)
	_controlla_aziende()
	s["cnt"] = int(s.get("cnt", 0)) + ws.size()
	_ev({"tipo": "assegna", "g": c, "aid": aid})
	if aid.begins_with("sind:"):
		return 1
	_log("%s: %d lavoratori a %s." % [nome(c), ws.size(), Dati.az(aid)["n"]])
	return ws.size()

## Passo generico: assegna fino a "max" lavoratori (filtro, solo disoccupati, denaro per lavoratore dallo Stato...).
func _p_assegna_n(p: Dictionary) -> void:
	var c: int = p["c"]
	var resto: int = p["max"]
	if resto <= 0:
		return
	var ops := bersagli_assegna(c, resto, p.get("solo_dis", false), p.get("filtro", ""))
	if p.has("solo_aziende"):
		var f := []
		for op in ops:
			if op["v"]["aid"] in p["solo_aziende"]:
				f.append(op)
		ops = f
	if ops.is_empty():
		return
	if not _ha_r(p):
		var tutte: Array = ops.duplicate()
		tutte.push_front({"t": "Basta così", "v": null})
		_chiedi(p, int(p.get("chi", c)), "Assegna lavoratori (ancora %d)." % resto if resto < 50 else "Assegna lavoratori.", tutte, "assegna")
		return
	var v: Variant = _r(p)
	if typeof(v) == TYPE_NIL:
		return
	var n := _esegui_assegna(c, v)
	if p.get("soldi_stato", 0) > 0:
		trasferisci(ST, int(p.get("chi", c)), n * int(p["soldi_stato"]))
	if p.get("soldi_padrone", 0) > 0 and not str(v["aid"]).begins_with("sind:"):
		var own := proprietario(v["aid"])
		if own >= 0 and own != c:
			trasferisci(own, c, n * int(p["soldi_padrone"]))
	p["max"] = resto - n
	p["fatti"] = int(p.get("fatti", 0)) + n
	if p.get("una_sola", false):
		return
	_spingi(p)

func _p_a_assegna(p: Dictionary) -> void:
	_spingi({"k": "assegna_n", "c": p["c"], "max": 3})

# ---------------------------------------------------------------- comprare beni e servizi
func fonti(c: int, r: String) -> Array:
	var o := []
	for i in [MC, CC, ST]:
		if i == c and i != MC:
			continue
		if i == MC and c == MC:
			if r != "inf" and int(G(MC)["mag"][r]) > 0:
				o.append({"i": MC, "n": int(G(MC)["mag"][r]), "p": 0})
			continue
		if i in [MC, CC] and r == "inf":
			continue
		var n := disponibile(i, r)
		if n > 0:
			o.append({"i": i, "n": n, "p": prezzo(i, r)})
	if r in ["cibo", "lus"]:
		o.append({"i": 9, "n": 99, "p": prezzo_estero(r) + dazio(r)})
	return o

func nome_fonte(i: int) -> String:
	return "Mercato Estero" if i == 9 else nome(i)

func pop_compra_possibile(c: int) -> bool:
	for r in ["cibo", "lus", "sal", "ist", "inf"]:
		for f in fonti(c, r):
			if int(f["p"]) == 0 or soldi(c) >= int(f["p"]):
				return true
	return false

## Esegue un acquisto (denaro al venditore, dazi allo Stato). Ritorna la quantità.
func compra(c: int, r: String, i: int, n: int, frazione := 1.0, paga_stato_meta := false) -> int:
	if n <= 0:
		return 0
	var pu := prezzo(i, r) if i != 9 else prezzo_estero(r)
	var daz := dazio(r) if i == 9 and frazione > 0.0 else 0
	var tot := int(ceil(pu * n * frazione))
	if paga_stato_meta:
		var meta := int(ceil(pu * n / 2.0))
		tot = meta
		if i != 9:
			trasferisci(ST, i, pu * n - meta)
		else:
			paga(ST, pu * n - meta)
	if i == MC and c == MC:
		tot = 0
	paga(c, tot + daz * n)
	if i != 9:
		dai_soldi(i, tot)
		_togli_ris(i, r, n)
	if daz > 0:
		dai_soldi(ST, daz * n)
	if c == ST:
		immagazzina(ST, r, n)
	elif r == "inf":
		G(c)["inf"] = int(G(c)["inf"]) + n
	elif c in [WC, MC]:
		G(c)["beni"][r] = int(G(c)["beni"][r]) + n
	else:
		immagazzina(c, r, n)
	if i == ST and r in ["sal", "ist"]:
		_benefici_pubblici(c, r, n, prezzo_pubblico(r))
	s["cnt"] = int(s.get("cnt", 0)) + n
	_log("%s compra %d %s da %s (%d)." % [nome(c), n, Dati.NOMI_RIS[r], nome_fonte(i), tot + daz * n])
	_ev({"tipo": "compra", "g": c, "da": i, "r": r, "n": n})
	return n

func massimo_acquistabile(c: int, f: Dictionary, limite: int, frazione := 1.0, r := "") -> int:
	var n := mini(int(f["n"]), limite)
	var pu: int = f["p"]
	if r != "" and int(f["i"]) == 9 and frazione < 1.0:
		pu = prezzo_estero(r)
	var costo := pu * frazione
	if costo <= 0.0:
		return n
	return mini(n, int(floor(soldi(c) / costo)))

## Acquisto generico: parametri ris (fisso) / solo_fonte / max_fonti / limite (per fonte) / frazione / no_dazi / stato_meta / doppio.
func _p_a_compra(p: Dictionary) -> void:
	var c: int = p["c"]
	if not p.has("ris"):
		if not _ha_r(p):
			var ops := []
			var lista: Array = p.get("risorse", ["cibo", "lus", "sal", "ist", "inf"])
			for r in lista:
				var fs := _fonti_filtrate(p, c, r)
				var ok := false
				for f in fs:
					if massimo_acquistabile(c, f, 1, p.get("frazione", 1.0), r) > 0:
						ok = true
				if ok:
					var prezzi := []
					for f in fs:
						prezzi.append("%s %d" % [_sigla_fonte(int(f["i"])), int(ceil(int(f["p"]) * p.get("frazione", 1.0)))])
					ops.append({"t": "%s (%s)" % [Dati.NOMI_RIS[r], ", ".join(prezzi)], "v": r})
			if ops.is_empty():
				_log("%s non può comprare nulla." % nome(c))
				return
			ops.push_front({"t": "Non comprare nulla", "v": ""})
			_chiedi(p, c, "Cosa compri?", ops, "compra_ris")
			return
		p["ris"] = str(_r(p))
		if p["ris"] == "":
			return
	var r: String = p["ris"]
	var limite: int = p.get("limite", popolazione(c) if c in [WC, MC] else 99)
	var usate: Array = p.get("usate", [])
	var max_f: int = p.get("max_fonti", 2)
	if usate.size() >= max_f:
		return
	if not p.has("fonte"):
		var fs2 := _fonti_filtrate(p, c, r)
		var ops2 := []
		for f in fs2:
			if int(f["i"]) in usate:
				continue
			var m := massimo_acquistabile(c, f, limite, p.get("frazione", 1.0), r)
			if m > 0:
				ops2.append({"t": "%s: fino a %d a %d l'una" % [nome_fonte(int(f["i"])), m, int(ceil(int(f["p"]) * p.get("frazione", 1.0)))], "v": f["i"]})
		if ops2.is_empty():
			return
		if not _ha_r(p):
			ops2.push_front({"t": "Basta così", "v": -1})
			_chiedi(p, c, "Da chi compri %s?" % Dati.NOMI_RIS[r], ops2, "compra_fonte")
			return
		var fi := int(_r(p))
		if fi < 0:
			return
		p["fonte"] = fi
	var fonte: int = p["fonte"]
	var ff := {}
	for f in _fonti_filtrate(p, c, r):
		if int(f["i"]) == fonte:
			ff = f
	if ff.is_empty():
		p.erase("fonte")
		return
	var mx := massimo_acquistabile(c, ff, limite, p.get("frazione", 1.0), r)
	if mx <= 0:
		p.erase("fonte")
		return
	if not _ha_r(p):
		var ops3 := []
		for q in range(mx, 0, -1):
			ops3.append({"t": "%d %s" % [q, Dati.NOMI_RIS[r]], "v": q})
		_chiedi(p, c, "Quante %s compri da %s?" % [Dati.NOMI_RIS[r], nome_fonte(fonte)], ops3, "compra_qta")
		return
	var q2 := int(_r(p))
	if p.get("no_dazi", false) and fonte == 9:
		var pu := prezzo_estero(r)
		paga(c, pu * q2)
		G(c)["beni"][r] = int(G(c)["beni"][r]) + q2
		_log("%s importa %d %s senza dazi." % [nome(c), q2, Dati.NOMI_RIS[r]])
		s["cnt"] = int(s.get("cnt", 0)) + q2
	elif p.get("stato_meta", false):
		compra(c, r, fonte, q2, 0.5, true)
	else:
		compra(c, r, fonte, q2, p.get("frazione", 1.0))
	p["comprati"] = int(p.get("comprati", 0)) + q2
	usate.append(fonte)
	p["usate"] = usate
	p.erase("fonte")
	_spingi(p)

func _fonti_filtrate(p: Dictionary, c: int, r: String) -> Array:
	var fs := fonti(c, r)
	if p.has("solo_fonte"):
		var o := []
		for f in fs:
			if int(f["i"]) in p["solo_fonte"]:
				o.append(f)
		return o
	return fs

func _sigla_fonte(i: int) -> String:
	return ["CO", "CM", "CC", "Stato", "", "", "", "", "", "Estero"][i]

# ---------------------------------------------------------------- Classe Operaia: sciopero e manifestazione
func bersagli_sciopero() -> Array:
	var o := []
	for aid in s["priv_cc"] + s["priv_mc"] + s["pub"]:
		var a: Dictionary = s["aziende"][aid]
		if a["sc"] or int(a["sal"]) >= 3 or not operativa(aid):
			continue
		var d := Dati.az(aid)
		var wcs := []
		if d["tipo"] == "MC":
			if a["dip"] != "":
				wcs.append(a["dip"])
		elif classe_lavoratori(aid) == WC:
			wcs = lavoratori_in(aid)
		if wcs.is_empty():
			continue
		var imp := false
		for w in wcs:
			if lav(w)["imp"]:
				imp = true
		if imp:
			continue
		o.append({"t": "%s di %s (salario L%d)" % [d["n"], Dati.NOMI_BREVI[a["own"]], int(a["sal"])], "v": aid})
	return o

func _p_a_sciopero(p: Dictionary) -> void:
	var resto: int = p.get("max", 2)
	if resto <= 0:
		return
	var ops := bersagli_sciopero()
	if ops.is_empty():
		return
	if not _ha_r(p):
		ops.push_front({"t": "Basta così", "v": ""})
		_chiedi(p, WC, "Dove metti un segnalino Sciopero? (ancora %d)" % resto, ops, "sciopero")
		return
	var aid: String = str(_r(p))
	if aid == "":
		return
	s["aziende"][aid]["sc"] = true
	_log("Sciopero a %s!" % Dati.az(aid)["n"])
	_ev({"tipo": "sciopero", "aid": aid})
	p["max"] = resto - 1
	_spingi(p)

func posti_per_operai() -> int:
	var n := 0
	for aid in s["priv_cc"] + s["pub"] + aziende_di(WC):
		var d := Dati.az(aid)
		if not d["auto"] and not operativa(aid) and classe_lavoratori(aid) < 0:
			n += d["slot"].size()
	for aid in s["priv_mc"]:
		var d2 := Dati.az(aid)
		if d2["dip"] != "" and operativa(aid) and s["aziende"][aid]["dip"] == "":
			n += 1
	return n

func manifestazione_possibile() -> bool:
	return not s["dimostr"] and disoccupati(WC).size() >= posti_per_operai() + 2

func _p_a_manifestazione(_p: Dictionary) -> void:
	s["dimostr"] = true
	_log("La Classe Operaia scende in piazza: Manifestazione!")
	_ev({"tipo": "manifestazione"})

## Dopo che qualcuno ha costruito e assunto operai: la manifestazione finisce se la condizione non vale più.
func _verifica_manifestazione() -> void:
	if s["dimostr"] and disoccupati(WC).size() < posti_per_operai() + 2:
		s["dimostr"] = false
		_log("La Manifestazione si scioglie.")

# ---------------------------------------------------------------- costruire aziende
func posti_liberi(c: int) -> int:
	return (12 if c == CC else 8) - aziende_di(c).size()

## Aziende costruibili dalla classe c con lo sconto indicato (valori negativi = sovrapprezzo).
func costruibili(c: int, sconto: int, lista := [], gratis := false, mc_extra := "") -> Array:
	var o := []
	if c in [CC, MC] and posti_liberi(c) <= 0:
		return o
	var mercato: Array = lista if not lista.is_empty() else G(c)["mercato"]
	for aid in mercato:
		var d := Dati.az(aid)
		var costo := maxi(0, int(d["costo"]) - sconto)
		if not gratis and not puo_pagare(c, costo):
			continue
		if c == MC:
			var req: Array = d["slot"].duplicate()
			if mc_extra != "":
				var k := req.find(mc_extra)
				if k < 0:
					continue
				req.remove_at(k)
			if not req.is_empty() and scegli_lavoratori(MC, req, false).is_empty():
				continue
		o.append({"t": "%s (%s, costo %d)" % [d["n"], Dati.NOMI_IND[d["ind"]], 0 if gratis else costo], "v": aid})
	return o

## Costruzione: parametri sconto, gratis (paga lo Stato), stato_meta, lista (aziende tra cui scegliere), mc_extra (abilità dalla scorta).
func _p_a_costruisci(p: Dictionary) -> void:
	var c: int = p["c"]
	var chi: int = p.get("chi", c)
	if not p.has("aid"):
		var ops := costruibili(c, p.get("sconto", 0), p.get("lista", []), p.get("gratis", false) or p.get("paga_stato", false), p.get("mc_extra", ""))
		if p.has("filtro_ind"):
			var f := []
			for op in ops:
				if Dati.az(op["v"])["ind"] in p["filtro_ind"]:
					f.append(op)
			ops = f
		if ops.is_empty():
			_log("%s non può costruire." % nome(c))
			return
		if not _ha_r(p):
			_chiedi(p, chi, "Quale Azienda costruisci?", ops, "costruisci")
			return
		p["aid"] = str(_r(p))
	var aid: String = p["aid"]
	var d := Dati.az(aid)
	if not p.has("sal") and d["sal"][0] > 0 and (d["tipo"] != "MC" or d["dip"] != ""):
		if not _ha_r(p):
			var ops2 := []
			for lv in range(salario_minimo(), 4):
				ops2.append({"t": "Salario L%d (%d)" % [lv, int(d["sal"][lv - 1])], "v": lv})
			_chiedi(p, c, "Che salario offri in %s?" % d["n"], ops2, "salario")
			return
		p["sal"] = int(_r(p))
	if not p.has("costruita"):
		var costo := maxi(0, int(d["costo"]) - int(p.get("sconto", 0)))
		if p.get("gratis", false):
			pass
		elif p.get("paga_stato", false):
			paga(ST, costo)
		elif p.get("stato_meta", false):
			var meta := int(ceil(costo / 2.0))
			paga(c, meta)
			paga(ST, costo - meta)
		else:
			paga(c, costo)
		G(c)["mercato"].erase(aid)
		G(c)["mazzo_az"].erase(aid)
		_crea_azienda(aid, Dati.CLASSI[c], int(p.get("sal", maxi(2, salario_minimo()))))
		aziende_di(c).append(aid)
		p["costruita"] = true
		_log("%s costruisce %s." % [nome(c), d["n"]])
		_ev({"tipo": "costruisci", "g": c, "aid": aid})
		if c == MC:
			var req: Array = d["slot"].duplicate()
			var extra: String = p.get("mc_extra", "")
			var ws := []
			if extra != "":
				var nuovo := _nuovo_lav(MC, extra)
				var k := req.find(extra)
				req.remove_at(k)
				var resto := scegli_lavoratori(MC, req, false, "", [nuovo])
				ws.resize(d["slot"].size())
				ws[k] = nuovo
				var j := 0
				for x in d["slot"].size():
					if x != k:
						ws[x] = resto[j]
						j += 1
			else:
				ws = scegli_lavoratori(MC, req, false)
			for x in ws.size():
				_metti(ws[x], aid, x, true)
			_controlla_aziende()
	# assunzione dei disoccupati
	if d["auto"]:
		return
	if c == MC:
		if d["dip"] == "":
			return
		var wsd := scegli_lavoratori(WC, [d["dip"]], true)
		if wsd.is_empty():
			return
		if not _ha_r(p):
			_chiedi(p, c, "Assumi un disoccupato della Classe Operaia in %s?" % d["n"], [{"t": "Sì, assumi", "v": true}, {"t": "No", "v": false}], "assumi")
			return
		if bool(_r(p)):
			_metti(wsd[0], aid, -2, true)
			_verifica_manifestazione()
		return
	var opz := []
	for k2 in [WC, MC]:
		var ws2 := scegli_lavoratori(k2, d["slot"], true)
		if not ws2.is_empty():
			opz.append({"t": "Assumi disoccupati della %s" % nome(k2), "v": k2})
	if opz.is_empty():
		return
	if not _ha_r(p):
		opz.append({"t": "Non assumere ora", "v": -1})
		_chiedi(p, c, "Assumi lavoratori in %s?" % d["n"], opz, "assumi")
		return
	var k3 := int(_r(p))
	if k3 < 0:
		return
	var ws3 := scegli_lavoratori(k3, d["slot"], true)
	for x in ws3.size():
		_metti(ws3[x], aid, x, true)
	_controlla_aziende()
	_verifica_manifestazione()

func vendibili(c: int, solo_non_auto := false) -> Array:
	var o := []
	for aid in aziende_di(c):
		if impegnata(aid):
			continue
		if solo_non_auto and Dati.az(aid)["auto"]:
			continue
		o.append({"t": "%s (+%d)" % [Dati.az(aid)["n"], int(Dati.az(aid)["costo"])], "v": aid})
	return o

func _p_a_vendi_az(p: Dictionary) -> void:
	var c: int = p["c"]
	var ops := vendibili(c, p.get("non_auto", false))
	if ops.is_empty():
		return
	if not _ha_r(p):
		_chiedi(p, c, "Quale Azienda vendi?", ops, "vendi_az")
		return
	var aid: String = str(_r(p))
	var guadagno := int(Dati.az(aid)["costo"]) * int(p.get("molt", 1))
	_vendi_azienda(c, aid)
	dai_soldi(c, guadagno)
	_log("%s vende %s per %d." % [nome(c), Dati.az(aid)["n"], guadagno])

func _vendi_azienda(c: int, aid: String) -> void:
	_svuota(aid)
	aziende_di(c).erase(aid)
	s["aziende"].erase(aid)
	if aid.begins_with("p"):
		s["pub_giu"].append(aid)
		_crea_azienda(aid, "ST", 2)
	_controlla_aziende()
	_ev({"tipo": "vendi", "g": c, "aid": aid})

# ---------------------------------------------------------------- mercato estero
## Transazioni disponibili sulla carta Export corrente (fatte: chiavi "r:k" già usate e quante volte).
func transazioni_export(c: int, fatte: Dictionary, ripeti := 1, carta := -1, solo := []) -> Array:
	var o := []
	var x: Dictionary = Dati.d()["export"][s["export"] if carta < 0 else carta]
	var risorse := Dati.RISORSE if c != ST else ["cibo", "lus"]
	if not solo.is_empty():
		risorse = solo
	for r in risorse:
		for k in 2:
			var key := "%s:%d" % [r, k]
			if int(fatte.get(key, 0)) >= ripeti:
				continue
			var q: int = x[r][k][0]
			if scorta_vendibile(c, r) >= q:
				o.append({"t": "Vendi %d %s per %d" % [q, Dati.NOMI_RIS[r], int(x[r][k][1])], "v": key})
	return o

func scorta_vendibile(c: int, r: String) -> int:
	match c:
		CC:
			var n: int = G(CC)["mag"][r]
			if r in ["cibo", "lus"]:
				n += int(G(CC)["ftz"][r])
			return n
		MC:
			return int(G(MC)["mag"][r])
		ST:
			if r in ["cibo", "lus"]:
				return int(G(ST)["mag"][r])
			return int(s["servizi"][r])
	return 0

func _usa_scorta(c: int, r: String, n: int) -> void:
	if c == CC and r in ["cibo", "lus"]:
		var f := mini(n, int(G(CC)["ftz"][r]))
		G(CC)["ftz"][r] = int(G(CC)["ftz"][r]) - f
		n -= f
	_togli_ris(c, r, n)

## Vendita al mercato estero. Parametri: ripeti, extra_stato (denaro dallo Stato per transazione), solo (risorse).
func _p_a_estero(p: Dictionary) -> void:
	var c: int = p["c"]
	var fatte: Dictionary = p.get("fatte", {})
	var ops := transazioni_export(c, fatte, p.get("ripeti", 1), -1, p.get("solo", []))
	if ops.is_empty():
		_fine_estero(p)
		return
	if not _ha_r(p):
		ops.push_front({"t": "Basta così", "v": ""})
		_chiedi(p, c, "Vendi al Mercato Estero.", ops, "estero")
		return
	var key: String = str(_r(p))
	if key == "":
		_fine_estero(p)
		return
	var r := key.split(":")[0]
	var k := int(key.split(":")[1])
	var x: Dictionary = Dati.d()["export"][s["export"]]
	var q: int = x[r][k][0]
	var m: int = x[r][k][1]
	_usa_scorta(c, r, q)
	dai_soldi(c, m)
	fatte[key] = int(fatte.get(key, 0)) + 1
	p["fatte"] = fatte
	p["n"] = int(p.get("n", 0)) + 1
	s["cnt"] = int(s.get("cnt", 0)) + 1
	_log("%s vende %d %s all'estero per %d." % [nome(c), q, Dati.NOMI_RIS[r], m])
	_ev({"tipo": "export", "g": c, "r": r, "n": q, "m": m})
	if c == MC:
		vp(MC, 1, "esportazione")
	if int(p.get("extra_stato", 0)) > 0:
		trasferisci(ST, c, int(p["extra_stato"]))
	_spingi(p)

func _fine_estero(p: Dictionary) -> void:
	if p.has("dopo_carta"):
		s["export"] = p["dopo_carta"]

# ---------------------------------------------------------------- Classe Media: turno extra
func bersagli_turno_extra(c: int) -> Array:
	var o := []
	for aid in aziende_di(c):
		if not operativa(aid):
			continue
		var d := Dati.az(aid)
		if c == MC:
			var libero := false
			for wid in s["aziende"][aid]["lav"]:
				if not lav(wid)["imp"]:
					libero = true
			if not libero:
				continue
		elif d["auto"]:
			continue
		elif s["aziende"][aid]["sc"]:
			continue
		o.append({"t": "%s (+%d %s)" % [d["n"], produzione(aid), Dati.NOMI_RIS[Dati.RIS_IND[d["ind"]]]], "v": aid})
	return o

func _p_a_turno_extra(p: Dictionary) -> void:
	var c: int = p["c"]
	var ops := bersagli_turno_extra(c)
	if p.has("solo_aziende"):
		var f := []
		for op in ops:
			if op["v"] in p["solo_aziende"]:
				f.append(op)
		ops = f
	if ops.is_empty():
		return
	if not _ha_r(p):
		if p.get("facoltativo", false):
			ops.push_front({"t": "Nessun turno extra", "v": ""})
		_chiedi(p, c, "Quale Azienda fa un turno extra?", ops, "turno_extra")
		return
	var aid: String = str(_r(p))
	if aid == "":
		return
	_produci(aid, true)
	for wid in lavoratori_in(aid):
		lav(wid)["imp"] = true

# ---------------------------------------------------------------- Classe Capitalista
func _p_a_accordo(p: Dictionary) -> void:
	if s["accordi_tav"].is_empty():
		return
	if not p.has("acc"):
		if not _ha_r(p):
			var ops := []
			for k in s["accordi_tav"]:
				var a: Dictionary = Dati.d()["accordi"][k]
				var daz: int = a["dazio"][polx(5)]
				var testo := "%s%s: %d (+%d di dazio, oppure tutto in zona franca)" % [
					"%d Cibo " % int(a["cibo"]) if int(a["cibo"]) > 0 else "", "%d Lusso" % int(a["lus"]) if int(a["lus"]) > 0 else "", int(a["costo"]), daz]
				if puo_pagare(CC, int(a["costo"])):
					ops.append({"t": testo, "v": k})
			if ops.is_empty():
				return
			_chiedi(p, CC, "Quale Accordo Commerciale?", ops, "accordo")
			return
		p["acc"] = int(_r(p))
	var a2: Dictionary = Dati.d()["accordi"][p["acc"]]
	var daz2: int = a2["dazio"][polx(5)]
	if not _ha_r(p):
		var ops2 := [{"t": "Tutto nella Zona di Libero Scambio (%d)" % int(a2["costo"]), "v": "ftz"}]
		if puo_pagare(CC, int(a2["costo"]) + daz2):
			ops2.append({"t": "Nei Magazzini, pagando i dazi (%d)" % (int(a2["costo"]) + daz2), "v": "mag"})
		_chiedi(p, CC, "Dove metti le merci?", ops2, "accordo_dove")
		return
	var dove: String = str(_r(p))
	s["accordi_tav"].erase(p["acc"])
	paga(CC, int(a2["costo"]))
	for r in ["cibo", "lus"]:
		var n: int = a2[r]
		if n <= 0:
			continue
		if dove == "ftz":
			var lim := 8 if r == "cibo" else 12
			G(CC)["ftz"][r] = mini(lim, int(G(CC)["ftz"][r]) + n)
		else:
			immagazzina(CC, r, n)
	if dove == "mag":
		trasferisci(CC, ST, daz2)
	_log("La Classe Capitalista conclude un Accordo Commerciale.")

func _p_a_lobby(_p: Dictionary) -> void:
	paga(CC, 30, true)
	G(CC)["inf"] = int(G(CC)["inf"]) + 3

# ---------------------------------------------------------------- Stato
func _p_a_incontro(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		for c in 3:
			ops.append({"t": "%s (Legittimità %d)" % [nome(c), int(G(ST)["leg"][c])], "v": c})
		_chiedi(p, ST, "Con quale classe ti incontri? (le dai 2 Influenza)", ops, "classe")
		return
	var c2 := int(_r(p))
	G(ST)["inf"] = int(G(ST)["inf"]) - 2
	G(c2)["inf"] = int(G(c2)["inf"]) + 2
	legit(c2, 1)

func _p_a_tassa_extra(_p: Dictionary) -> void:
	for c in 3:
		trasferisci(c, ST, 10)
	var ord := [0, 1, 2]
	ord.sort_custom(func(a, b): return int(G(ST)["leg"][a]) < int(G(ST)["leg"][b]))
	legit(ord[0], -1)
	legit(ord[1], -1)

func _p_a_campagna(p: Dictionary) -> void:
	var m := mini(3, int(s["servizi"]["inf"]))
	if m <= 0:
		return
	if not _ha_r(p):
		var ops := []
		for q in range(m, 0, -1):
			ops.append({"t": "%d Influenza" % q, "v": q})
		_chiedi(p, ST, "Quanta Influenza dei Media prendi?", ops, "quantita")
		return
	var q2 := int(_r(p))
	s["servizi"]["inf"] = int(s["servizi"]["inf"]) - q2
	G(ST)["inf"] = int(G(ST)["inf"]) + q2

# ================================================================ azioni gratuite
func _p_l_sanita(p: Dictionary) -> void:
	var c: int = p["c"]
	G(c)["beni"]["sal"] = int(G(c)["beni"]["sal"]) - popolazione(c)
	prosperita(c)
	vp(c, 2, "assistenza sanitaria")
	_nuovo_lav(c, "u")

func _p_l_lusso(p: Dictionary) -> void:
	var c: int = p["c"]
	G(c)["beni"]["lus"] = int(G(c)["beni"]["lus"]) - popolazione(c)
	prosperita(c)

func _p_l_istruzione(p: Dictionary) -> void:
	var c: int = p["c"]
	if not p.has("pagato"):
		G(c)["beni"]["ist"] = int(G(c)["beni"]["ist"]) - popolazione(c)
		prosperita(c)
		p["pagato"] = true
	if not p.has("w"):
		if not _ha_r(p):
			var ops := []
			var visti := {}
			for wid in lavoratori(c):
				var w := lav(wid)
				if w["loc"].begins_with("sind:"):
					continue
				if w["sk"] != "u" and w["loc"] != "" and int(w["sl"]) >= 0:
					var req: Array = Dati.az(w["loc"])["slot"]
					if req[int(w["sl"])] != "u":
						continue
				var chiave: String = "%s|%s" % [w["sk"], w["loc"]]
				if visti.has(chiave):
					continue
				visti[chiave] = true
				var dove: String = "disoccupato" if w["loc"] == "" else Dati.az(w["loc"])["n"]
				ops.append({"t": "Lavoratore %s (%s)" % [Dati.NOMI_IND[w["sk"]], dove], "v": wid})
			ops.sort_custom(func(a, b): return int(lav(a["v"])["sk"] != "u") < int(lav(b["v"])["sk"] != "u"))
			if ops.is_empty():
				return
			_chiedi(p, c, "Quale lavoratore istruisci?", ops, "istruisci")
			return
		p["w"] = str(_r(p))
	if not _ha_r(p):
		var ops2 := []
		for ind in Dati.INDUSTRIE:
			if ind != lav(p["w"])["sk"]:
				ops2.append({"t": Dati.NOMI_IND[ind], "v": ind})
		_chiedi(p, c, "In quale industria si specializza?", ops2, "abilita")
		return
	lav(p["w"])["sk"] = str(_r(p))
	_log("%s: un lavoratore si specializza in %s." % [nome(c), Dati.NOMI_IND[lav(p["w"])["sk"]]])

func coppie_scambio(c: int) -> Array:
	var o := []
	var dis := disoccupati(c)
	if dis.is_empty():
		return o
	for wid in lavoratori(c):
		var w := lav(wid)
		if w["sk"] == "u" or w["loc"] == "" or int(w["sl"]) < 0 or not s["aziende"].has(w["loc"]):
			continue
		var req: Array = Dati.az(w["loc"])["slot"]
		if req[int(w["sl"])] != "u":
			continue
		var altro := ""
		for d in dis:
			if lav(d)["sk"] == "u":
				altro = d
				break
		if altro == "":
			continue
		o.append({"t": "%s da %s con un disoccupato %s" % [Dati.NOMI_IND[w["sk"]], Dati.az(w["loc"])["n"], Dati.NOMI_IND[lav(altro)["sk"]]], "v": [wid, altro]})
	return o

func _p_l_scambia(p: Dictionary) -> void:
	var c: int = p["c"]
	var ops := coppie_scambio(c)
	if ops.is_empty():
		return
	if not _ha_r(p):
		ops.push_front({"t": "Basta così", "v": null})
		_chiedi(p, c, "Scambia lavoratori.", ops, "scambia")
		return
	var v: Variant = _r(p)
	if typeof(v) == TYPE_NIL:
		return
	var a: String = v[0]
	var b: String = v[1]
	var loc: String = lav(a)["loc"]
	var sl: int = lav(a)["sl"]
	var imp: bool = lav(a)["imp"]
	_togli(a)
	lav(a)["imp"] = false
	_metti(b, loc, sl, imp)
	p["volte"] = int(p.get("volte", 0)) + 1
	if int(p["volte"]) < 6:
		_spingi(p)

func _p_l_benefici(p: Dictionary) -> void:
	var c: int = p["c"]
	var b: Dictionary = G(ST)["ben"][c]
	dai_soldi(c, int(b["soldi"]))
	for r in Dati.RISORSE:
		if int(b[r]) > 0:
			if c in [WC, MC]:
				G(c)["beni"][r] = int(G(c)["beni"][r]) + int(b[r])
			else:
				immagazzina(c, r, int(b[r]))
	G(c)["inf"] = int(G(c)["inf"]) + int(b["inf"])
	aggiungi_cubi(c, int(b["cubi"]))
	G(ST)["ben"][c] = _ben_vuoto()
	vp(ST, 1, "benefici ricevuti")
	_log("%s riceve i benefici dello Stato." % nome(c))

func _p_l_prestito(p: Dictionary) -> void:
	var c: int = p["c"]
	paga(c, 50, true)
	G(c)["prestiti"] = int(G(c)["prestiti"]) - 1
	_log("%s estingue un Prestito." % nome(c))

func _p_l_prezzi(p: Dictionary) -> void:
	var c: int = p["c"]
	if not p.has("ris"):
		if not _ha_r(p):
			var ops := [{"t": "Fatto", "v": ""}]
			for r in Dati.RISORSE:
				ops.append({"t": "%s (ora %d)" % [Dati.NOMI_RIS[r], int(G(c)["prezzi"][r])], "v": r})
			_chiedi(p, c, "Quale prezzo cambi?", ops, "prezzi")
			return
		var r = str(_r(p))
		if r == "":
			return
		p["ris"] = r
	var livelli := [9, 12, 15] if p["ris"] == "cibo" else [5, 8, 10]
	if not _ha_r(p):
		var ops2 := []
		for x in livelli:
			ops2.append({"t": "%d" % x, "v": x})
		_chiedi(p, c, "Nuovo prezzo di %s:" % Dati.NOMI_RIS[p["ris"]], ops2, "prezzo")
		return
	G(c)["prezzi"][p["ris"]] = int(_r(p))
	p.erase("ris")
	p["volte"] = int(p.get("volte", 0)) + 1
	if int(p["volte"]) < 4:
		_spingi(p)

func aziende_salario(c: int) -> Array:
	var o := []
	for aid in aziende_di(c):
		var d := Dati.az(aid)
		if d["auto"] or d["sal"][0] == 0:
			continue
		o.append(aid)
	return o

func _p_l_salari(p: Dictionary) -> void:
	var c: int = p["c"]
	if not p.has("aid"):
		if not _ha_r(p):
			var ops := [{"t": "Fatto", "v": ""}]
			for aid in aziende_salario(c):
				if aid in p.get("fatte", []):
					continue
				ops.append({"t": "%s (L%d = %d)" % [Dati.az(aid)["n"], int(az(aid)["sal"]), salario(aid)], "v": aid})
			_chiedi(p, c, "Quale salario cambi?", ops, "salari")
			return
		var a = str(_r(p))
		if a == "":
			return
		p["aid"] = a
	var aid2: String = p["aid"]
	var d2 := Dati.az(aid2)
	if not _ha_r(p):
		var ops2 := []
		var imp := impegnata(aid2)
		for lv in range(salario_minimo(), 4):
			if imp and lv < int(az(aid2)["sal"]):
				continue
			ops2.append({"t": "L%d (%d)" % [lv, int(d2["sal"][lv - 1])], "v": lv})
		_chiedi(p, c, "Salario di %s:" % d2["n"], ops2, "salario")
		return
	var lv2 := int(_r(p))
	if lv2 > int(az(aid2)["sal"]):
		for wid in lavoratori_in(aid2):
			lav(wid)["imp"] = true
	az(aid2)["sal"] = lv2
	p.erase("aid")
	var fatte: Array = p.get("fatte", [])
	fatte.append(aid2)
	p["fatte"] = fatte
	_spingi(p)

func _p_l_bonus(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		for aid in s["priv_cc"]:
			if operativa(aid) and not Dati.az(aid)["auto"]:
				ops.append({"t": Dati.az(aid)["n"], "v": aid})
		_chiedi(p, CC, "A quale Azienda dai il premio di 5?", ops, "bonus")
		return
	var aid: String = str(_r(p))
	var k := classe_lavoratori(aid)
	trasferisci(CC, k, 5)
	for wid in lavoratori_in(aid):
		lav(wid)["imp"] = true

func _p_l_magazzino(p: Dictionary) -> void:
	var c: int = p["c"]
	if not _ha_r(p):
		var ops := []
		for r in Dati.RISORSE:
			if not G(c)["extra"][r] and (p.get("qualsiasi", false) or produce(c, r)):
				ops.append({"t": Dati.NOMI_RIS[r], "v": r})
		if ops.is_empty():
			return
		_chiedi(p, c, "Magazzino aggiuntivo per quale risorsa?", ops, "magazzino")
		return
	var r2: String = str(_r(p))
	if not p.get("gratis", false):
		paga(c, 20)
	G(c)["extra"][r2] = true
	s["scelta_ris"] = r2

# ================================================================ produzione
## Produzione di un'azienda: paga i salari e produce. extra = turno extra (impegna, non dipende dalla fase).
func _produci(aid: String, extra := false) -> void:
	var a: Dictionary = s["aziende"][aid]
	var d := Dati.az(aid)
	var own := proprietario(aid)
	if own < 0:
		own = WC
	var r: String = Dati.RIS_IND[d["ind"]]
	if not operativa(aid):
		return
	var n := 0
	if d["tipo"] == "MC":
		var principali_ok := true
		if extra:
			principali_ok = false
			for wid in a["lav"]:
				if not lav(wid)["imp"]:
					principali_ok = true
		if principali_ok:
			n += int(d["prod"])
		if a["dip"] != "" and not a["sc"] and not (extra and lav(a["dip"])["imp"]):
			trasferisci(MC, WC, salario(aid))
			n += int(d["bonus"])
	elif d["tipo"] == "COOP":
		n = int(d["prod"])
	else:
		if a["sc"]:
			return
		if not d["auto"]:
			var k := classe_lavoratori(aid)
			trasferisci(own, k, salario(aid))
		n = produzione(aid)
	var messi := immagazzina(own, r, n)
	_ev({"tipo": "produci", "aid": aid, "r": r, "n": messi})

func _p_produzione(_p: Dictionary) -> void:
	s["fase"] = "produzione"
	_log("--- Round %d: produzione ---" % int(s["round"]))
	# scioperi
	for aid in s["aziende"]:
		var a: Dictionary = s["aziende"][aid]
		if a["sc"] and (int(a["sal"]) >= 3 or not operativa(aid)):
			a["sc"] = false
	for aid in s["aziende"]:
		if s["aziende"][aid]["sc"]:
			G(WC)["inf"] = int(G(WC)["inf"]) + 1
			_log("Sciopero riuscito a %s: +1 Influenza alla Classe Operaia." % Dati.az(aid)["n"])
	# manifestazione
	if s["dimostr"]:
		s["dimostr"] = false
		G(WC)["inf"] = int(G(WC)["inf"]) + 1
		var perdita := disoccupati(WC).size() + sindacati()
		var spazi := {MC: posti_liberi(MC), CC: posti_liberi(CC), ST: 9 - s["pub"].size()}
		var ord := [MC, CC, ST]
		ord.sort_custom(func(x, y): return int(G(x)["vp"]) > int(G(y)["vp"]))
		while perdita > 0:
			var tolto := false
			for i in ord:
				if perdita > 0 and int(spazi[i]) > 0:
					spazi[i] = int(spazi[i]) - 1
					vp(i, -1)
					perdita -= 1
					tolto = true
			if not tolto:
				break
		_log("La Manifestazione costa PV alle altre classi.")
	for own in [ST, CC, MC, WC]:
		for aid in aziende_di(own).duplicate():
			_produci(aid)
	if sindacati() > 0:
		G(WC)["inf"] = int(G(WC)["inf"]) + sindacati()
	for aid in s["aziende"]:
		s["aziende"][aid]["sc"] = false
	for wid in s["lav"]:
		if not str(s["lav"][wid]["loc"]).begins_with("sind:"):
			s["lav"][wid]["imp"] = false
	# bisogni
	for c in [MC, WC]:
		_copri_bisogni(c)
	_controlla_fmi()
	s["lm_tasse"] = "" if not s.has("lm_tasse_prev") else s["lm_tasse_prev"]
	_tasse()
	s.erase("lm_tasse_prev")

func _copri_bisogni(c: int) -> void:
	var serve := popolazione(c)
	var g := G(c)
	var usa := mini(serve, int(g["beni"]["cibo"]))
	g["beni"]["cibo"] = int(g["beni"]["cibo"]) - usa
	serve -= usa
	if c == MC:
		var u2 := mini(serve, int(g["mag"]["cibo"]))
		g["mag"]["cibo"] = int(g["mag"]["cibo"]) - u2
		serve -= u2
	while serve > 0:
		var best := {}
		for f in fonti(c, "cibo"):
			if int(f["i"]) == c:
				continue
			if best.is_empty() or int(f["p"]) < int(best["p"]):
				best = f
		var q := mini(serve, int(best["n"]))
		var pu := prezzo(int(best["i"]), "cibo") if int(best["i"]) != 9 else prezzo_estero("cibo")
		var daz := dazio("cibo") if int(best["i"]) == 9 else 0
		paga(c, (pu + daz) * q)
		if int(best["i"]) != 9:
			dai_soldi(int(best["i"]), pu * q)
			_togli_ris(int(best["i"]), "cibo", q)
		if daz > 0:
			dai_soldi(ST, daz * q)
		_log("%s compra %d Cibo da %s per sfamare la popolazione." % [nome(c), q, nome_fonte(int(best["i"]))])
		serve -= q

func limite_prestiti_stato() -> int:
	return 1 if pol(0) == "C" else 2

func _controlla_fmi() -> void:
	var gs := G(ST)
	while int(gs["prestiti"]) >= limite_prestiti_stato() and int(gs["soldi"]) >= 55:
		gs["soldi"] = int(gs["soldi"]) - 55
		gs["prestiti"] = int(gs["prestiti"]) - 1
	if int(gs["prestiti"]) < limite_prestiti_stato():
		return
	_log("Lo Stato è insolvente: interviene il Fondo Monetario Internazionale!")
	_ev({"tipo": "fmi"})
	for k in 7:
		var pr = s["prop"][k]
		if pr != null:
			G(int(pr["c"]))["inf"] = int(G(int(pr["c"]))["inf"]) + 1
			G(int(pr["c"]))["bill"] = int(G(int(pr["c"]))["bill"]) + 1
			s["prop"][k] = null
	s["lm_tasse_prev"] = pol(1)
	for k in 7:
		if pol(k) != Dati.POL_FMI[k]:
			_cambia_politica(k, Dati.POL_FMI[k])
	for aid in s["aziende"]:
		if not Dati.az(aid)["auto"]:
			s["aziende"][aid]["sal"] = 1
	while int(gs["prestiti"]) > 0 and int(gs["soldi"]) >= 55:
		gs["soldi"] = int(gs["soldi"]) - 55
		gs["prestiti"] = int(gs["prestiti"]) - 1
	if int(gs["prestiti"]) > 0:
		gs["soldi"] = 0
		gs["prestiti"] = 0
	for c in 3:
		gs["leg"][c] = int(ceil(int(gs["leg"][c]) / 2.0))

func _tasse() -> void:
	var lm := polx(1) if s["lm_tasse"] == "" else Dati.SEZ.find(s["lm_tasse"])
	var tx := polx(2)
	var molt := moltiplicatore()
	# Classe Capitalista
	var imp := operative(CC) * molt
	paga(CC, imp)
	var rev: int = maxi(0, int(G(CC)["rev"]))
	var soc := 0
	for k in Dati.SOGLIE_SOCIETA.size():
		if rev >= Dati.SOGLIE_SOCIETA[k]:
			soc = Dati.TASSA_SOCIETA[k][tx]
	paga(CC, soc)
	dai_soldi(ST, imp + soc)
	_log("Tasse Classe Capitalista: %d (lavoro) + %d (società)." % [imp, soc])
	# Classe Media
	var esterne := {}
	for wid in lavoratori(MC):
		var loc: String = lav(wid)["loc"]
		if loc != "" and s["aziende"].has(loc) and not loc in s["priv_mc"]:
			esterne[loc] = true
	var tm: int = Dati.TASSA_REDDITO[lm][tx] * esterne.size() + operative(MC) * molt
	paga(MC, tm)
	dai_soldi(ST, tm)
	_log("Tasse Classe Media: %d." % tm)
	var tw: int = Dati.TASSA_REDDITO[lm][tx] * popolazione(WC)
	paga(WC, tw)
	dai_soldi(ST, tw)
	_log("Tasse Classe Operaia: %d." % tw)
	s["lm_tasse"] = ""

# ================================================================ cambi di politica
func _cambia_politica(k: int, sez: String) -> void:
	var prima := pol(k)
	s["pol"][k] = sez
	_log("La Politica %s passa a %d%s." % [Dati.POLITICHE[k], k + 1, sez])
	_ev({"tipo": "politica", "pol": k, "sez": sez})
	match k:
		0:
			_adegua_settore_pubblico()
		1:
			var m := salario_minimo()
			for aid in s["aziende"]:
				if int(s["aziende"][aid]["sal"]) < m:
					s["aziende"][aid]["sal"] = m
		3, 4:
			pass
	if prima == sez:
		return

func _adegua_settore_pubblico() -> void:
	var obiettivo: int = [9, 6, 3][polx(0)]
	var pub: Array = s["pub"]
	while pub.size() > obiettivo:
		# chiude prima le aziende vuote e meno care
		var scelta := ""
		var bv := 99999
		for aid in pub:
			var v := int(Dati.az(aid)["costo"]) + (1000 if operativa(aid) else 0)
			if v < bv:
				bv = v
				scelta = aid
		_svuota(scelta)
		pub.erase(scelta)
		s["pub_giu"].append(scelta)
		dai_soldi(ST, int(Dati.az(scelta)["costo"]))
		_log("Chiude l'Azienda pubblica %s." % Dati.az(scelta)["n"])
	while pub.size() < obiettivo and not s["pub_giu"].is_empty():
		var aid2: String = s["pub_giu"].pop_front()
		paga(ST, int(Dati.az(aid2)["costo"]))
		pub.append(aid2)
		s["aziende"][aid2]["sal"] = maxi(salario_minimo(), int(s["aziende"][aid2]["sal"]))
		_log("Apre l'Azienda pubblica %s." % Dati.az(aid2)["n"])
		var d := Dati.az(aid2)
		for k2 in [WC, MC]:
			var ws := scegli_lavoratori(k2, d["slot"], true)
			if not ws.is_empty():
				for x in ws.size():
					_metti(ws[x], aid2, x, true)
				break
	for r in ["sal", "ist", "inf"]:
		s["servizi"][r] = mini(int(s["servizi"][r]), capienza_pubblica(r))
	_controlla_aziende()

# ================================================================ elezioni
func _p_elezioni(_p: Dictionary) -> void:
	var ci_sono := false
	for k in 7:
		if s["prop"][k] != null:
			ci_sono = true
	if not ci_sono:
		return
	s["fase"] = "elezioni"
	_log("--- Round %d: elezioni ---" % int(s["round"]))
	_riempi_sacchetto(true)
	for k in range(6, -1, -1):
		if s["prop"][k] != null:
			_spingi({"k": "voto", "pol": k, "fase": "dich", "idx": 0, "imm": false, "cubi": []})

func _p_voto(p: Dictionary) -> void:
	var k: int = p["pol"]
	var pr = s["prop"][k]
	if pr == null:
		return
	var prop: int = pr["c"]
	s["voto"] = p
	if not p.has("pref"):
		p["pref"] = {str(prop): true}
	match str(p["fase"]):
		"dich":
			while int(p["idx"]) < 4:
				var c: int = p["idx"]
				if c == prop or (c == ST and int(G(ST)["inf"]) <= 0):
					p["idx"] = c + 1
					continue
				if not _ha_r(p):
					var ops := [{"t": "Favorevole", "v": true}, {"t": "Contrario", "v": false}]
					_chiedi(p, c, "Legge %d%s (%s) proposta da %s: favorevole o contrario?" % [k + 1, pr["sez"], Dati.POLITICHE[k], nome(prop)], ops, "voto")
					return
				p["pref"][str(c)] = bool(_r(p))
				p["idx"] = c + 1
			p["fase"] = "cubi"
			if p["cubi"].is_empty():
				p["cubi"] = pesca_cubi(5)
			p["fase"] = "inf"
			p["idx"] = 0
			p["spesa"] = {}
			var tutti_uguali := true
			for c2 in p["pref"]:
				if not p["pref"][c2]:
					tutti_uguali = false
			p["unanime"] = tutti_uguali
			_spingi(p)
		"inf":
			if p.get("unanime", false):
				_risolvi_voto(p)
				return
			while int(p["idx"]) < 4:
				var c3: int = p["idx"]
				if not p["pref"].has(str(c3)) or int(G(c3)["inf"]) <= 0:
					p["idx"] = c3 + 1
					continue
				if not _ha_r(p):
					var ops2 := []
					for q in int(G(c3)["inf"]) + 1:
						ops2.append({"t": "Spendi %d Influenza" % q, "v": q})
					var lato := "a favore" if p["pref"][str(c3)] else "contro"
					_chiedi(p, c3, "Cubi pescati: %s. Quanta Influenza spendi %s?" % [_descrivi_cubi(p["cubi"]), lato], ops2, "influenza")
					return
				p["spesa"][str(c3)] = int(_r(p))
				p["idx"] = c3 + 1
			_risolvi_voto(p)

func _descrivi_cubi(cubi: Array) -> String:
	var t := []
	for c in 3:
		var n := cubi.count(c)
		if n > 0:
			t.append("%d %s" % [n, Dati.NOMI_BREVI[Dati.CLASSI[c]]])
	return ", ".join(t) if not t.is_empty() else "nessuno"

func conta_voti(p: Dictionary) -> Array:
	var fav := 0
	var con := 0
	for x in p["cubi"]:
		var pref = p["pref"].get(str(int(x)), null)
		if pref == null:
			continue
		if pref:
			fav += 1
		else:
			con += 1
	for c in p.get("spesa", {}):
		if p["pref"][c]:
			fav += int(p["spesa"][c])
		else:
			con += int(p["spesa"][c])
	return [fav, con]

func _risolvi_voto(p: Dictionary) -> void:
	var k: int = p["pol"]
	var pr: Dictionary = s["prop"][k]
	var prop: int = pr["c"]
	var v := conta_voti(p)
	var passa: bool = p.get("unanime", false) or v[0] >= v[1]
	# influenza spesa sempre scartata
	for c in p.get("spesa", {}):
		G(int(c))["inf"] = int(G(int(c))["inf"]) - int(p["spesa"][c])
	var contribuito := {}
	for x in p["cubi"]:
		var pref = p["pref"].get(str(int(x)), null)
		var vincente: bool = pref != null and pref == passa
		if p.get("unanime", false):
			vincente = true
		if vincente:
			s["riserva"][int(x)] = int(s["riserva"][int(x)]) + 1
			contribuito[str(int(x))] = true
		else:
			s["borsa"][int(x)] = int(s["borsa"][int(x)]) + 1
	for c in p.get("spesa", {}):
		if int(p["spesa"][c]) > 0:
			contribuito[c] = true
	s["prop"][k] = null
	G(prop)["bill"] = int(G(prop)["bill"]) + 1
	s["voto"] = {}
	var esito := {"tipo": "esito", "pol": k, "sez": pr["sez"], "passa": passa, "fav": v[0], "con": v[1], "cubi": p["cubi"], "spesa": p.get("spesa", {}), "pref": p["pref"], "prop": prop}
	_ev(esito)
	s["storico"].append(esito)
	if passa:
		_log("La Legge %d%s PASSA (%d a %d)." % [k + 1, pr["sez"], v[0], v[1]])
		vp(prop, 3, "legge approvata")
		for c in p["pref"]:
			if int(c) != prop and p["pref"][c] and contribuito.has(c):
				vp(int(c), 1, "legge sostenuta")
		_cambia_politica(k, pr["sez"])
	else:
		_log("La Legge %d%s è RESPINTA (%d a %d)." % [k + 1, pr["sez"], v[0], v[1]])

# ================================================================ punteggio e fine
func _p_punteggio(_p: Dictionary) -> void:
	s["fase"] = "punteggio"
	_log("--- Round %d: punteggio ---" % int(s["round"]))
	vp(WC, 2 * sindacati(), "sindacati")
	var piene := 0
	for aid in s["priv_mc"]:
		if piena(aid):
			piene += 1
	if int(G(MC)["prosp"]) < piene:
		prosperita(MC)
	var gc := G(CC)
	gc["cap"] = int(gc["cap"]) + int(gc["rev"])
	gc["rev"] = 0
	var liv := 0
	for k in Dati.RICCHEZZA.size():
		if int(gc["cap"]) >= Dati.RICCHEZZA[k]:
			liv = k + 1
	vp(CC, liv, "ricchezza")
	if liv > int(gc["ricchezza"]):
		vp(CC, 3 * (liv - int(gc["ricchezza"])), "nuovo livello di ricchezza")
		gc["ricchezza"] = liv
	# Stato: penalità degli eventi
	var gs := G(ST)
	for eid in s["eventi_tav"]:
		var e := Dati.evento(eid)
		if e["pen"] is String:
			var ord := [0, 1, 2]
			ord.sort_custom(func(a, b): return int(gs["leg"][a]) > int(gs["leg"][b]))
			legit(ord[0], -1)
			legit(ord[1], -1)
		else:
			for x in e["pen"]:
				legit(Dati.CLASSI.find(x[0]), int(x[1]))
		_log("Evento ignorato: %s." % e["it"])
	s["eventi_tav"] = []
	var l: Array = gs["leg"].duplicate()
	l.sort()
	vp(ST, int(l[0]) + int(l[1]), "legittimità")
	for c in 3:
		gs["leg"][c] = clampi(int(ceil(int(gs["leg"][c]) / 2.0)) + int(gs["tok"][c]), 1, 10)
	vp(ST, agenda_corrispondenze(), "agenda politica")

func agenda_corrispondenze() -> int:
	var ag: Array = Dati.d()["agende"][int(G(ST)["agenda"])]
	var n := 0
	for k in 5:
		if pol(k) == ag[k]:
			n += 1
	return n

func _p_fine_round(_p: Dictionary) -> void:
	if int(s["round"]) >= 5:
		_fine_partita()
		return
	s["round"] = int(s["round"]) + 1
	_spingi({"k": "round"})

func _fine_partita() -> void:
	s["fase"] = "fine"
	_log("--- Fine della partita ---")
	for c in 4:
		var g := G(c)
		if c == CC:
			vp(CC, -5 * int(g["prestiti"]), "prestiti")
		else:
			while int(g["prestiti"]) > 0 and soldi(c) >= 55:
				paga(c, 55)
				g["prestiti"] = int(g["prestiti"]) - 1
			if int(g["prestiti"]) > 0:
				var debito := 55 * int(g["prestiti"])
				var pagabile := (soldi(c) / 5) * 5
				paga(c, mini(pagabile, debito))
				vp(c, -((debito - mini(pagabile, debito)) / 5), "prestiti non pagati")
				g["prestiti"] = 0
	var conta := func(sez: String) -> int:
		var n := 0
		for k in 5:
			if pol(k) == sez:
				n += 1
		return n
	vp(WC, Dati.VP_FINE_WC[conta.call("A")], "politiche socialiste")
	vp(WC, mini(15, soldi(WC) / 10), "denaro")
	vp(MC, Dati.VP_FINE_MC[conta.call("B")], "politiche centriste")
	var gm := G(MC)
	vp(MC, int(gm["mag"]["cibo"]) / 2 + int(gm["mag"]["lus"]) / 3 + int(gm["mag"]["sal"]) / 3 + int(gm["mag"]["ist"]) / 3, "scorte")
	vp(MC, soldi(MC) / 15, "denaro")
	vp(CC, Dati.VP_FINE_CC[conta.call("C")], "politiche neoliberiste")
	var gc := G(CC)
	vp(CC, (int(gc["mag"]["cibo"]) + int(gc["ftz"]["cibo"])) / 2 + (int(gc["mag"]["lus"]) + int(gc["ftz"]["lus"])) / 3 + int(gc["mag"]["sal"]) / 3 + int(gc["mag"]["ist"]) / 3, "scorte")
	vp(ST, soldi(ST) / 30, "tesoreria")
	vp(ST, int(G(ST)["mag"]["cibo"]) / 2 + int(G(ST)["mag"]["lus"]) / 3 + int(s["servizi"]["sal"]) / 3 + int(s["servizi"]["ist"]) / 3 + int(s["servizi"]["inf"]) / 3, "scorte")
	var best := 0
	var bv := -99999
	var ag: Array = Dati.d()["agende"][int(G(ST)["agenda"])]
	for c in 4:
		var v: int = G(c)["vp"]
		var spareggio := 0
		for k in 5:
			var sez: String = ["A", "B", "C", ""][c]
			if c == ST:
				sez = ag[k]
			if pol(k) == sez:
				spareggio += 1
		var tot := v * 1000 + spareggio * 10 + (5 if c == ST else 0)
		if tot > bv:
			bv = tot
			best = c
	s["vincitore"] = best
	s["fine"] = true
	s["attesa"] = {}
	_log("Vince %s con %d PV!" % [nome(best), int(G(best)["vp"])])
	_ev({"tipo": "fine", "g": best})

# ================================================================ effetti delle carte
func _p_legit_carta(p: Dictionary) -> void:
	var cid: String = p["cid"]
	var c := Dati.carta(cid)
	for x in c["leg"]:
		if int(x[2]) == 0:
			legit(Dati.CLASSI.find(x[0]), int(x[1]))

func _p_legit_per(p: Dictionary) -> void:
	legit(int(p["cls"]), int(s.get("cnt", 0)) / int(p["per"]))

func _fx_nome(cid: String) -> String:
	return str(Dati.carta(cid)["fx"]).split(":")[0]

func _fx_arg(cid: String) -> String:
	var f := str(Dati.carta(cid)["fx"]).split(":")
	return f[1] if f.size() > 1 else ""

func _p_fx(p: Dictionary) -> void:
	s["cnt"] = 0
	var cid: String = p["cid"]
	var c: int = p["c"]
	var nm := _fx_nome(cid)
	var arg := _fx_arg(cid)
	# legittimità proporzionale indicata sulla carta
	for x in Dati.carta(cid)["leg"]:
		if int(x[2]) > 0:
			_spingi({"k": "legit_per", "cls": Dati.CLASSI.find(x[0]), "per": int(x[2])})
	_spingi({"k": "fx_" + nm, "c": c, "arg": arg, "cid": cid})

## Verifica approssimativa che l'effetto di una carta si possa giocare.
func fx_possibile(c: int, cid: String) -> bool:
	var nm := _fx_nome(cid)
	var arg := _fx_arg(cid)
	match nm:
		"cubi_pop", "voce_ceto_medio", "campagna_politica", "lobby_protezionista", "gruppi_interesse":
			if int(s["riserva"][c]) <= 0:
				return false
			if nm == "campagna_politica":
				return puo_pagare(c, 15)
			if nm == "lobby_protezionista":
				return _conta_ind(CC, ["agr", "lus"] if pol(5) == "A" else ["agr"]) > 0
			return true
		"fake_news":
			return int(s["borsa"][0]) + int(s["borsa"][1]) + int(s["borsa"][2]) > 0
		"movimento":
			return puo_proporre(c, false, int(arg) - 1)
		"riforme_radicali", "questioni_urgenti", "sondaggio":
			return puo_proporre(c, nm == "riforme_radicali")
		"due_leggi":
			return int(G(c)["bill"]) >= 1 and puo_proporre(c, false)
		"due_leggi_25":
			return puo_pagare(c, 25) and puo_proporre(c, false)
		"reddito_integrativo", "sussidi_disoccupazione", "reddito_integrativo_mc":
			return true
		"bonus_ingaggio", "specializzazione", "assegna_libero":
			return nm == "specializzazione" or not bersagli_assegna(c, 4, true).is_empty()
		"specializzazione_mc", "iniziativa_occupazione":
			return not bersagli_assegna(WC, 3, true, "mc_dip").is_empty() or nm == "specializzazione_mc"
		"incidente":
			return not _opzioni_incidente().is_empty()
		"mezzo_prezzo":
			return int(s["servizi"][arg]) > 0 and (prezzo_pubblico(arg) == 0 or soldi(c) >= 3)
		"compra_inf3":
			return int(s["servizi"]["inf"]) >= 3 and puo_pagare(c, 15)
		"sciopero_generale":
			return not bersagli_sciopero().is_empty()
		"emigrazione":
			return disoccupati(c).size() >= 4
		"edilizia":
			return puo_pagare(c, 10)
		"straordinari_pubblici":
			return not _pubbliche_operative().is_empty()
		"cooperativa":
			return disoccupati(WC).size() >= 3 and int(G(WC)["coop"]) < 2
		"turismo_interno":
			return disponibile(MC, "lus") + disponibile(CC, "lus") + disponibile(ST, "lus") > 0
		"vendi_stato", "vendi_stato9":
			return scorta_vendibile(c, arg) > 0 and capienza_pubblica(arg) > int(s["servizi"][arg])
		"appalti":
			return scorta_vendibile(c, "lus") > 0 and capienza_pubblica("lus") > int(G(ST)["mag"]["lus"])
		"sussidio_export", "crisi_alimentare", "marchio_globale":
			return not transazioni_export(c, {}).is_empty() or (nm == "crisi_alimentare" and scorta_vendibile(c, "cibo") > 0) or (nm == "marchio_globale" and scorta_vendibile(c, "lus") > 0)
		"costruisci_gratis", "terra_opportunita", "industrializzazione", "investimento", "investimento10", "espansione", "impresa_crescita":
			if posti_liberi(c) <= 0:
				return false
			if nm == "terra_opportunita":
				for aid in G(c)["mercato"]:
					if not costruibili(c, 0, [aid], false, Dati.az(aid)["slot"][0]).is_empty():
						return true
				return false
			if nm == "investimento" or nm == "investimento10":
				return true
			if nm == "impresa_crescita":
				return true
			return not costruibili(c, 0, [], nm != "espansione" and nm != "investimento").is_empty()
		"analisi_estero", "analisi_estero_cc":
			return true
		"consumi":
			return pop_compra_possibile(c)
		"parco":
			return puo_pagare(c, 6 * popolazione(c))
		"sussidio_import":
			return true
		"sussidio_occupazione":
			for aid in aziende_di(MC):
				if az(aid)["dip"] != "":
					return true
			return false
		"offshore":
			return int(G(CC)["rev"]) >= 2
		"partner_estero":
			return not s["accordi_tav"].is_empty()
		"contributi_imprese", "contributi_st":
			return true
		"strategia_uscita":
			return not vendibili(CC, true).is_empty()
		"progresso":
			return puo_pagare(CC, 20) and not _aziende_macchinario().is_empty()
		"isola":
			return puo_pagare(CC, 50)
		"turno_extra_cc", "straordinari_st":
			return not bersagli_turno_extra(c).is_empty()
		"iniziativa_occupazione_cc", "iniziativa_occupazione_st":
			for aid in aziende_di(c):
				if not operativa(aid) and not Dati.az(aid)["auto"]:
					for k in [WC, MC]:
						if not scegli_lavoratori(k, Dati.az(aid)["slot"], true).is_empty():
							return true
			return false
		"salari_competitivi":
			return not _opzioni_salari_competitivi().is_empty()
		"reclutamento_estero":
			if not puo_pagare(CC, 10):
				return false
			for aid in s["priv_cc"]:
				if not operativa(aid):
					return true
			return false
		"emergenza":
			var n := 0
			for k in 7:
				if s["prop"][k] != null:
					n += 1
			return n >= 3 and n < 7
		"iva":
			return true
		"investimenti_esteri":
			return int(G(ST)["inf"]) >= 2
		"rappresentanza":
			return int(G(ST)["inf"]) >= 1
		"nazionalizzazione":
			return not _opzioni_nazionalizzazione().is_empty()
		"privatizzazione":
			for aid in s["pub"]:
				if operativa(aid) and posti_liberi(CC) > 0:
					return true
			return false
		"risposta_immediata":
			return not eventi_eseguibili().is_empty()
		"cambio_priorita", "alta_priorita":
			return not s["mazzo_ev"].is_empty() or not eventi_eseguibili().is_empty()
		"turismo_estero":
			return int(s["servizi"][arg]) > 0
		"censura":
			return true
		"programma":
			return true
	return true

func _conta_ind(c: int, inds: Array) -> int:
	var n := 0
	for aid in aziende_di(c):
		if Dati.az(aid)["ind"] in inds:
			n += 1
	return n

func _pubbliche_operative() -> Array:
	var o := []
	for aid in s["pub"]:
		if operativa(aid):
			o.append(aid)
	return o

func _aziende_macchinario() -> Array:
	var o := []
	for aid in s["priv_cc"]:
		if int(Dati.az(aid)["mac"]) > 0 and not az(aid)["mac"]:
			o.append(aid)
	return o

# ---------------------------------------------------------------- effetti: voti e leggi
func _p_fx_cubi_pop(p: Dictionary) -> void:
	aggiungi_cubi(p["c"], popolazione(p["c"]))

func _p_fx_voce_ceto_medio(p: Dictionary) -> void:
	var az_set := {}
	for wid in lavoratori(MC):
		var loc: String = lav(wid)["loc"]
		if loc in s["priv_cc"] or loc in s["pub"]:
			az_set[loc] = true
	aggiungi_cubi(MC, 2 + az_set.size())

func _p_fx_gruppi_interesse(p: Dictionary) -> void:
	var c: int = p["c"]
	var trovati := 0
	var rivelati := []
	while trovati < 3:
		var x := pesca_cubi(1)
		if x.is_empty():
			break
		rivelati.append(x[0])
		if int(x[0]) != c:
			trovati += 1
	var sostituiti := 0
	for x in rivelati:
		if int(x) != c and sostituiti < int(s["riserva"][c]):
			s["riserva"][int(x)] = int(s["riserva"][int(x)]) + 1
			s["riserva"][c] = int(s["riserva"][c]) - 1
			s["borsa"][c] = int(s["borsa"][c]) + 1
			sostituiti += 1
		else:
			s["borsa"][int(x)] = int(s["borsa"][int(x)]) + 1
	_log("%s sostituisce %d cubi di altre classi con i propri." % [nome(c), sostituiti])

func _p_fx_fake_news(p: Dictionary) -> void:
	var c: int = p["c"]
	if not p.has("cubi"):
		p["cubi"] = pesca_cubi(6)
		p["tolti"] = 0
	var cubi: Array = p["cubi"]
	if int(p["tolti"]) < 4 and not cubi.is_empty():
		if not _ha_r(p):
			var ops := [{"t": "Basta, rimetti gli altri", "v": -1}]
			for k in 3:
				if k in cubi:
					ops.append({"t": "Togli un cubo %s" % Dati.NOMI_BREVI[Dati.CLASSI[k]], "v": k})
			_chiedi(p, c, "Fake news: cubi pescati %s. Quali togli? (ancora %d)" % [_descrivi_cubi(cubi), 4 - int(p["tolti"])], ops, "fake")
			return
		var k2 := int(_r(p))
		if k2 >= 0:
			cubi.erase(k2)
			s["riserva"][k2] = int(s["riserva"][k2]) + 1
			p["tolti"] = int(p["tolti"]) + 1
			_spingi(p)
			return
	for x in cubi:
		s["borsa"][int(x)] = int(s["borsa"][int(x)]) + 1

func _p_fx_movimento(p: Dictionary) -> void:
	_spingi({"k": "a_proponi", "c": p["c"], "pol": int(p["arg"]) - 1})
	aggiungi_cubi(p["c"], 2)

func _p_fx_riforme_radicali(p: Dictionary) -> void:
	_spingi({"k": "a_proponi", "c": p["c"], "radicale": true, "no_immediato": true})

func _p_fx_questioni_urgenti(p: Dictionary) -> void:
	_spingi({"k": "a_proponi", "c": p["c"], "voto_gratis": true})

func _p_fx_due_leggi(p: Dictionary) -> void:
	_spingi({"k": "a_proponi", "c": p["c"]})
	_spingi({"k": "a_proponi", "c": p["c"]})

func _p_fx_due_leggi_25(p: Dictionary) -> void:
	paga(p["c"], 25)
	_p_fx_due_leggi(p)

func _p_fx_sondaggio(p: Dictionary) -> void:
	var cubi := pesca_cubi(5)
	_log("Sondaggio: cubi rivelati %s." % _descrivi_cubi(cubi))
	_spingi({"k": "a_proponi", "c": p["c"], "voto_gratis": true, "cubi": cubi})

func _p_fx_emergenza(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		for k in 7:
			if s["prop"][k] == null:
				for x in sezioni_proponibili(k, false):
					ops.append({"t": "%d. %s: %s -> %s" % [k + 1, Dati.POLITICHE[k], pol(k), x], "v": [k, x]})
		_chiedi(p, ST, "Stato d'emergenza: quale Politica cambi?", ops, "emergenza")
		return
	var v: Array = _r(p)
	_cambia_politica(int(v[0]), str(v[1]))

# ---------------------------------------------------------------- effetti: denaro dallo Stato e acquisti
func _p_fx_reddito_integrativo(p: Dictionary) -> void:
	var n := occupati(WC).size()
	trasferisci(ST, WC, n)
	s["cnt"] = n
	_spingi({"k": "a_compra", "c": WC})

func _p_fx_reddito_integrativo_mc(p: Dictionary) -> void:
	var n := 0
	for wid in lavoratori(MC):
		var loc: String = lav(wid)["loc"]
		if loc in s["priv_cc"] or loc in s["pub"]:
			n += 1
	trasferisci(ST, MC, 2 * n)
	s["cnt"] = n
	_spingi({"k": "a_compra", "c": MC})

func _p_fx_sussidi_disoccupazione(p: Dictionary) -> void:
	var n := disoccupati(WC).size()
	trasferisci(ST, WC, 5 * n)
	s["cnt"] = n
	_spingi({"k": "a_compra", "c": WC, "solo_fonte": [ST], "max_fonti": 1})

func _p_fx_mezzo_prezzo(p: Dictionary) -> void:
	_spingi({"k": "a_compra", "c": p["c"], "ris": p["arg"], "solo_fonte": [ST], "max_fonti": 1, "frazione": 0.5})

func _p_fx_compra_inf3(p: Dictionary) -> void:
	var c: int = p["c"]
	paga(c, 15)
	dai_soldi(ST, 15)
	s["servizi"]["inf"] = int(s["servizi"]["inf"]) - 3
	G(c)["inf"] = int(G(c)["inf"]) + 3

func _p_fx_turismo_interno(p: Dictionary) -> void:
	_spingi({"k": "a_compra", "c": p["c"], "ris": "lus", "solo_fonte": [MC, CC, ST], "max_fonti": 1, "stato_meta": true, "frazione": 0.5})

func _p_fx_consumi(p: Dictionary) -> void:
	var c: int = p["c"]
	if not _ha_r(p):
		_chiedi(p, c, "Consumi personali:", [{"t": "Da più fonti, fino alla Popolazione da ciascuna", "v": "molte"}, {"t": "Da una sola fonte, fino al doppio della Popolazione", "v": "doppio"}], "consumi")
		return
	if str(_r(p)) == "molte":
		_spingi({"k": "a_compra", "c": c, "max_fonti": 5})
	else:
		_spingi({"k": "a_compra", "c": c, "max_fonti": 1, "limite": 2 * popolazione(c)})

func _p_fx_sussidio_import(p: Dictionary) -> void:
	_spingi({"k": "a_compra", "c": p["c"], "risorse": ["cibo", "lus"], "solo_fonte": [9], "max_fonti": 1, "no_dazi": true})

func _p_fx_parco(p: Dictionary) -> void:
	paga(MC, 6 * popolazione(MC))
	prosperita(MC)

func _p_fx_edilizia(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		if puo_pagare(WC, 20):
			ops.append({"t": "Paga 20 alla Classe Capitalista: +5 PV", "v": CC})
		ops.append({"t": "Paga 10 alla Classe Media: +3 PV", "v": MC})
		_chiedi(p, WC, "Edilizia popolare:", ops, "edilizia")
		return
	var k := int(_r(p))
	trasferisci(WC, k, 20 if k == CC else 10)
	vp(WC, 5 if k == CC else 3, "edilizia popolare")

func _p_fx_emigrazione(p: Dictionary) -> void:
	var c: int = p["c"]
	var tolti := int(p.get("tolti", 0))
	if tolti >= 2 or (tolti == 0 and disoccupati(c).size() < 4) or disoccupati(c).is_empty():
		return
	if not _ha_r(p):
		var ops := [{"t": "Basta così", "v": ""}]
		var visti := {}
		for wid in disoccupati(c):
			var sk: String = lav(wid)["sk"]
			if visti.has(sk):
				continue
			visti[sk] = true
			ops.append({"t": "Emigra un lavoratore %s (+%d)" % [Dati.NOMI_IND[sk], 5 if sk == "u" else 10], "v": wid})
		_chiedi(p, c, "Chi emigra? (fino a 2)", ops, "emigra")
		return
	var wid2: String = str(_r(p))
	if wid2 == "":
		return
	dai_soldi(c, 5 if lav(wid2)["sk"] == "u" else 10)
	s["lav"].erase(wid2)
	p["tolti"] = int(p.get("tolti", 0)) + 1
	_spingi(p)

# ---------------------------------------------------------------- effetti: lavoratori
func _p_fx_bonus_ingaggio(p: Dictionary) -> void:
	_spingi({"k": "assegna_n", "c": WC, "max": 4, "solo_dis": true, "soldi_padrone": 4})

func _p_fx_assegna_libero(p: Dictionary) -> void:
	_spingi({"k": "assegna_n", "c": p["c"], "max": 99, "solo_dis": pol(1) != "C"})

func _p_fx_specializzazione(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		for ind in Dati.INDUSTRIE:
			ops.append({"t": "Lavoratore qualificato: %s" % Dati.NOMI_IND[ind], "v": ind})
		_chiedi(p, p["c"], "Quale lavoratore qualificato aggiungi?", ops, "abilita")
		return
	_nuovo_lav(WC, str(_r(p)))
	if int(p["c"]) == WC:
		_spingi({"k": "assegna_n", "c": WC, "max": 3})
	else:
		_spingi({"k": "assegna_n", "c": WC, "max": 3, "solo_dis": true, "filtro": "mc_dip", "chi": MC})

func _p_fx_specializzazione_mc(p: Dictionary) -> void:
	_p_fx_specializzazione(p)

func _p_fx_iniziativa_occupazione(p: Dictionary) -> void:
	_spingi({"k": "assegna_n", "c": WC, "max": 3, "solo_dis": true, "filtro": "mc_dip", "chi": MC, "soldi_stato": 5})

func _p_fx_iniziativa_occupazione_cc(p: Dictionary) -> void:
	_iniziativa(p, 5)

func _p_fx_iniziativa_occupazione_st(p: Dictionary) -> void:
	_iniziativa(p, 0)

func _iniziativa(p: Dictionary, soldi_w: int) -> void:
	var c: int = p["c"]
	if not _ha_r(p):
		var ops := []
		for aid in aziende_di(c):
			if operativa(aid) or Dati.az(aid)["auto"]:
				continue
			for k in [WC, MC]:
				var ws := scegli_lavoratori(k, Dati.az(aid)["slot"], true)
				if not ws.is_empty():
					ops.append({"t": "%s con lavoratori della %s" % [Dati.az(aid)["n"], nome(k)], "v": {"aid": aid, "dip": false, "w": ws, "k": k}})
		if ops.is_empty():
			return
		_chiedi(p, c, "Quale Azienda riapri con i disoccupati?", ops, "assegna")
		return
	var v: Dictionary = _r(p)
	var n := _esegui_assegna(int(v["k"]), v)
	if soldi_w > 0:
		trasferisci(ST, c, n * soldi_w)
	_verifica_manifestazione()

func _p_fx_cooperativa(p: Dictionary) -> void:
	var k: int = int(G(WC)["coop"]) + 1
	G(WC)["coop"] = k
	var aid := "coop%d" % k
	_crea_azienda(aid, "WC", 1)
	var dis := disoccupati(WC)
	dis.sort_custom(func(a, b): return int(lav(a)["sk"] != "u") < int(lav(b)["sk"] != "u"))
	for x in 3:
		_metti(dis[x], aid, x, true)
	_controlla_aziende()
	_log("La Classe Operaia fonda una Cooperativa agricola.")

func _p_fx_sciopero_generale(p: Dictionary) -> void:
	_spingi({"k": "a_sciopero", "c": WC, "max": 2 + sindacati()})

func _opzioni_incidente() -> Array:
	var o := []
	for i in [MC, CC, ST]:
		for ind in Dati.INDUSTRIE:
			var n := 0
			for aid in aziende_di(i):
				if Dati.az(aid)["ind"] != ind:
					continue
				var con := false
				for wid in lavoratori_in(aid):
					if int(lav(wid)["c"]) == WC:
						con = true
				if con:
					n += 1
			if n > 0:
				o.append({"t": "%s, %s: %d" % [nome(i), Dati.NOMI_IND[ind], 8 * n], "v": [i, 8 * n]})
	return o

func _p_fx_incidente(p: Dictionary) -> void:
	if not _ha_r(p):
		_chiedi(p, WC, "Incidente sul lavoro: chi paga?", _opzioni_incidente(), "incidente")
		return
	var v: Array = _r(p)
	trasferisci(int(v[0]), WC, int(v[1]))

func _p_fx_straordinari_pubblici(p: Dictionary) -> void:
	var c: int = p["c"]
	if not _ha_r(p):
		var ops := []
		for aid in _pubbliche_operative():
			ops.append({"t": "%s (+%d %s)" % [Dati.az(aid)["n"], produzione(aid), Dati.NOMI_RIS[Dati.RIS_IND[Dati.az(aid)["ind"]]]], "v": aid})
		_chiedi(p, c, "Quale Azienda pubblica fa gli straordinari?", ops, "straordinari")
		return
	var aid2: String = str(_r(p))
	var sc_prima: bool = az(aid2)["sc"]
	az(aid2)["sc"] = false
	_produci(aid2, true)
	az(aid2)["sc"] = sc_prima
	var r: String = Dati.RIS_IND[Dati.az(aid2)["ind"]]
	_spingi({"k": "a_compra", "c": c, "ris": r, "solo_fonte": [ST], "max_fonti": 1})

func _p_fx_straordinari_st(p: Dictionary) -> void:
	_spingi({"k": "a_turno_extra", "c": ST})

func _p_fx_turno_extra_cc(p: Dictionary) -> void:
	_spingi({"k": "a_turno_extra", "c": CC})

func _p_fx_sussidio_occupazione(p: Dictionary) -> void:
	var lista := []
	for aid in aziende_di(MC):
		if az(aid)["dip"] != "":
			lista.append(aid)
	trasferisci(ST, MC, 5 * lista.size())
	s["cnt"] = lista.size()
	_spingi({"k": "a_turno_extra", "c": MC, "solo_aziende": lista, "facoltativo": true})

# ---------------------------------------------------------------- effetti: vendite allo Stato e all'estero
func _p_fx_vendi_stato(p: Dictionary) -> void:
	_vendi_allo_stato(p, 6)

func _p_fx_vendi_stato9(p: Dictionary) -> void:
	_vendi_allo_stato(p, 9)

func _p_fx_appalti(p: Dictionary) -> void:
	p["arg"] = "lus"
	_vendi_allo_stato(p, 6)
	if not s["attesa"].is_empty():
		return
	G(CC)["inf"] = int(G(CC)["inf"]) + 1

func _vendi_allo_stato(p: Dictionary, massimo: int) -> void:
	var c: int = p["c"]
	var r: String = p["arg"]
	var spazio := capienza_pubblica(r) - (int(s["servizi"][r]) if r in ["sal", "ist", "inf"] else int(G(ST)["mag"][r]))
	var m := mini(massimo, mini(scorta_vendibile(c, r), spazio))
	if m <= 0:
		return
	if not _ha_r(p):
		var ops := []
		for q in range(m, 0, -1):
			ops.append({"t": "Vendi %d %s (+%d)" % [q, Dati.NOMI_RIS[r], 10 * q], "v": q})
		_chiedi(p, c, "Quante %s vendi allo Stato?" % Dati.NOMI_RIS[r], ops, "quantita")
		return
	var q2 := int(_r(p))
	_usa_scorta(c, r, q2)
	immagazzina(ST, r, q2)
	trasferisci(ST, c, 10 * q2)
	s["cnt"] = q2
	_log("%s vende %d %s allo Stato." % [nome(c), q2, Dati.NOMI_RIS[r]])

func _p_fx_sussidio_export(p: Dictionary) -> void:
	_spingi({"k": "a_estero", "c": MC, "extra_stato": 5})

func _p_fx_crisi_alimentare(p: Dictionary) -> void:
	_spingi({"k": "vendita_fissa", "c": CC, "ris": "cibo", "max": 4, "prezzo": 15})
	_spingi({"k": "a_estero", "c": CC})

func _p_fx_marchio_globale(p: Dictionary) -> void:
	_spingi({"k": "vendita_fissa", "c": CC, "ris": "lus", "max": 6, "prezzo": 10})
	_spingi({"k": "a_estero", "c": CC})

func _p_vendita_fissa(p: Dictionary) -> void:
	var c: int = p["c"]
	var r: String = p["ris"]
	var m := mini(int(p["max"]), scorta_vendibile(c, r))
	if m <= 0:
		return
	if not _ha_r(p):
		var ops := [{"t": "Non vendere", "v": 0}]
		for q in range(m, 0, -1):
			ops.append({"t": "Vendi %d %s a %d" % [q, Dati.NOMI_RIS[r], int(p["prezzo"])], "v": q})
		_chiedi(p, c, "Vendita extra al Mercato Estero:", ops, "quantita")
		return
	var q2 := int(_r(p))
	_usa_scorta(c, r, q2)
	dai_soldi(c, q2 * int(p["prezzo"]))

func _p_fx_analisi_estero(p: Dictionary) -> void:
	if s["mazzo_exp"].is_empty():
		_spingi({"k": "a_estero", "c": MC, "ripeti": 2})
		return
	var nuova: int = s["mazzo_exp"].back()
	if not _ha_r(p):
		var ops := [{"t": "Tieni la carta Export attuale", "v": false}, {"t": "Usa la nuova carta Export", "v": true}]
		_chiedi(p, MC, "Analisi del mercato estero: confronta le carte Export.", ops, "export_scelta")
		p["nuova"] = nuova
		return
	s["mazzo_exp"].pop_back()
	if bool(_r(p)):
		s["export"] = nuova
	_spingi({"k": "a_estero", "c": MC, "ripeti": 2})

func _p_fx_analisi_estero_cc(p: Dictionary) -> void:
	if s["mazzo_exp"].size() < 2:
		_spingi({"k": "a_estero", "c": CC})
		return
	var a: int = s["mazzo_exp"][-1]
	var b: int = s["mazzo_exp"][-2]
	if not _ha_r(p):
		_chiedi(p, CC, "Analisi del mercato estero: quale carta Export usi?", [
			{"t": "Tieni quella attuale", "v": -1}, {"t": "Prima carta rivelata", "v": a}, {"t": "Seconda carta rivelata", "v": b}], "export_scelta")
		return
	s["mazzo_exp"].pop_back()
	s["mazzo_exp"].pop_back()
	var sc := int(_r(p))
	if sc >= 0:
		s["export"] = sc
	_spingi({"k": "a_estero", "c": CC})

func _p_fx_partner_estero(p: Dictionary) -> void:
	_spingi({"k": "a_estero", "c": CC, "solo": ["cibo", "lus"]})
	_spingi({"k": "a_accordo", "c": CC})

func _p_fx_turismo_estero(p: Dictionary) -> void:
	var r: String = p["arg"]
	var m := mini(8, int(s["servizi"][r]))
	if not _ha_r(p):
		var ops := []
		for q in range(m, 0, -1):
			ops.append({"t": "Vendi %d %s (+%d)" % [q, Dati.NOMI_RIS[r], q * prezzo_pubblico(r)], "v": q})
		_chiedi(p, ST, "Quante ne vendi all'estero?", ops, "quantita")
		return
	var q2 := int(_r(p))
	s["servizi"][r] = int(s["servizi"][r]) - q2
	dai_soldi(ST, q2 * prezzo_pubblico(r))

# ---------------------------------------------------------------- effetti: costruzioni
func _p_fx_costruisci_gratis(p: Dictionary) -> void:
	_spingi({"k": "a_costruisci", "c": MC, "paga_stato": true})

func _p_fx_terra_opportunita(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		for aid in G(MC)["mercato"]:
			var sk: String = Dati.az(aid)["slot"][0]
			if not costruibili(MC, 0, [aid], false, sk).is_empty():
				ops.append({"t": "%s (lavoratore %s dalla scorta, costo %d)" % [Dati.az(aid)["n"], Dati.NOMI_IND[sk], int(Dati.az(aid)["costo"])], "v": aid})
		if ops.is_empty():
			return
		_chiedi(p, MC, "Quale Azienda costruisci?", ops, "costruisci")
		return
	var aid2: String = str(_r(p))
	_spingi({"k": "a_costruisci", "c": MC, "aid": aid2, "mc_extra": Dati.az(aid2)["slot"][0]})

func _investimento(p: Dictionary, delta: int) -> void:
	var c: int = p["c"]
	if not _ha_r(p):
		var ops := []
		if not costruibili(c, delta).is_empty():
			ops.append({"t": "Costruisci dal Mercato pagando %d in meno" % delta, "v": "mercato"})
		if not costruibili(c, -delta, G(c)["mazzo_az"]).is_empty():
			ops.append({"t": "Cerca nel mazzo Aziende pagando %d in più" % delta, "v": "mazzo"})
		if ops.is_empty():
			return
		_chiedi(p, c, "Opportunità di investimento:", ops, "investimento")
		return
	if str(_r(p)) == "mercato":
		_spingi({"k": "a_costruisci", "c": c, "sconto": delta})
	else:
		_spingi({"k": "rimescola_aziende", "c": c})
		_spingi({"k": "a_costruisci", "c": c, "sconto": -delta, "lista": G(c)["mazzo_az"].duplicate()})

func _p_rimescola_aziende(p: Dictionary) -> void:
	_mescola(G(p["c"])["mazzo_az"])

func _p_fx_investimento(p: Dictionary) -> void:
	_investimento(p, 8)

func _p_fx_investimento10(p: Dictionary) -> void:
	_investimento(p, 10)

func _p_fx_impresa_crescita(p: Dictionary) -> void:
	var c: int = p["c"]
	if not p.has("ris"):
		if not _ha_r(p):
			var ops := []
			for r in Dati.RISORSE:
				if not G(c)["extra"][r]:
					ops.append({"t": "Magazzino per %s" % Dati.NOMI_RIS[r], "v": r})
			if ops.is_empty():
				p["ris"] = ""
			else:
				_chiedi(p, c, "Impresa in crescita: magazzino gratuito per quale risorsa?", ops, "magazzino")
				return
		else:
			p["ris"] = str(_r(p))
			G(c)["extra"][p["ris"]] = true
	var ops2 := costruibili(c, 0)
	var ops3 := []
	for op in ops2:
		var d := Dati.az(op["v"])
		var sconto := 4 if Dati.RIS_IND[d["ind"]] == p["ris"] else 0
		if puo_pagare(c, int(d["costo"]) - sconto):
			ops3.append(op)
	if ops3.is_empty():
		return
	if not _ha_r(p):
		ops3.push_front({"t": "Non costruire", "v": ""})
		_chiedi(p, c, "Costruisci un'Azienda? (4 in meno se produce %s)" % Dati.NOMI_RIS.get(p["ris"], "-"), ops3, "costruisci")
		return
	var aid: String = str(_r(p))
	if aid == "":
		return
	var sc := 4 if Dati.RIS_IND[Dati.az(aid)["ind"]] == p["ris"] else 0
	_spingi({"k": "a_costruisci", "c": c, "aid": aid, "sconto": sc})

func _p_fx_espansione(p: Dictionary) -> void:
	_spingi({"k": "nuove_aziende", "c": CC, "n": 2})
	_spingi({"k": "a_costruisci", "c": CC})
	_spingi({"k": "a_costruisci", "c": CC})

func _p_nuove_aziende(p: Dictionary) -> void:
	for k in int(p["n"]):
		if not G(p["c"])["mazzo_az"].is_empty():
			G(p["c"])["mercato"].append(G(p["c"])["mazzo_az"].pop_back())

func _p_fx_industrializzazione(p: Dictionary) -> void:
	_spingi({"k": "a_costruisci", "c": CC, "stato_meta": true, "filtro_ind": ["agr", "lus"]})

# ---------------------------------------------------------------- effetti: Classe Capitalista
func _p_fx_campagna_politica(p: Dictionary) -> void:
	paga(CC, 15)
	aggiungi_cubi(CC, 6)

func _p_fx_lobby_protezionista(p: Dictionary) -> void:
	aggiungi_cubi(CC, 2 * _conta_ind(CC, ["agr", "lus"] if pol(5) == "A" else ["agr"]))

func _p_fx_offshore(p: Dictionary) -> void:
	var m: int = int(G(CC)["rev"]) / 2
	G(CC)["rev"] = int(G(CC)["rev"]) - m
	G(CC)["cap"] = int(G(CC)["cap"]) + m
	_log("La Classe Capitalista sposta %d nel Capitale." % m)

func _p_fx_contributi_imprese(p: Dictionary) -> void:
	var n := aziende_di(CC).size()
	trasferisci(ST, CC, 5 * n)
	s["cnt"] = n

func _p_fx_strategia_uscita(p: Dictionary) -> void:
	_spingi({"k": "a_vendi_az", "c": CC, "non_auto": true, "molt": 2})

func _p_fx_progresso(p: Dictionary) -> void:
	var lista := _aziende_macchinario()
	if not p.has("n"):
		if not _ha_r(p):
			var ops := [{"t": "Paga 20 per 1 Macchinario", "v": 1}]
			if puo_pagare(CC, 45) and lista.size() >= 2:
				ops.append({"t": "Paga 45 per 2 Macchinari", "v": 2})
			_chiedi(p, CC, "Progresso tecnologico:", ops, "progresso")
			return
		p["n"] = int(_r(p))
		paga(CC, 20 if int(p["n"]) == 1 else 45)
	if int(p["n"]) <= 0 or lista.is_empty():
		return
	if not _ha_r(p):
		var ops2 := []
		for aid in lista:
			ops2.append({"t": "%s (+%d)" % [Dati.az(aid)["n"], int(Dati.az(aid)["mac"])], "v": aid})
		_chiedi(p, CC, "Su quale Azienda metti il Macchinario?", ops2, "macchinario")
		return
	az(str(_r(p)))["mac"] = true
	p["n"] = int(p["n"]) - 1
	_spingi(p)

func _p_fx_isola(p: Dictionary) -> void:
	paga(CC, 50, true)
	dai_soldi(ST, 50)
	vp(CC, 7, "isola privata")

func _opzioni_salari_competitivi() -> Array:
	var o := []
	for aid in s["priv_cc"]:
		var d := Dati.az(aid)
		if operativa(aid) or d["auto"]:
			continue
		for pid in s["pub"]:
			var dp := Dati.az(pid)
			if not operativa(pid) or dp["ind"] != d["ind"] or dp["slot"].size() != d["slot"].size() or impegnata(pid):
				continue
			o.append({"t": "%s prende i lavoratori di %s" % [d["n"], dp["n"]], "v": [aid, pid]})
	return o

func _p_fx_salari_competitivi(p: Dictionary) -> void:
	if not _ha_r(p):
		_chiedi(p, CC, "Salari competitivi:", _opzioni_salari_competitivi(), "salari_comp")
		return
	var v: Array = _r(p)
	var aid: String = v[0]
	var pid: String = v[1]
	az(aid)["sal"] = 3
	var ws := lavoratori_in(pid)
	var k := 0
	for wid in ws:
		_metti(wid, aid, k, true)
		k += 1
	_controlla_aziende()

func _p_fx_reclutamento_estero(p: Dictionary) -> void:
	if not p.has("aid"):
		if not _ha_r(p):
			var ops := []
			for aid in s["priv_cc"]:
				if not operativa(aid) and not Dati.az(aid)["auto"]:
					ops.append({"t": Dati.az(aid)["n"], "v": aid})
			_chiedi(p, CC, "Reclutamento estero: quale Azienda?", ops, "reclutamento")
			return
		p["aid"] = str(_r(p))
	if not _ha_r(p):
		_chiedi(p, CC, "Lavoratori di quale classe?", [{"t": "Classe Operaia", "v": WC}, {"t": "Classe Media", "v": MC}], "classe")
		return
	var k := int(_r(p))
	paga(CC, 10)
	var aid2: String = p["aid"]
	var d := Dati.az(aid2)
	for x in d["slot"].size():
		_metti(_nuovo_lav(k, d["slot"][x]), aid2, x, true)
	_log("Arrivano %d lavoratori dall'estero per %s." % [d["slot"].size(), d["n"]])

# ---------------------------------------------------------------- effetti: Stato
## Mette oggetti nell'area Benefici di una classe (sostituisce quelli precedenti).
func fornisci(c: int, cosa: Dictionary) -> void:
	var b: Dictionary = _ben_vuoto() if not s.get("ben_turno", {}).has(str(c)) else G(ST)["ben"][c]
	for k in cosa:
		b[k] = int(b[k]) + int(cosa[k])
	G(ST)["ben"][c] = b
	if not s.has("ben_turno"):
		s["ben_turno"] = {}
	s["ben_turno"][str(c)] = true
	_log("Lo Stato fornisce benefici a %s." % nome(c))
	_ev({"tipo": "benefici", "c": c})

## Costo per lo Stato di procurarsi n risorse r da fornire alla classe dest (dalle scorte, poi comprando).
func costo_procurare(r: String, n: int, dest: int) -> int:
	var ho := disponibile(ST, r) if r != "inf" else int(s["servizi"]["inf"])
	if ho >= n:
		return 0
	var serve := n - ho
	var costo := 0
	var offerte := []
	for i in [MC, CC]:
		if i == dest or r == "inf":
			continue
		var q := disponibile(i, r)
		if q > 0:
			offerte.append([prezzo(i, r), q])
	if r in ["cibo", "lus"]:
		offerte.append([prezzo_estero(r), 999])
	offerte.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	for o in offerte:
		var q2 := mini(serve, int(o[1]))
		costo += q2 * int(o[0])
		serve -= q2
		if serve <= 0:
			break
	return costo if serve <= 0 else 99999

func procura(r: String, n: int, dest: int) -> void:
	var ho := disponibile(ST, r)
	var dal_mio := mini(ho, n)
	_togli_ris(ST, r, dal_mio)
	var serve := n - dal_mio
	while serve > 0:
		var best := -1
		var bp := 99999
		for i in [MC, CC]:
			if i == dest or disponibile(i, r) <= 0:
				continue
			if prezzo(i, r) < bp:
				bp = prezzo(i, r)
				best = i
		if r in ["cibo", "lus"] and prezzo_estero(r) < bp:
			best = 9
			bp = prezzo_estero(r)
		if best < 0:
			break
		var q := serve if best == 9 else mini(serve, disponibile(best, r))
		paga(ST, bp * q)
		if best != 9:
			dai_soldi(best, bp * q)
			_togli_ris(best, r, q)
		serve -= q

func _scegli_classe(p: Dictionary, testo: String, classi: Array) -> int:
	if _ha_r(p):
		return int(_r(p))
	var ops := []
	for c in classi:
		ops.append({"t": "%s (Legittimità %d)" % [nome(c), int(G(ST)["leg"][c])], "v": c})
	_chiedi(p, ST, testo, ops, "classe")
	return -1

func _p_fx_iva(p: Dictionary) -> void:
	if not p.has("pagato"):
		for c in 3:
			trasferisci(c, ST, 15)
		p["pagato"] = true
		p["n"] = 0
	if int(p["n"]) >= 2:
		return
	var classi := []
	for c in 3:
		if int(G(ST)["leg"][c]) > 1 and not c in p.get("fatte", []):
			classi.append(c)
	if classi.is_empty():
		return
	var c2 := _scegli_classe(p, "Aumento dell'IVA: a quale classe togli 1 Legittimità?", classi)
	if c2 < 0:
		return
	legit(c2, -1)
	var f: Array = p.get("fatte", [])
	f.append(c2)
	p["fatte"] = f
	p["n"] = int(p["n"]) + 1
	_spingi(p)

func _p_fx_turismo(p: Dictionary) -> void:
	dai_soldi(ST, 15)
	for x in str(p["arg"]).split(","):
		dai_soldi(Dati.CLASSI.find(x), 15)

func _p_fx_sostegno_occupazione(p: Dictionary) -> void:
	paga(ST, 30)
	fornisci(WC, {"soldi": 15})
	fornisci(MC, {"soldi": 15})

func _p_fx_geopolitica(p: Dictionary) -> void:
	dai_soldi(ST, [15, 30, 45][polx(5)])

func _p_fx_investimenti_esteri(p: Dictionary) -> void:
	G(ST)["inf"] = int(G(ST)["inf"]) - 2
	dai_soldi(ST, 40)

func _p_fx_reddito_integrativo_st(p: Dictionary) -> void:
	var c := _scegli_classe(p, "A quale classe dai 1 per ogni lavoratore occupato?", [WC, MC])
	if c < 0:
		return
	var n := occupati(c).size()
	paga(ST, n)
	fornisci(c, {"soldi": n})
	legit(c, n / 10)

func _p_fx_programma(p: Dictionary) -> void:
	var r: String = p["arg"]
	var c := _scegli_classe(p, "A quale classe fornisci %s?" % Dati.NOMI_RIS[r], [WC, MC])
	if c < 0:
		return
	var n := popolazione(c)
	procura(r, n, c)
	fornisci(c, {r: n})
	gettone(c)

func _p_fx_rappresentanza(p: Dictionary) -> void:
	var c := _scegli_classe(p, "A quale classe dai rappresentanza?", [WC, MC, CC])
	if c < 0:
		return
	G(ST)["inf"] = int(G(ST)["inf"]) - 1
	var cubi := mini(2, int(s["riserva"][c]))
	fornisci(c, {"inf": 1, "cubi": cubi})
	legit(c, 2)

func _p_fx_contributi_st(p: Dictionary) -> void:
	var n := aziende_di(CC).size()
	paga(ST, 5 * n)
	fornisci(CC, {"soldi": 5 * n})
	s["cnt"] = n

func _opzioni_nazionalizzazione() -> Array:
	var o := []
	var vuota := ""
	for aid in s["pub"]:
		if not operativa(aid):
			vuota = aid
	if vuota == "":
		return o
	for aid in s["priv_cc"]:
		if not operativa(aid) and not Dati.az(aid)["auto"]:
			o.append({"t": "Nazionalizza %s (al posto di %s)" % [Dati.az(aid)["n"], Dati.az(vuota)["n"]], "v": [aid, vuota]})
	return o

func _p_fx_nazionalizzazione(p: Dictionary) -> void:
	if not p.has("aid"):
		if not _ha_r(p):
			_chiedi(p, ST, "Nazionalizzazione:", _opzioni_nazionalizzazione(), "nazionalizza")
			return
		var v: Array = _r(p)
		var aid: String = v[0]
		var vecchia: String = v[1]
		s["pub"].erase(vecchia)
		s["pub_giu"].append(vecchia)
		s["priv_cc"].erase(aid)
		s["pub"].append(aid)
		az(aid)["own"] = "ST"
		if pol(0) == "B":
			trasferisci(ST, CC, int(Dati.az(aid)["costo"]))
		p["aid"] = aid
		_log("Lo Stato nazionalizza %s." % Dati.az(aid)["n"])
	_spingi({"k": "assegna_n", "c": WC, "max": 3, "solo_dis": true, "solo_aziende": [p["aid"]], "chi": ST, "una_sola": true})

func _p_fx_privatizzazione(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		for aid in s["pub"]:
			if operativa(aid):
				ops.append({"t": "%s (%d)" % [Dati.az(aid)["n"], int(Dati.az(aid)["costo"])], "v": aid})
		_chiedi(p, ST, "Quale Azienda pubblica privatizzi?", ops, "privatizza")
		return
	var aid2: String = str(_r(p))
	s["pub"].erase(aid2)
	s["priv_cc"].append(aid2)
	az(aid2)["own"] = "CC"
	trasferisci(CC, ST, int(Dati.az(aid2)["costo"]))
	gettone(CC)
	for r in ["sal", "ist", "inf"]:
		s["servizi"][r] = mini(int(s["servizi"][r]), capienza_pubblica(r))
	_log("Lo Stato privatizza %s." % Dati.az(aid2)["n"])

func _p_fx_indennita(p: Dictionary) -> void:
	var c := _scegli_classe(p, "A quale classe dai 20?", [WC, MC, CC])
	if c < 0:
		return
	paga(ST, 20)
	fornisci(c, {"soldi": 20})
	gettone(c)

func _p_fx_agenda_setting(p: Dictionary) -> void:
	G(ST)["inf"] = int(G(ST)["inf"]) + agenda_corrispondenze()

func _p_fx_assistenza_estera(p: Dictionary) -> void:
	dai_soldi(ST, 10 * agenda_corrispondenze())

func _p_fx_qe(p: Dictionary) -> void:
	dai_soldi(ST, 35 if int(G(ST)["prestiti"]) > 0 else 25)

func _p_fx_censura(p: Dictionary) -> void:
	if not p.has("presi"):
		var m := mini(2, int(s["servizi"]["inf"]))
		s["servizi"]["inf"] = int(s["servizi"]["inf"]) - m
		G(ST)["inf"] = int(G(ST)["inf"]) + m
		p["presi"] = []
	if p["presi"].size() >= 2:
		return
	var classi := []
	for c in 3:
		if not c in p["presi"] and int(G(c)["inf"]) > 0 and int(G(ST)["leg"][c]) > 1:
			classi.append(c)
	if classi.is_empty():
		return
	if not _ha_r(p):
		var ops := [{"t": "Basta così", "v": -1}]
		for c in classi:
			ops.append({"t": "%s ti dà 1 Influenza (-1 Legittimità)" % nome(c), "v": c})
		_chiedi(p, ST, "Censura: chi colpisci?", ops, "censura")
		return
	var c2 := int(_r(p))
	if c2 < 0:
		return
	G(c2)["inf"] = int(G(c2)["inf"]) - 1
	G(ST)["inf"] = int(G(ST)["inf"]) + 1
	legit(c2, -1)
	p["presi"].append(c2)
	_spingi(p)

func _p_fx_risposta_immediata(p: Dictionary) -> void:
	if not _ha_r(p):
		var ops := []
		for eid in eventi_eseguibili():
			ops.append({"t": Dati.evento(eid)["it"], "v": eid})
		_chiedi(p, ST, "Risposta immediata: quale Evento?", ops, "evento")
		return
	var eid2: String = str(_r(p))
	_spingi({"k": "evento", "eid": eid2, "scarta": true})
	_spingi({"k": "evento", "eid": eid2, "scarta": false})

func _p_fx_cambio_priorita(p: Dictionary) -> void:
	_vedi_eventi(p, true)

func _p_fx_alta_priorita(p: Dictionary) -> void:
	_vedi_eventi(p, false)

func _vedi_eventi(p: Dictionary, sostituisci: bool) -> void:
	var cima := []
	for k in mini(2, s["mazzo_ev"].size()):
		var e: String = s["mazzo_ev"][s["mazzo_ev"].size() - 1 - k]
		if int(s["round"]) == 1 and Dati.evento(e)["r2"]:
			continue
		cima.append(e)
	if not p.has("fatto"):
		if not _ha_r(p):
			var ops := [{"t": "Non cambiare gli Eventi", "v": null}]
			for e in cima:
				if sostituisci:
					for vecchio in s["eventi_tav"]:
						ops.append({"t": "%s al posto di %s" % [Dati.evento(e)["it"], Dati.evento(vecchio)["it"]], "v": [e, vecchio]})
				elif s["eventi_tav"].size() < 2:
					ops.append({"t": "Metti in gioco %s" % Dati.evento(e)["it"], "v": [e, ""]})
			_chiedi(p, ST, "Guardi le prime carte Evento: %s." % ", ".join(cima.map(func(x): return Dati.evento(x)["it"])), ops, "eventi")
			return
		var v: Variant = _r(p)
		p["fatto"] = true
		if typeof(v) != TYPE_NIL:
			s["mazzo_ev"].erase(v[0])
			if str(v[1]) != "":
				s["eventi_tav"].erase(v[1])
			s["eventi_tav"].append(v[0])
	if eventi_eseguibili().is_empty():
		return
	_spingi({"k": "a_evento", "c": ST})

# ================================================================ eventi (azione dello Stato)
func _meta(n: int) -> int:
	return (n + 1) / 2

## Quantità richiesta dall'evento per la classe c.
func _qta_evento(modo: String, c: int) -> int:
	match modo:
		"meta":
			return _meta(popolazione(c)) if c in [WC, MC] else _meta(operative(c))
		"aziende":
			return _meta(operative(c))
		"pop":
			return _meta(popolazione(c))
	return 0

func opzioni_evento(eid: String) -> Array:
	var e := Dati.evento(eid)
	var f := str(e["fx"]).split(":")
	var nm := f[0]
	var o := []
	var sc: Dictionary = e["sc"]
	var cassa := soldi(ST)
	match nm:
		"fornisci_ris":
			var r := f[1]
			for x in sc:
				var c := Dati.CLASSI.find(x)
				var n := _qta_evento(f[2], c)
				if n <= 0:
					continue
				if costo_procurare(r, n, c) <= cassa:
					o.append({"t": "%s: %d %s" % [nome(c), n, Dati.NOMI_RIS[r]], "v": {"c": c, r: n, "item": n}})
		"fornisci_media2":
			if int(s["servizi"]["inf"]) >= 2:
				for x in sc:
					var c2 := Dati.CLASSI.find(x)
					o.append({"t": "%s: 2 Influenza dei Media" % nome(c2), "v": {"c": c2, "inf_media": 2}})
		"fornisci_soldi":
			for x in sc:
				var c3 := Dati.CLASSI.find(x)
				var n3 := 0
				match f[1]:
					"aziende5":
						n3 = 5 * operative(c3)
					"pop5":
						n3 = 5 * popolazione(c3)
					"pubblici5":
						for wid in lavoratori(c3):
							if lav(wid)["loc"] in s["pub"]:
								n3 += 5
				if n3 > 0 and n3 <= cassa:
					o.append({"t": "%s: %d" % [nome(c3), n3], "v": {"c": c3, "soldi": n3, "denaro": n3}})
		"fornisci_due":
			var r1 := f[1]
			var r2 := f[2]
			for x in sc:
				var c4 := Dati.CLASSI.find(x)
				var n4 := maxi(2, _qta_evento(f[3], c4))
				for a in range(1, n4):
					var b := n4 - a
					if costo_procurare(r1, a, c4) + costo_procurare(r2, b, c4) <= cassa:
						o.append({"t": "%s: %d %s + %d %s" % [nome(c4), a, Dati.NOMI_RIS[r1], b, Dati.NOMI_RIS[r2]], "v": {"c": c4, r1: a, r2: b, "item": n4}})
		"sostenibilita":
			if cassa >= 50:
				for pr in [[0, 1], [0, 2], [1, 2]]:
					o.append({"t": "25 a %s e a %s" % [Dati.NOMI_BREVI[Dati.CLASSI[pr[0]]], Dati.NOMI_BREVI[Dati.CLASSI[pr[1]]]], "v": {"coppia": pr}})
		"scandalo":
			var mi := mini(3, int(s["servizi"]["inf"]))
			if cassa >= 25 and mi > 0:
				for a2 in range(mi + 1):
					for b2 in range(mi + 1 - a2):
						var c5 := mi - a2 - b2
						if a2 + b2 + c5 == 0:
							continue
						o.append({"t": "Influenza: %d CO, %d CM, %d CC" % [a2, b2, c5], "v": {"distr": [a2, b2, c5]}})
		"stimolo":
			if cassa >= 30:
				o.append({"t": "10 a ogni classe (+3 PV)", "v": {"stimolo": 10}})
			if cassa >= 45:
				o.append({"t": "15 a ogni classe (+1 Legittimità a tutte)", "v": {"stimolo": 15}})
		"industria_nascente":
			for c6 in [MC, CC]:
				if posti_liberi(c6) <= 0:
					continue
				for aid in G(c6)["mercato"]:
					var d := Dati.az(aid)
					if int(d["costo"]) < 15 or int(d["costo"]) > cassa:
						continue
					if c6 == MC and scegli_lavoratori(MC, d["slot"], true).is_empty():
						continue
					o.append({"t": "%s per %s (%d)" % [d["n"], nome(c6), int(d["costo"])], "v": {"c": c6, "aid": aid}})
		"compra_da":
			var r3 := f[1]
			var lim: int = s["pub"].size()
			for c7 in [MC, CC]:
				var q := mini(lim, disponibile(c7, r3))
				q = mini(q, capienza_pubblica(r3) - disponibile(ST, r3))
				while q > 0 and q * prezzo(c7, r3) > cassa:
					q -= 1
				if q > 0 and sc.has(Dati.CLASSI[c7]):
					o.append({"t": "Compra %d %s da %s" % [q, Dati.NOMI_RIS[r3], nome(c7)], "v": {"da": c7, "r": r3, "q": q}})
		"polarizzazione":
			var cubi := [mini(4, int(s["riserva"][WC])), mini(4, int(s["riserva"][CC]))]
			if cassa >= 30:
				for a3 in range(5):
					var b3 := 4 - a3
					if a3 <= int(cubi[0]) and b3 <= int(cubi[1]):
						o.append({"t": "Cubi: %d alla Classe Operaia, %d alla Capitalista" % [a3, b3], "v": {"cubi_wc": a3, "cubi_cc": b3}})
		"disordini":
			for c8 in [WC, CC]:
				if puo_proporre(ST, false):
					o.append({"t": "Lascia scegliere la Legge a %s" % nome(c8), "v": {"c": c8}})
		"rappresentanza_ev":
			if int(G(ST)["inf"]) >= 1:
				for c9 in [WC, MC, CC]:
					o.append({"t": "%s: 1 Influenza e 2 cubi" % nome(c9), "v": {"c": c9}})
		"deflazione":
			for m in [15, 30, 45]:
				if cassa >= m:
					o.append({"t": "Spendi %d (+%d PV)" % [m, m / 15 * 2], "v": {"spendi": m}})
		"spendi_ris":
			var r4 := f[1]
			for q2 in range(mini(6, int(s["servizi"][r4])), 0, -1):
				o.append({"t": "Spendi %d %s (+%d PV)" % [q2, Dati.NOMI_RIS[r4], q2], "v": {"spendi_r": r4, "q": q2}})
	return o

func eventi_eseguibili() -> Array:
	var o := []
	for eid in s["eventi_tav"]:
		if not opzioni_evento(eid).is_empty():
			o.append(eid)
	return o

func _p_a_evento(p: Dictionary) -> void:
	var ev := eventi_eseguibili()
	if ev.is_empty():
		return
	if not _ha_r(p):
		var ops := []
		for eid in ev:
			ops.append({"t": Dati.evento(eid)["it"], "v": eid})
		_chiedi(p, ST, "Quale Evento affronti?", ops, "evento")
		return
	_spingi({"k": "evento", "eid": str(_r(p)), "scarta": true})

func _premio(e: Dictionary, chiave: String, c: int, quanti: int) -> void:
	var pr: String = str(e["sc"].get(chiave, ""))
	if pr == "":
		return
	var f := pr.split(":")
	match f[0]:
		"tok":
			gettone(c)
		"leg":
			legit(c, int(f[1]))
		"leg_per":
			legit(c, quanti / int(f[1]))
		"tok_per":
			for k in quanti / int(f[1]):
				gettone(c)
		"vp_per":
			var molt := int(f[3]) if f.size() > 3 else 1
			vp(ST, quanti / int(f[1]) * molt, "evento")
		"vp":
			vp(ST, int(f[1]), "evento")
		"leg_tutte":
			for k2 in 3:
				legit(k2, int(f[1]))

func _p_evento(p: Dictionary) -> void:
	var eid: String = p["eid"]
	var e := Dati.evento(eid)
	var ops := opzioni_evento(eid)
	if ops.is_empty():
		return
	if not _ha_r(p):
		_chiedi(p, ST, "%s: %s" % [e["it"], _testo_semplice(e["t"])], ops, "evento_scelta")
		return
	var v: Dictionary = _r(p)
	var nm := str(e["fx"]).split(":")[0]
	_log("Lo Stato affronta l'Evento «%s»." % e["it"])
	_ev({"tipo": "evento", "eid": eid})
	match nm:
		"fornisci_ris", "fornisci_due":
			var c: int = v["c"]
			var cosa := {}
			for r in Dati.RISORSE:
				if v.has(r):
					procura(r, int(v[r]), c)
					cosa[r] = int(v[r])
			fornisci(c, cosa)
			_premio(e, Dati.CLASSI[c], c, int(v["item"]))
		"fornisci_media2":
			s["servizi"]["inf"] = int(s["servizi"]["inf"]) - 2
			fornisci(int(v["c"]), {"inf": 2})
			_premio(e, Dati.CLASSI[int(v["c"])], int(v["c"]), 2)
		"fornisci_soldi":
			paga(ST, int(v["soldi"]))
			fornisci(int(v["c"]), {"soldi": int(v["soldi"])})
			_premio(e, Dati.CLASSI[int(v["c"])], int(v["c"]), int(v["denaro"]))
		"sostenibilita":
			for c2 in v["coppia"]:
				paga(ST, 25)
				fornisci(int(c2), {"soldi": 25})
				_premio(e, Dati.CLASSI[int(c2)], int(c2), 25)
		"scandalo":
			paga(ST, 25)
			var dd: Array = v["distr"]
			for c3 in 3:
				if int(dd[c3]) > 0:
					s["servizi"]["inf"] = int(s["servizi"]["inf"]) - int(dd[c3])
					fornisci(c3, {"inf": int(dd[c3])})
					_premio(e, Dati.CLASSI[c3], c3, int(dd[c3]))
		"stimolo":
			var m: int = v["stimolo"]
			for c4 in 3:
				paga(ST, m)
				fornisci(c4, {"soldi": m})
			_premio(e, str(m), 0, 0)
		"industria_nascente":
			var c5: int = v["c"]
			var aid: String = v["aid"]
			_spingi({"k": "premio_evento", "eid": eid, "c": c5})
			_spingi({"k": "a_costruisci", "c": c5, "aid": aid, "paga_stato": true})
			if not p["scarta"]:
				return
		"compra_da":
			var da: int = v["da"]
			var r5: String = v["r"]
			var q: int = v["q"]
			trasferisci(ST, da, q * prezzo(da, r5))
			_togli_ris(da, r5, q)
			immagazzina(ST, r5, q)
			_premio(e, Dati.CLASSI[da], da, q)
		"polarizzazione":
			paga(ST, 30)
			if int(v["cubi_wc"]) > 0:
				fornisci(WC, {"cubi": int(v["cubi_wc"])})
			if int(v["cubi_cc"]) > 0:
				fornisci(CC, {"cubi": int(v["cubi_cc"])})
			_premio(e, "WC", WC, int(v["cubi_wc"]))
			_premio(e, "CC", CC, int(v["cubi_cc"]))
		"disordini":
			var c6: int = v["c"]
			_spingi({"k": "premio_evento", "eid": eid, "c": c6})
			_spingi({"k": "disordini", "chi": c6})
		"rappresentanza_ev":
			var c7: int = v["c"]
			G(ST)["inf"] = int(G(ST)["inf"]) - 1
			fornisci(c7, {"inf": 1, "cubi": mini(2, int(s["riserva"][c7]))})
			_premio(e, Dati.CLASSI[c7], c7, 1)
		"deflazione":
			paga(ST, int(v["spendi"]))
			_premio(e, "spendi", ST, int(v["spendi"]))
		"spendi_ris":
			s["servizi"][v["spendi_r"]] = int(s["servizi"][v["spendi_r"]]) - int(v["q"])
			_premio(e, "spendi", ST, int(v["q"]))
	if p["scarta"]:
		s["eventi_tav"].erase(eid)

func _p_premio_evento(p: Dictionary) -> void:
	var e := Dati.evento(p["eid"])
	_premio(e, Dati.CLASSI[int(p["c"])], int(p["c"]), 1)
	s["eventi_tav"].erase(p["eid"])

## Disordini civili: la classe scelta sceglie la Legge, lo Stato la propone.
func _p_disordini(p: Dictionary) -> void:
	var chi: int = p["chi"]
	if not _ha_r(p):
		var ops := []
		for k in 7:
			if s["prop"][k] == null:
				for x in sezioni_proponibili(k, false):
					ops.append({"t": "%d%s (%s)" % [k + 1, x, Dati.POLITICHE[k]], "v": [k, x]})
		_chiedi(p, chi, "Disordini civili: quale Legge deve proporre lo Stato?", ops, "proponi_pol")
		return
	var v: Array = _r(p)
	_spingi({"k": "a_proponi", "c": ST, "pol": int(v[0]), "sez": str(v[1])})

func _testo_semplice(t: String) -> String:
	var o := t
	for k in ["cibo", "lus", "sal", "ist", "inf", "mac"]:
		o = o.replace("{%s}" % k, Dati.NOMI_RIS.get(k, "Macchinario"))
	o = o.replace("{V}", "").replace("{VP}", " PV")
	return o
