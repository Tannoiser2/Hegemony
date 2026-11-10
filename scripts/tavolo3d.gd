## Tavolo 3D: tabellone originale, plance originali dei giocatori, carte in italiano e pedine 3D.
## Mouse: sinistro trascina, destro ruota, rotella zoom, clic su una carta per i dettagli.
## Tocco (iPad): un dito trascina, due dita pizzicano per lo zoom e ruotano, tocco breve per i dettagli.
class_name Tavolo3D
extends Node3D

signal dettagli(testo: String)

const F_BOLD := preload("res://assets/font/Montserrat-Bold.ttf")
const F_NERO := preload("res://assets/font/Montserrat-ExtraBold.ttf")
const MESH_LAV := preload("res://assets/modelli/lavoratore.obj")

const CARTA := Vector2(2.3, 3.19)          # carta azienda sul tabellone (360x500 px)
const PLANCIA := Vector2(11.6, 6.52)
const ALTO := 0.06                          # quota del piano dei tabelloni

## Centri delle plance dei giocatori (a sinistra Operai e Ceto medio, a destra Capitalisti e Stato).
const CENTRO_PLANCIA := {0: Vector3(-16.4, 0, -9.2), 1: Vector3(-16.4, 0, -0.6), 2: Vector3(16.4, 0, -9.2), 3: Vector3(16.4, 0, -0.6)}
const PRIV_X := [252, 499, 745, 992]
const PRIV_Y := [1380, 1720, 2060, 2400, 2720]
const PUB_X := [1278, 1524, 1770]
const PUB_Y := [1720, 2060, 2400]

var m: Motore
var cam: Camera3D
var bersaglio := Vector3(0, 0, 3.5)
var yaw := 0.0
var pitch := deg_to_rad(63.0)
var dist := 45.0
var coord: Dictionary
var nodi := {}
var visti := {}
var zone := []
var tocchi := {}
var mosso := 0.0
var materiali := {}
var texture := {}

# ================================================================ costruzione
func _ready() -> void:
	var f := FileAccess.open("res://dati/tavolo.json", FileAccess.READ)
	coord = JSON.parse_string(f.get_as_text())
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#15181c")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.9)
	e.ambient_light_energy = 0.42
	env.environment = e
	add_child(env)
	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-58, -28, 0)
	luce.light_energy = 0.62
	luce.shadow_enabled = true
	luce.directional_shadow_max_distance = 90.0
	add_child(luce)
	cam = Camera3D.new()
	cam.fov = 42.0
	cam.far = 300.0
	add_child(cam)
	_aggiorna_camera()
	# tavolo
	var piano := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 90)
	piano.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color("#2b2621")
	mt.roughness = 0.9
	piano.material_override = mt
	add_child(piano)
	_lastra("res://assets/3d/tabellone.webp", Vector3(0, 0, 0), Vector2(20, 30))
	var img_pl := {0: "plancia_WC", 1: "plancia_MC", 2: "plancia_CC", 3: "plancia_ST"}
	for c in 4:
		_lastra("res://assets/3d/%s.webp" % img_pl[c], CENTRO_PLANCIA[c], PLANCIA)
	zone.clear()

func _tex(path: String) -> Texture2D:
	if not texture.has(path):
		texture[path] = load(path) if ResourceLoader.exists(path) else null
	return texture[path]

func _mat_img(path: String, trasparente := false) -> StandardMaterial3D:
	var k := path + str(trasparente)
	if not materiali.has(k):
		var mt := StandardMaterial3D.new()
		mt.albedo_texture = _tex(path)
		mt.roughness = 0.75
		if trasparente:
			mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mt.alpha_scissor_threshold = 0.4
		materiali[k] = mt
	return materiali[k]

func _mat_col(c: Color, ruvido := 0.6) -> StandardMaterial3D:
	var k := c.to_html() + str(ruvido)
	if not materiali.has(k):
		var mt := StandardMaterial3D.new()
		mt.albedo_color = c
		mt.roughness = ruvido
		materiali[k] = mt
	return materiali[k]

