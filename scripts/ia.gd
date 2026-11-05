## Intelligenza artificiale: valuta ogni opzione simulandone l'effetto sul resto del turno
## e stimando la posizione della propria classe (punti, denaro, aziende, prosperità, legittimità...).
class_name IA
extends RefCounted

var rng := RandomNumberGenerator.new()
var rapida := false
var facile := false
var casuale := false

## Preferenze per sezione (A, B, C) di ogni politica, per classe.
const PREF := [
	[[3, 1, 0], [3, 1, 0], [2, 1, 0], [3, 1, 0], [3, 1, 0], [1, 2, 1], [2, 1, 0]],
	[[1, 3, 0], [1, 3, 0], [0, 3, 1], [1, 3, 0], [1, 3, 0], [2, 2, 0], [0, 2, 1]],
	[[0, 1, 3], [0, 1, 3], [0, 1, 3], [0, 1, 3], [0, 1, 3], [0, 1, 3], [0, 1, 3]],
	[[1, 1, 1], [1, 1, 1], [2, 1, 1], [1, 1, 1], [1, 1, 1], [2, 1, 0], [1, 1, 1]],
]
const PROFONDI := ["turno", "base", "libera", "scarta"]

func scegli(m: Motore, a: Dictionary) -> int:
	var ops: Array = a["opzioni"]
	if ops.size() <= 1:
		return 0
	rng.seed = int(m.s["rng"]) * 31 + int(m.s["decisioni"]) * 2654435761
	if casuale:
		return rng.randi() % ops.size()
	var me: int = a["g"]
	var tipo: String = a.get("tipo", "")
	match tipo:
		"voto":
			return _voto(m, me, a)
		"influenza":
			return _influenza(m, me, a)
		"mercato":
			return _mercato(m, me)
	var profondo: bool = tipo in PROFONDI and not rapida
	var best := 0
	var bv := -INF
	for i in ops.size():
		var v := _valuta(m, me, i, profondo)
		v += rng.randf() * (4.0 if facile else 0.05)
		if v > bv:
			bv = v
			best = i
	return best

# ---------------------------------------------------------------- simulazione
func _copia(m: Motore) -> Motore:
	var log = m.s["log"]
	var ev = m.s["eventi"]
	var st = m.s["storico"]
	m.s["log"] = []
	m.s["eventi"] = []
	m.s["storico"] = []
	var c := Motore.new()
	c.s = m.s.duplicate(true)
	m.s["log"] = log
	m.s["eventi"] = ev
	m.s["storico"] = st
	c.s["rng"] = (int(c.s["rng"]) * 1103515245 + 12345 + rng.randi()) & 0x7FFFFFFF
	return c

func _valuta(m: Motore, me: int, i: int, profondo: bool) -> float:
	var c := _copia(m)
	c.scegli(i)
	var passi := 0
	var limite := 10 if profondo else 3
	while passi < limite and not c.s["fine"]:
		var a := c.attesa()
		if a.is_empty() or int(a["g"]) != me:
			break
		var t: String = a.get("tipo", "")
		if t in ["turno", "voto", "influenza"]:
			break
		c.scegli(_rapida(c, me, a))
		passi += 1
	return valuta_posizione(c, me)

func _rapida(c: Motore, me: int, a: Dictionary) -> int:
	var ops: Array = a["opzioni"]
	if ops.size() <= 1:
		return 0
	var t: String = a.get("tipo", "")
	if t == "voto":
		return _voto(c, me, a)
	if t == "influenza":
		return _influenza(c, me, a)
	var best := 0
	var bv := -INF
	var n := mini(ops.size(), 12)
	for i in n:
		var x := _copia(c)
		x.scegli(i)
		var v := valuta_posizione(x, me)
		if v > bv:
			bv = v
			best = i
	return best

# ---------------------------------------------------------------- votazioni
func valore_politica(me: int, m: Motore, k: int, sez: String) -> float:
	var x := Dati.SEZ.find(sez)
	if me == Motore.ST:
		var ag: Array = Dati.d()["agende"][int(m.G(Motore.ST)["agenda"])]
		var v: float = PREF[3][k][x]
		if k < 5 and ag[k] == sez:
			v += 3.0
		return v
	return float(PREF[me][k][x])

func _voto(m: Motore, me: int, a: Dictionary) -> int:
	var p: Dictionary = a["passo"]
	var k: int = p["pol"]
	var pr: Dictionary = m.s["prop"][k]
	var nuovo := valore_politica(me, m, k, pr["sez"])
	var vecchio := valore_politica(me, m, k, m.pol(k))
	# piccolo premio al sostegno (1 PV se la legge passa con il proprio contributo)
	var favorevole := nuovo + 0.4 > vecchio
	for i in a["opzioni"].size():
		if bool(a["opzioni"][i]["v"]) == favorevole:
			return i
	return 0

func _influenza(m: Motore, me: int, a: Dictionary) -> int:
	var p: Dictionary = a["passo"]
	var k: int = p["pol"]
	var pr: Dictionary = m.s["prop"][k]
	var mio: bool = p["pref"][str(me)]
	var vc := m.conta_voti(p)
	var miei: int = vc[0] if mio else vc[1]
	var loro: int = vc[1] if mio else vc[0]
	var importanza: float = absf(valore_politica(me, m, k, pr["sez"]) - valore_politica(me, m, k, m.pol(k)))
	if int(pr["c"]) == me:
		importanza += 2.0
	var disp: int = m.G(me)["inf"]
	# chi deve ancora decidere dopo di me potrebbe ribaltare: tengo un margine
	var serve := 0
	if mio:
		serve = loro - miei
	else:
		serve = miei - loro + 1
	if serve <= 0:
		serve = 1 if importanza >= 2.5 and disp >= 3 else 0
	if serve > disp or importanza < 1.0:
		serve = 0
	if serve > 0 and importanza < 2.0 and serve > 1:
		serve = 0
	for i in a["opzioni"].size():
		if int(a["opzioni"][i]["v"]) == serve:
			return i
	return 0

func _mercato(m: Motore, me: int) -> int:
	var g := m.G(me)
	var buone := 0
	for aid in g["mercato"]:
		var d := Dati.az(aid)
		if int(d["costo"]) <= m.soldi(me):
			buone += 1
	return 1 if buone == 0 and m.soldi(me) > 30 else 0

# ---------------------------------------------------------------- valutazione della posizione
func valuta_posizione(m: Motore, me: int) -> float:
	if m.s["fine"]:
		return 2000.0 if int(m.s["vincitore"]) == me else float(m.G(me)["vp"]) * 3.0
	var mio := _punteggio(m, me)
	var mx := -INF
	var somma := 0.0
	for j in 4:
		if j == me:
			continue
		var v := float(m.G(j)["vp"])
		mx = maxf(mx, v)
		somma += v
	return mio - 0.25 * mx - 0.1 * somma / 3.0

func _punteggio(m: Motore, me: int) -> float:
	var g := m.G(me)
	var round_rimasti := 6 - int(m.s["round"])
	var futuro := clampf(round_rimasti / 5.0, 0.0, 1.0)
	var v := float(g["vp"]) * 3.0
	v -= float(g["prestiti"]) * (16.0 if me == Motore.CC else 36.0)
	v += float(g["inf"]) * 2.0 * futuro + float(g["inf"]) * 0.5
	if me != Motore.ST:
		v += float(m.s["borsa"][me]) * 0.9 * futuro
	# politiche
	for k in 7:
		var w := 1.6 if k < 5 else 1.0
		v += valore_politica(me, m, k, m.pol(k)) * w * (0.6 + futuro)
		var pr = m.s["prop"][k]
		if pr != null:
			var dv := valore_politica(me, m, k, pr["sez"]) - valore_politica(me, m, k, m.pol(k))
			v += dv * 0.6
			if int(pr["c"]) == me:
				v += 2.0
	match me:
		Motore.WC:
			v += _operai(m, futuro)
		Motore.MC:
			v += _ceto_medio(m, futuro)
		Motore.CC:
			v += _capitalisti(m, futuro)
		Motore.ST:
			v += _stato(m, futuro)
	return v

func _beni_verso_uso(m: Motore, c: int) -> float:
	var g := m.G(c)
	var pop := maxi(1, m.popolazione(c))
	var prosp: int = g["prosp"]
	var prossimo: float = float(prosp + 1) if c == Motore.WC else float(Dati.PROSP_MC[mini(10, prosp + 1)])
	var valore_uso := prossimo * 3.0 + 3.0
	var v := 0.0
	for r in ["sal", "ist", "lus"]:
		var q: float = g["beni"][r]
		var extra := 6.0 if r == "sal" else (2.0 if r == "ist" else 0.0)
		var pieni := floorf(q / pop)
		v += pieni * (valore_uso + extra) * 0.85
		v += fmod(q, pop) / pop * (valore_uso + extra) * 0.45
	v += float(g["beni"]["cibo"]) * 0.9
	return v