## Tabellone o plancia: lastra spessa con l'immagine sopra.
func _lastra(path: String, centro: Vector3, misura: Vector2) -> void:
	var bordo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(misura.x, ALTO, misura.y)
	bordo.mesh = bm
	bordo.material_override = _mat_col(Color("#1b1d21"))
	bordo.position = centro + Vector3(0, ALTO / 2, 0)
	add_child(bordo)
	var sopra := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = misura
	sopra.mesh = pm
	sopra.material_override = _mat_img(path)
	sopra.position = centro + Vector3(0, ALTO + 0.002, 0)
	add_child(sopra)

# ================================================================ coordinate
func px(x: float, y: float, h := 0.0) -> Vector3:
	return Vector3(x / 100.0 - 10.0, ALTO + h, y / 100.0 - 15.0)

func pv(v, h := 0.0) -> Vector3:
	return px(float(v[0]), float(v[1]), h)

## Punto di una plancia: frazioni dell'immagine (0..1).
func pb(c: int, fx: float, fy: float, h := 0.0) -> Vector3:
	return CENTRO_PLANCIA[c] + Vector3((fx - 0.5) * PLANCIA.x, ALTO + h, (fy - 0.5) * PLANCIA.y)

# ================================================================ pezzi
func _nodo(chiave: String, crea: Callable, pos: Vector3, rot := Vector3.ZERO) -> Node3D:
	visti[chiave] = true
	var n: Node3D = nodi.get(chiave)
	if n == null or not is_instance_valid(n):
		n = crea.call()
		add_child(n)
		n.position = pos
		n.rotation = rot
		nodi[chiave] = n
		n.set_meta("meta", pos)
		return n
	if n.get_meta("meta", Vector3.INF) != pos or n.rotation != rot:
		n.set_meta("meta", pos)
		var tw := n.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var su := (n.position.distance_to(pos) > 0.6)
		if su:
			var mezzo := (n.position + pos) / 2 + Vector3(0, 1.2, 0)
			var tw2 := n.create_tween().set_trans(Tween.TRANS_SINE)
			tw2.tween_property(n, "position", mezzo, 0.22)
			tw2.tween_property(n, "position", pos, 0.22)
		else:
			tw.tween_property(n, "position", pos, 0.3)
		tw.tween_property(n, "rotation", rot, 0.35)
	return n

func _crea_carta(path: String, misura: Vector2) -> Node3D:
	var n := Node3D.new()
	var bordo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(misura.x, 0.03, misura.y)
	bordo.mesh = bm
	bordo.material_override = _mat_col(Color("#e9e7e1"))
	bordo.position.y = 0.015
	n.add_child(bordo)
	var sopra := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = misura
	sopra.mesh = pm
	sopra.material_override = _mat_img(path)
	sopra.position.y = 0.032
	n.add_child(sopra)
	return n

func carta(chiave: String, path: String, pos: Vector3, misura := CARTA, testo := "") -> void:
	var k := chiave + "|" + path
	_nodo(k, _crea_carta.bind(path, misura), pos)
	if testo != "":
		zone.append({"r": Rect2(pos.x - misura.x / 2, pos.z - misura.y / 2, misura.x, misura.y), "t": testo})

func _crea_gettone(path: String, raggio: float, col: Color) -> Node3D:
	var n := Node3D.new()
	var cil := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raggio
	cm.bottom_radius = raggio
	cm.height = 0.1
	cm.radial_segments = 28
	cil.mesh = cm
	cil.material_override = _mat_col(col, 0.5)
	cil.position.y = 0.05
	n.add_child(cil)
	if path != "":
		var sopra := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(raggio * 2, raggio * 2)
		sopra.mesh = pm
		sopra.material_override = _mat_img(path, true)
		sopra.position.y = 0.102
		n.add_child(sopra)
	return n

func gettone(chiave: String, path: String, pos: Vector3, raggio := 0.3, col := Color("#2b2f35")) -> void:
	_nodo(chiave, _crea_gettone.bind(path, raggio, col), pos)

func _crea_lav(sk: String, classe: int) -> Node3D:
	var n := Node3D.new()
	var corpo := MeshInstance3D.new()
	corpo.mesh = MESH_LAV
	corpo.scale = Vector3.ONE * 1.9
	var col: Color = Dati.COLORI_IND[sk]
	if sk == "sal":
		col = Color("#f2f2f2")
	corpo.material_override = _mat_col(col.darkened(0.08), 0.55)
	n.add_child(corpo)
	var base := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.15
	cm.bottom_radius = 0.16
	cm.height = 0.035
	base.mesh = cm
	base.material_override = _mat_col(Dati.COLORI[Dati.CLASSI[classe]], 0.4)
	base.position.y = 0.025
	n.add_child(base)
	corpo.position.y = 0.05
	return n

## Lavoratore: in piedi, oppure sdraiato se è impegnato.
func lavoratore(wid: String, w: Dictionary, pos: Vector3) -> void:
	var rot := Vector3.ZERO
	if w["imp"]:
		rot = Vector3(deg_to_rad(-90), 0, 0)
		pos += Vector3(0, 0.2, 0.25)
	_nodo("w:" + wid + ":" + str(w["sk"]), _crea_lav.bind(str(w["sk"]), int(w["c"])), pos, rot)

func _crea_etichetta(dim: int, col: Color) -> Node3D:
	var l := Label3D.new()
	l.font = F_NERO
	l.font_size = dim
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.modulate = col
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	return l

func scritta(chiave: String, testo: String, pos: Vector3, dim := 64, col := Color.WHITE) -> void:
	var n: Label3D = _nodo("t:" + chiave, _crea_etichetta.bind(dim, col), pos)
	n.text = testo

## Gettone di risorsa con il numero sopra (non mostra nulla se n = 0 e nascondi_zero).
func risorsa(chiave: String, r: String, n: int, pos: Vector3, nascondi_zero := false) -> void:
	if n <= 0 and nascondi_zero:
		return
	var path: String = {"cibo": "res://assets/3d/t_cibo.png", "lus": "res://assets/3d/t_lus.png", "sal": "res://assets/3d/t_sal.png", "ist": "res://assets/3d/t_ist.png",
		"soldi": "res://assets/3d/t_soldi.png", "inf": "res://assets/icone/inf.png"}.get(r, "")
	var col := Color("#963c8c") if r == "inf" else Color("#2b2f35")
	gettone("r:" + chiave, path, pos, 0.32, col)
	scritta("r:" + chiave, str(n), pos + Vector3(0, 0.75, 0), 70)

func _crea_cubo(classe: int) -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.26, 0.26, 0.26)
	mi.mesh = bm
	mi.material_override = _mat_col(Dati.COLORI[Dati.CLASSI[classe]], 0.4)
	mi.position.y = 0.13
	n.add_child(mi)
	return n

func cubo(chiave: String, classe: int, pos: Vector3) -> void:
	_nodo(chiave, _crea_cubo.bind(classe), pos)

# ================================================================ aggiornamento
func aggiorna(motore: Motore) -> void:
	m = motore
	if m == null:
		return
	visti.clear()
	zone.clear()
	_segnapunti()
	_politiche()
	_mercato_eventi()
	_aziende()
	_disoccupati()
	_servizi_stato()
	_plancia_operai()
	_plancia_ceto_medio()
	_plancia_capitalisti()
	_plancia_stato()
	for c in 4:
		var p := pb(c, 0.5, -0.07, 0.1)
		var g := m.G(c)
		var t := "%s   %d PV" % [Dati.NOMI_CLASSE[Dati.CLASSI[c]].to_upper(), int(g["vp"])]
		scritta("titolo%d" % c, t, p, 62, Dati.COLORI[Dati.CLASSI[c]].lightened(0.35))
		var t2 := "Influenza %d   Carte %d" % [int(g["inf"]), g["mano"].size()]
		if int(g["prestiti"]) > 0:
			t2 += "   PRESTITI %d" % int(g["prestiti"])
		scritta("sotto%d" % c, t2, pb(c, 0.5, 1.07, 0.1), 44, Color("#d8dce0"))
		zone.append({"r": Rect2(CENTRO_PLANCIA[c].x - PLANCIA.x / 2, CENTRO_PLANCIA[c].z - PLANCIA.y / 2, PLANCIA.x, PLANCIA.y), "t": "plancia:%d" % c})
	for k in nodi.keys():
		if not visti.has(k):
			var n: Node = nodi[k]
			if is_instance_valid(n):
				n.queue_free()
			nodi.erase(k)