func _operai(m: Motore, futuro: float) -> float:
	var g := m.G(Motore.WC)
	var v := 0.0
	v += float(g["soldi"]) * 0.22
	v += float(g["prosp"]) * 4.0 * futuro
	v += _beni_verso_uso(m, Motore.WC)
	var occ := m.occupati(Motore.WC).size()
	var dis := m.disoccupati(Motore.WC).size()
	v += occ * 2.2 * futuro - dis * 1.0 * futuro
	v += m.sindacati() * 6.0 * futuro
	for wid in m.lavoratori(Motore.WC):
		var w: Dictionary = m.lav(wid)
		if w["sk"] != "u":
			v += 0.8 * futuro
		var loc: String = w["loc"]
		if loc != "" and m.s["aziende"].has(loc):
			v += float(m.salario(loc)) / maxf(1.0, m.lavoratori_in(loc).size()) * 0.12 * futuro
			if m.s["aziende"][loc]["sc"]:
				v += 2.2 - float(m.salario(loc)) / maxf(1.0, m.lavoratori_in(loc).size()) * 0.22
	if m.s["dimostr"]:
		v += 3.0
	return v

func _ceto_medio(m: Motore, futuro: float) -> float:
	var g := m.G(Motore.MC)
	var v := 0.0
	v += float(g["soldi"]) * 0.2
	v += float(g["prosp"]) * 3.0 * futuro
	v += _beni_verso_uso(m, Motore.MC)
	for r in Dati.RISORSE:
		v += float(g["mag"][r]) * 1.2
	for aid in m.s["priv_mc"]:
		v += 7.0 * futuro + 2.0
		if m.piena(aid):
			v += 3.0 * futuro
		elif m.operativa(aid):
			v += 1.5 * futuro
	var dis := m.disoccupati(Motore.MC).size()
	v += m.occupati(Motore.MC).size() * 1.6 * futuro - dis * 0.8 * futuro
	return v

func _capitalisti(m: Motore, futuro: float) -> float:
	var g := m.G(Motore.CC)
	var v := 0.0
	var denaro := float(g["rev"]) + float(g["cap"])
	v += denaro * 0.14
	# livello di ricchezza raggiungibile
	var liv := 0
	for k in Dati.RICCHEZZA.size():
		if denaro >= Dati.RICCHEZZA[k]:
			liv = k + 1
	v += maxf(0.0, liv - int(g["ricchezza"])) * 2.0
	for r in Dati.RISORSE:
		var q := float(g["mag"][r])
		if r in ["cibo", "lus"]:
			q += float(g["ftz"][r])
		v += q * float(g["prezzi"][r]) * 0.09
	for aid in m.s["priv_cc"]:
		var d := Dati.az(aid)
		v += float(d["costo"]) * 0.18 + 3.0
		if m.operativa(aid):
			var r2: String = Dati.RIS_IND[d["ind"]]
			var valore := 8.0 if r2 == "inf" else float(g["prezzi"].get(r2, 8))
			v += (float(m.produzione(aid)) * valore * 0.75 - float(m.salario(aid))) * 0.18 * futuro * 2.0 + 3.0 * futuro
		if m.s["aziende"][aid]["mac"]:
			v += 2.0
	return v

func _stato(m: Motore, futuro: float) -> float:
	var g := m.G(Motore.ST)
	var v := 0.0
	v += float(g["soldi"]) * 0.11
	var l: Array = g["leg"].duplicate()
	l.sort()
	v += (float(l[0]) + float(l[1])) * 2.2 + float(l[2]) * 0.6
	for c in 3:
		v += float(g["tok"][c]) * 4.0 * futuro
	if m.s["fase"] == "azioni":
		for eid in m.s["eventi_tav"]:
			v -= 4.0
	v += m.agenda_corrispondenze() * 1.6
	for r in ["sal", "ist", "inf"]:
		v += float(m.s["servizi"][r]) * 0.5
	for c in 3:
		var b: Dictionary = g["ben"][c]
		for k in b:
			if int(b[k]) > 0:
				v += 1.0
				break
	return v