func _segnapunti() -> void:
	var tr: Array = coord["tracciato"]
	var conta := {}
	for c in 4:
		var v := posmod(int(m.G(c)["vp"]), 100)
		var k := int(conta.get(v, 0))
		conta[v] = k + 1
		gettone("vp%d" % c, "res://assets/3d/classe_%s.png" % Dati.CLASSI[c], pv(tr[v], 0.11 * k), 0.3, Dati.COLORI[Dati.CLASSI[c]])
	var r := clampi(int(m.s["round"]), 1, 5)
	gettone("round", "res://assets/3d/round.png", pv(coord["round"][r - 1]), 0.3, Color("#f6b33c"))
	var molt := str(m.moltiplicatore())
	if coord["molt"].has(molt):
		gettone("molt", "res://assets/3d/molt.png", pv(coord["molt"][molt]), 0.26, Color("#f6b33c"))

func _politiche() -> void:
	for k in 7:
		var x := m.polx(k)
		gettone("pol%d" % k, "res://assets/3d/politica.png", pv(coord["politiche"][k][x]), 0.32, Color("#111"))
		var pr = m.s["prop"][k]
		if pr != null:
			var j := Dati.SEZ.find(str(pr["sez"]))
			var c: int = pr["c"]
			gettone("legge%d" % k, "res://assets/3d/classe_%s.png" % Dati.CLASSI[c], pv(coord["politiche"][k][j], 0.0) + Vector3(0.0, 0.0, 0.0), 0.3, Dati.COLORI[Dati.CLASSI[c]])

func _mercato_eventi() -> void:
	var ev: Array = m.s["eventi_tav"]
	var pos_ev := [[1340, 560], [1714, 560]]
	for i in mini(2, ev.size()):
		var e := Dati.evento(ev[i])
		carta("ev%d" % i, "res://assets/carte3d/%s.webp" % ev[i], pv(pos_ev[i]), Vector2(1.75, 2.43), "evento:" + str(ev[i]))
	carta("export", "res://assets/carte3d/x%02d.webp" % int(m.s["export"]), px(637, 1020), Vector2(1.7, 2.36), "export")
	var acc: Array = m.s["accordi_tav"]
	var pos_acc := [[193, 1020], [353, 1020]]
	for i in mini(2, acc.size()):
		carta("acc%d" % i, "res://assets/carte3d/b%02d.webp" % int(acc[i]), pv(pos_acc[i]), Vector2(1.45, 2.01), "accordo:%d" % int(acc[i]))
	# sacchetto dei voti (riquadro dei risultati del voto)
	for c in 3:
		var n := int(m.s["borsa"][c])
		var base := px(1330 + c * 190, 350)
		for k in mini(n, 12):
			cubo("bv%d_%d" % [c, k], c, base + Vector3((k % 4) * 0.3 - 0.45, 0.27 * (k / 4), 0))
		scritta("borsa%d" % c, str(n), base + Vector3(0, 1.3, 0), 60)
	scritta("borsa", "SACCHETTO DEI VOTI", px(1520, 300, 0.05), 44, Color("#f6b33c"))

func _slot_azienda(lista: String, i: int) -> Vector3:
	match lista:
		"CC":
			return px(PRIV_X[i % 4], PRIV_Y[i / 4])
		"MC":
			return px(PRIV_X[i % 4], PRIV_Y[3 + i / 4])
		"ST":
			return px(PUB_X[i % 3], PUB_Y[i / 3])
		"WC":
			return CENTRO_PLANCIA[1] + Vector3(-4.0 + i * 2.5, ALTO, 5.6)
	return Vector3.ZERO

func _aziende() -> void:
	var gruppi := {"CC": m.s["priv_cc"], "MC": m.s["priv_mc"], "ST": m.s["pub"], "WC": m.aziende_di(Motore.WC)}
	for g in gruppi:
		var lista: Array = gruppi[g]
		for i in lista.size():
			var aid: String = lista[i]
			if i >= (12 if g == "CC" else (8 if g == "MC" else 9)):
				continue
			_azienda(aid, _slot_azienda(g, i))

func _azienda(aid: String, centro: Vector3) -> void:
	var d := Dati.az(aid)
	var a: Dictionary = m.az(aid)
	var img := "coop" if aid.begins_with("coop") else aid
	carta("az:" + aid, "res://assets/carte3d/%s.webp" % img, centro, CARTA, "azienda:" + aid)
	var h := 0.04
	var slot: Array = d["slot"]
	var dip := str(d.get("dip", "")) if d["tipo"] == "MC" else ""
	var tot := slot.size() + (1 if dip != "" else 0)
	var passo := 0.24 if tot <= 3 else 0.2
	var x0 := 0.5 - passo * (tot - 1) / 2.0
	var occupanti: Array = a["lav"].duplicate()
	if dip != "":
		occupanti.append(a.get("dip", ""))
	for k in occupanti.size():
		var wid: String = occupanti[k]
		if wid == "":
			continue
		var p := centro + Vector3((x0 + k * passo - 0.5) * CARTA.x, h, (0.64 - 0.5) * CARTA.y)
		lavoratore(wid, m.lav(wid), p)
	if not d["auto"] and int(d["sal"][0]) > 0:
		var lv := clampi(int(a["sal"]), 1, 3)
		var p2 := centro + Vector3((0.2 + 0.3 * (lv - 1) - 0.5) * CARTA.x, h, (0.91 - 0.5) * CARTA.y)
		gettone("sal:" + aid, "", p2 + Vector3(0.38, 0, -0.1), 0.1, Color("#f6b33c"))
	if a.get("sc", false):
		gettone("sc:" + aid, "res://assets/3d/sciopero.png", centro + Vector3(0.75, h, -1.2), 0.42, Color("#c8161d"))
	if a.get("mac", false):
		gettone("mac:" + aid, "res://assets/3d/macchinario.png", centro + Vector3(0.75, h, 0.45), 0.25, Color("#333"))

func _disoccupati() -> void:
	# riquadro dei lavoratori disoccupati del tabellone (x 1180..1630, y 2590..2830)
	var righe := {Motore.WC: 2610.0, Motore.MC: 2760.0}
	for c in [Motore.WC, Motore.MC]:
		var dis := m.disoccupati(c)
		dis.sort()
		for k in dis.size():
			var col := k % 11
			var riga := k / 11
			var p := px(1190 + col * 42, righe[c] + riga * 55)
			lavoratore(dis[k], m.lav(dis[k]), p)
	if m.s["dimostr"]:
		gettone("dimostr", "res://assets/3d/manifestazione.png", px(1420, 2520), 0.6, Color("#c8161d"))
	zone.append({"r": Rect2(1.6, 10.6, 5.0, 2.5), "t": "disoccupati"})

func _servizi_stato() -> void:
	var pos := {"sal": [1294, 1280], "ist": [1531, 1280], "inf": [1765, 1280]}
	for r in pos:
		risorsa("pub" + r, r, int(m.s["servizi"][r]), pv(pos[r]))
	risorsa("tesoro", "soldi", m.soldi(Motore.ST), px(1700, 1060))
	# benefici da ritirare (blu Capitalisti, giallo Ceto medio, rosso Operai)
	var xs := {Motore.CC: 1274, Motore.MC: 1510, Motore.WC: 1760}
	for c in xs:
		var b: Dictionary = m.G(Motore.ST)["ben"][c]
		var i := 0
		for k in ["soldi", "cibo", "lus", "sal", "ist", "inf"]:
			if int(b.get(k, 0)) > 0:
				risorsa("ben%d%s" % [c, k], k, int(b[k]), px(xs[c] - 50 + (i % 2) * 100, 730 + (i / 2) * 85))
				i += 1
		if int(b.get("cubi", 0)) > 0:
			scritta("bencubi%d" % c, "+%d cubi" % int(b["cubi"]), px(xs[c], 840, 0.2), 44)

# ---------------------------------------------------------------- plance
func _pop_frazione(n: int, x0: float, passo: float, x_icona: float, larg: float) -> float:
	if n < 10:
		return x_icona / larg
	return (x0 + (mini(n, 30) - 10) * passo) / larg

func _plancia_operai() -> void:
	var c := Motore.WC
	var g := m.G(c)
	var n := m.lavoratori(c).size()
	gettone("popWC", "", pb(c, _pop_frazione(n, 78, 38.9, 42, 900), 159.0 / 515.0), 0.2, Color("#f2f2f2"))
	gettone("prospWC", "", pb(c, (52 + 55.1 * int(g["prosp"])) / 900.0, 312.0 / 515.0), 0.24, Color("#f2f2f2"))
	risorsa("soldiWC", "soldi", int(g["soldi"]), pb(c, 762.0 / 900.0, 305.0 / 515.0))
	var k := 0
	for r in Dati.RISORSE:
		risorsa("beniWC" + r, r, int(g["beni"][r]), pb(c, (690 + 48 * k) / 900.0, 440.0 / 515.0))
		k += 1
	var xs := {"agr": 91, "lus": 210, "sal": 329, "ist": 448, "med": 567}
	for ind in xs:
		var wid: String = g["sind"][ind]
		if wid != "":
			lavoratore(wid, m.lav(wid), pb(c, xs[ind] / 900.0, 430.0 / 515.0))

func _plancia_ceto_medio() -> void:
	var c := Motore.MC
	var g := m.G(c)
	var n := m.lavoratori(c).size()
	gettone("popMC", "", pb(c, _pop_frazione(n, 64, 40, 34, 900), 122.0 / 505.0), 0.2, Color("#f2f2f2"))
	gettone("prospMC", "", pb(c, (47 + 54.6 * int(g["prosp"])) / 900.0, 246.0 / 505.0), 0.24, Color("#f2f2f2"))
	risorsa("soldiMC", "soldi", int(g["soldi"]), pb(c, 762.0 / 900.0, 265.0 / 505.0))
	var k := 0
	for r in Dati.RISORSE:
		risorsa("beniMC" + r, r, int(g["beni"][r]), pb(c, (690 + 48 * k) / 900.0, 425.0 / 505.0))
		k += 1
	_magazzini(c, {"cibo": [43, 91, 139], "lus": [196, 243, 290], "sal": [348, 395, 442], "ist": [500, 548, 595]}, 375.0, 450.0, 505.0)

func _magazzini(c: int, caselle: Dictionary, y_ris: float, y_prezzo: float, alt: float) -> void:
	var g := m.G(c)
	for r in caselle:
		var xx: Array = caselle[r]
		risorsa("mag%d%s" % [c, r], r, int(g["mag"][r]), pb(c, float(xx[1]) / 900.0, y_ris / alt))
		var livelli := [9, 12, 15] if r == "cibo" else [5, 8, 10]
		var j := maxi(0, livelli.find(int(g["prezzi"][r])))
		gettone("prezzo%d%s" % [c, r], "", pb(c, float(xx[j]) / 900.0, y_prezzo / alt), 0.13, Color("#111"))
		if g["extra"].get(r, false):
			scritta("extra%d%s" % [c, r], "+ magazzino", pb(c, float(xx[1]) / 900.0, (y_ris - 60) / alt, 0.1), 34, Color("#f6b33c"))

func _plancia_capitalisti() -> void:
	var c := Motore.CC
	var g := m.G(c)
	risorsa("introiti", "soldi", int(g["rev"]), pb(c, 229.0 / 900.0, 165.0 / 505.0))
	risorsa("capitale", "soldi", int(g["cap"]), pb(c, 670.0 / 900.0, 165.0 / 505.0))
	var liv := int(g["ricchezza"])
	var xw := 42.0 if liv == 0 else 96.0 + (liv - 1) * 54.4
	gettone("ricchezza", "", pb(c, xw / 900.0, 255.0 / 505.0), 0.2, Color("#f2f2f2"))
	_magazzini(c, {"cibo": [47, 97, 147], "lus": [224, 274, 324], "sal": [401, 451, 501], "ist": [577, 627, 677]}, 385.0, 450.0, 505.0)
	risorsa("infCC", "inf", int(g["inf"]), pb(c, 804.0 / 900.0, 385.0 / 505.0))
	var ftz := "Zona franca: %d Cibo, %d Lusso" % [int(g["ftz"]["cibo"]), int(g["ftz"]["lus"])]
	scritta("ftz", ftz, pb(c, 0.5, 1.14, 0.1), 46, Color("#9fd0f0"))
	# mercato delle aziende sopra la plancia
	var merc: Array = g["mercato"]
	for i in merc.size():
		carta("mercCC%d" % i, "res://assets/carte3d/%s.webp" % merc[i], CENTRO_PLANCIA[c] + Vector3(-3.4 + i * 2.2, ALTO, -5.75), Vector2(2.0, 2.78), "azienda_m:" + str(merc[i]))
	var mm: Array = m.G(Motore.MC)["mercato"]
	for i in mm.size():
		carta("mercMC%d" % i, "res://assets/carte3d/%s.webp" % mm[i], CENTRO_PLANCIA[0] + Vector3(1.1 + i * 2.2, ALTO, -5.75), Vector2(2.0, 2.78), "azienda_m:" + str(mm[i]))
	scritta("mercCC", "MERCATO", CENTRO_PLANCIA[c] + Vector3(-5.2, 0.2, -5.75), 40, Color("#9fd0f0"))
	scritta("mercMC", "MERCATO", CENTRO_PLANCIA[0] + Vector3(-2.6, 0.2, -5.75), 40, Color("#ffe08a"))

func _plancia_stato() -> void:
	var c := Motore.ST
	var g := m.G(c)
	var ys := {Motore.WC: 158.0, Motore.MC: 216.0, Motore.CC: 272.0}
	for k in ys:
		var l := clampi(int(g["leg"][k]), 1, 10)
		gettone("leg%d" % k, "res://assets/3d/classe_%s.png" % Dati.CLASSI[k], pb(c, (97 + 57 * (l - 1)) / 900.0, ys[k] / 505.0), 0.22, Dati.COLORI[Dati.CLASSI[k]])
		var t := int(g["tok"][k])
		for j in mini(t, 4):
			gettone("tok%d_%d" % [k, j], "res://assets/3d/gettone_%s.png" % Dati.CLASSI[k], pb(c, 1.035, ys[k] / 505.0, 0.11 * j), 0.24, Dati.COLORI[Dati.CLASSI[k]])
	risorsa("magSTcibo", "cibo", int(g["mag"]["cibo"]), pb(c, 166.0 / 900.0, 405.0 / 505.0))
	risorsa("magSTlus", "lus", int(g["mag"]["lus"]), pb(c, 445.0 / 900.0, 405.0 / 505.0))
	risorsa("infST", "inf", int(g["inf"]), pb(c, 724.0 / 900.0, 405.0 / 505.0))
	if int(g["agenda"]) >= 0:
		carta("agenda", "res://assets/carte3d/g%02d.webp" % int(g["agenda"]), CENTRO_PLANCIA[c] + Vector3(-4.2, ALTO, 5.6), Vector2(2.1, 2.92), "agenda")

# ================================================================ camera e input
func _aggiorna_camera() -> void:
	pitch = clampf(pitch, deg_to_rad(18), deg_to_rad(89))
	dist = clampf(dist, 6.0, 70.0)
	bersaglio.x = clampf(bersaglio.x, -26, 26)
	bersaglio.z = clampf(bersaglio.z, -20, 18)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	cam.position = bersaglio + dir * dist
	cam.look_at(bersaglio, Vector3.UP)

func reimposta_camera() -> void:
	bersaglio = Vector3(0, 0, 3.5)
	yaw = 0.0
	pitch = deg_to_rad(63.0)
	dist = 45.0
	_aggiorna_camera()

func vista(nome: String) -> void:
	match nome:
		"tabellone":
			bersaglio = Vector3(0, 0, -1)
			yaw = 0.0
			pitch = deg_to_rad(80)
			dist = 33.0
		"plance":
			bersaglio = Vector3(0, 0, -6)
			yaw = 0.0
			pitch = deg_to_rad(62)
			dist = 44.0
	_aggiorna_camera()

func _pan(delta: Vector2) -> void:
	var s := dist * 0.0013
	var destra := Vector3(cos(yaw), 0, -sin(yaw))
	var avanti := Vector3(sin(yaw), 0, cos(yaw))
	bersaglio -= destra * delta.x * s
	bersaglio -= avanti * delta.y * s
	_aggiorna_camera()

func _zoom(f: float) -> void:
	dist *= f
	_aggiorna_camera()

func _ruota(dyaw: float, dpitch: float) -> void:
	yaw += dyaw
	pitch += dpitch
	_aggiorna_camera()

## Chiamato dal contenitore dell'interfaccia con la posizione nel viewport 3D.
func gestisci(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			tocchi[ev.index] = ev.position
			if tocchi.size() == 1:
				mosso = 0.0
		else:
			if tocchi.size() == 1 and mosso < 12.0:
				_scegli(ev.position)
			tocchi.erase(ev.index)
		return
	if ev is InputEventScreenDrag:
		if not tocchi.has(ev.index):
			tocchi[ev.index] = ev.position
		var prima: Vector2 = tocchi[ev.index]
		var pos: Vector2 = ev.position
		var rel: Vector2 = ev.relative
		if tocchi.size() == 1:
			mosso += rel.length()
			_pan(rel)
		elif tocchi.size() >= 2:
			mosso += 100.0
			var altri := tocchi.keys().filter(func(k): return k != ev.index)
			var altro: Vector2 = tocchi[altri[0]]
			var d0 := prima.distance_to(altro)
			var d1 := pos.distance_to(altro)
			if d0 > 1.0 and d1 > 1.0:
				_zoom(d0 / d1)
			var a0 := (prima - altro).angle()
			var a1 := (pos - altro).angle()
			var da := wrapf(a1 - a0, -PI, PI)
			_ruota(-da, 0.0)
			# due dita che salgono o scendono insieme inclinano la vista
			_ruota(0.0, rel.y * 0.002)
		tocchi[ev.index] = pos
		return
	if ev is InputEventMouseButton:
		if ev.device == InputEvent.DEVICE_ID_EMULATION:
			return
		match ev.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if ev.pressed:
					_zoom(0.9)
			MOUSE_BUTTON_WHEEL_DOWN:
				if ev.pressed:
					_zoom(1.11)
			MOUSE_BUTTON_LEFT:
				if ev.pressed:
					mosso = 0.0
				elif mosso < 6.0:
					_scegli(ev.position)
		return
	if ev is InputEventMagnifyGesture:
		_zoom(1.0 / ev.factor)
		return
	if ev is InputEventPanGesture:
		_pan(-ev.delta * 8.0)
		return
	if ev is InputEventMouseMotion:
		if ev.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if ev.button_mask & MOUSE_BUTTON_MASK_LEFT:
			mosso += ev.relative.length()
			_pan(ev.relative)
		elif ev.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			_ruota(-ev.relative.x * 0.006, ev.relative.y * 0.004)

func _scegli(pos: Vector2) -> void:
	var o := cam.project_ray_origin(pos)
	var n := cam.project_ray_normal(pos)
	if absf(n.y) < 0.001:
		return
	var t := (ALTO - o.y) / n.y
	var p := o + n * t
	var q := Vector2(p.x, p.z)
	for i in range(zone.size() - 1, -1, -1):
		if (zone[i]["r"] as Rect2).has_point(q):
			dettagli.emit(zone[i]["t"])
			return
