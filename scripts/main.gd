## Interfaccia di Hegemony: menu, tavolo di gioco, scelte, partite online e salvataggi.
extends Node

const F_REG := preload("res://assets/font/Montserrat-Regular.ttf")
const F_SEMI := preload("res://assets/font/Montserrat-SemiBold.ttf")
const F_BOLD := preload("res://assets/font/Montserrat-Bold.ttf")
const F_NERO := preload("res://assets/font/Montserrat-ExtraBold.ttf")

const C_FONDO := Color("#1f242b")
const C_PANNELLO := Color("#2b3139")
const C_PANNELLO2 := Color("#353c46")
const C_BORDO := Color("#f0a72e")
const C_ORO := Color("#f6b33c")
const C_TESTO := Color("#eef0f2")
const C_SPENTO := Color("#9aa3ad")
const C_CARTA := Color("#f4f4f2")
const C_SCURO := Color("#2a2e33")
const SALVA_LOCALE := "user://partita_hegemony.txt"
const ICONE := ["cibo", "lus", "sal", "ist", "inf", "soldi", "vp", "prosp", "mac"]

var ui: CanvasLayer
var schermo: Control
var net: Rete
var m: Motore
var ia: IA

var in_partita := false
var online := false
var codice := ""
var mio_posto := 0
var posti := [0, -1, -1, -1]      # per classe: posto online (-1 = IA); in locale 0 = umano
var attesa_ia := 0.0
var velocita := 1.0
var mostrata := -1
var aspetto_rete := false
var ultimo_umano := -1
var salvataggio_in_corso := false
var ultimo_salvataggio := 0.0
var cambio_mostrato := -1
var eventi_visti := 0
var scelta_umani := [true, false, false, false]
var scelta_facile := false

# riferimenti del tavolo
var top_info: Label
var top_round: HBoxContainer
var col_pol: VBoxContainer
var col_mercato: VBoxContainer
var col_eventi: VBoxContainer
var tavolo: VBoxContainer
var col_giocatori: VBoxContainer
var pannello_scelte: VBoxContainer
var titolo_scelte: RichTextLabel
var mano_box: HBoxContainer
var mano_titolo: Label
var diario: RichTextLabel
var diario_box: PanelContainer
var banner: PanelContainer
var zoom_layer: Control
var tavolo3d: Tavolo3D
var vista3d: SubViewportContainer
var pan_sx: Control
var pan_sc: Control
var pan_mano: Control
var info3d: PanelContainer

func _ready() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	schermo = Control.new()
	schermo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.theme = _tema()
	ui.add_child(schermo)
	net = Rete.new()
	add_child(net)
	ia = IA.new()
	mostra_menu()

func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = F_SEMI
	t.default_font_size = 15
	return t

# ================================================================ mattoni grafici
func stile(bg: Color, bordo := Color(0, 0, 0, 0), spessore := 0, raggio := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s

func etichetta(testo: String, font: Font = F_SEMI, size := 15, col := C_TESTO) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func testo_lungo(testo: String, size := 14, col := C_TESTO) -> Label:
	var l := etichetta(testo, F_REG, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func ricco(bb: String, size := 14, col := C_TESTO) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_override("normal_font", F_REG)
	r.add_theme_font_override("bold_font", F_BOLD)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", col)
	r.text = bb
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func bottone(testo: String, cb: Callable, col := Color("#3a424d"), size := 15) -> Button:
	var b := Button.new()
	b.text = testo
	b.add_theme_font_override("font", F_BOLD)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", C_TESTO)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", stile(col, col.lightened(0.25), 1, 7))
	b.add_theme_stylebox_override("hover", stile(col.lightened(0.15), C_ORO, 2, 7))
	b.add_theme_stylebox_override("pressed", stile(col.darkened(0.2), C_ORO, 2, 7))
	b.add_theme_stylebox_override("disabled", stile(col.darkened(0.4), col, 1, 7))
	b.add_theme_stylebox_override("focus", stile(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 7))
	b.pressed.connect(cb)
	return b

func pannello(bg := C_PANNELLO, bordo := Color(1, 1, 1, 0.08), spessore := 1) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stile(bg, bordo, spessore, 10))
	return p

func immagine(path: String, w: float, h: float, modo := TextureRect.STRETCH_KEEP_ASPECT_COVERED) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = modo
	t.custom_minimum_size = Vector2(w, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func icona(nome: String, d := 18.0, col := Color.WHITE) -> TextureRect:
	var t := immagine("res://assets/icone/%s.png" % nome, d, d, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	t.modulate = col
	return t

## Sostituisce i segnaposto {cibo} {V} {VP}... con le icone.
func testo_icone(t: String, size := 14) -> String:
	var d := size + 2
	var o := t
	for k in ["cibo", "lus", "sal", "ist", "inf", "mac"]:
		o = o.replace("{%s}" % k, "[img=%d]res://assets/icone/%s.png[/img]" % [d, k])
	o = o.replace("{V}", "[img=%d]res://assets/icone/soldi.png[/img]" % d)
	o = o.replace("{VP}", " [img=%d]res://assets/icone/vp.png[/img]" % d)
	return o

func pulisci() -> void:
	for c in schermo.get_children():
		c.queue_free()
	in_partita = false

func titolo_sezione(t: String, col := C_ORO) -> Label:
	var l := etichetta(t.to_upper(), F_NERO, 13, col)
	return l

func meeple(sk: String, classe: int, d := 22.0, impegnato := false, vuoto := false) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(d, d + 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := icona("lavoratore", d, Dati.COLORI_IND[sk])
	if vuoto:
		t.modulate = Color(Dati.COLORI_IND[sk], 0.28)
	box.add_child(t)
	if not vuoto and classe >= 0:
		var base := ColorRect.new()
		base.color = Dati.COLORI[Dati.CLASSI[classe]]
		base.position = Vector2(2, d)
		base.size = Vector2(d - 4, 4)
		box.add_child(base)
	if impegnato:
		t.rotation_degrees = 90
		t.pivot_offset = Vector2(d / 2, d / 2)
	return box

# ================================================================ menu
func _sfondo_menu() -> void:
	var f := ColorRect.new()
	f.color = C_FONDO
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(f)
	var img := immagine("res://assets/ui/tabellone.webp", 100, 100)
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.modulate = Color(1, 1, 1, 0.22)
	schermo.add_child(img)
	var velo := ColorRect.new()
	velo.color = Color(0.12, 0.14, 0.17, 0.55)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(velo)

func _logo(v: VBoxContainer) -> void:
	var l := etichetta("HEGEMONY", F_REG, 64, Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", 0)
	v.add_child(l)
	var riga := ColorRect.new()
	riga.color = C_ORO
	riga.custom_minimum_size = Vector2(0, 3)
	v.add_child(riga)
	var s := etichetta("CONQUISTA LA SUPREMAZIA POLITICA", F_BOLD, 16, C_ORO)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)

func _riquadro_menu(w: float, h: float) -> VBoxContainer:
	var box := pannello(Color(0.16, 0.18, 0.22, 0.95), Color(C_ORO, 0.5), 2)
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(w, h)
	box.position = Vector2(-w / 2, -h / 2)
	schermo.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	box.add_child(v)
	return v

func mostra_menu() -> void:
	pulisci()
	_sfondo_menu()
	var v := _riquadro_menu(560, 560)
	_logo(v)
	v.add_child(testo_lungo("Quattro classi, un solo Paese: Classe Operaia, Classe Media, Classe Capitalista e Stato si contendono le politiche, l'economia e il consenso.", 15, C_SPENTO))
	v.add_child(bottone("NUOVA PARTITA", _menu_nuova, Color("#8a4b0f"), 20))
	if FileAccess.file_exists(SALVA_LOCALE):
		v.add_child(bottone("CONTINUA LA PARTITA", _continua_locale, Color("#2e5f2e"), 18))
	v.add_child(bottone("RIPRENDI DAL SALVATAGGIO ONLINE", _continua_online, Color("#33465c"), 16))
	v.add_child(bottone("GIOCA ONLINE CON GLI AMICI", _menu_online, Color("#1e5a8a"), 18))
	v.add_child(bottone("REGOLE IN BREVE", _menu_regole, Color("#3a424d"), 16))
	var nota := testo_lungo("Versione digitale non ufficiale per uso personale. Hegemony © Hegemonic Project, edizione italiana Ghenos Games.", 12, C_SPENTO)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)

func _menu_nuova() -> void:
	pulisci()
	_sfondo_menu()
	var v := _riquadro_menu(640, 600)
	v.add_child(etichetta("NUOVA PARTITA", F_NERO, 28, C_ORO))
	v.add_child(testo_lungo("Scegli quali classi guidi tu (una o più, sullo stesso dispositivo): le altre le guida l'IA.", 15, C_SPENTO))
	for i in 4:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 12)
		v.add_child(r)
		var stemma := pannello(Dati.COLORI[Dati.CLASSI[i]], Color(1, 1, 1, 0.2), 1)
		stemma.custom_minimum_size = Vector2(36, 36)
		r.add_child(stemma)
		var nome := etichetta(Dati.NOMI_CLASSE[Dati.CLASSI[i]], F_BOLD, 18)
		nome.custom_minimum_size = Vector2(250, 0)
		r.add_child(nome)
		var b := bottone("TU" if scelta_umani[i] else "IA", func(): pass, Color("#8a4b0f") if scelta_umani[i] else Color("#3a424d"), 16)
		b.custom_minimum_size = Vector2(120, 0)
		b.pressed.connect(func():
			scelta_umani[i] = not scelta_umani[i]
			_menu_nuova())
		r.add_child(b)
	var rf := HBoxContainer.new()
	v.add_child(rf)
	rf.add_child(etichetta("Avversari IA:", F_BOLD, 16))
	var bf := bottone("FACILI" if scelta_facile else "NORMALI", func():
		scelta_facile = not scelta_facile
		_menu_nuova(), Color("#3a424d"), 15)
	rf.add_child(bf)
	v.add_child(testo_lungo("Partita completa a 4 classi: 5 round, eventi, agenda politica dello Stato, FMI e prestiti.", 14, C_SPENTO))
	v.add_child(bottone("INIZIA", _avvia_locale, Color("#8a4b0f"), 22))
	v.add_child(bottone("INDIETRO", mostra_menu))

func _avvia_locale() -> void:
	online = false
	posti = []
	var flags := []
	for i in 4:
		posti.append(0 if scelta_umani[i] else -1)
		flags.append(not scelta_umani[i])
	m = Motore.new()
	m.nuova_partita({"seme": int(Time.get_unix_time_from_system()) % 1000000 + randi() % 1000, "ia": flags})
	m.s["posti"] = posti.duplicate()
	m.s["facile"] = scelta_facile
	ia.facile = scelta_facile
	_apri_partita()
	_salva(true)

func _continua_locale() -> void:
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.READ)
	if f == null:
		return
	var st = str_to_var(f.get_as_text())
	if not (st is Dictionary):
		_avviso("Salvataggio illeggibile.")
		return
	_carica_stato(st)

func _carica_stato(st: Dictionary) -> void:
	online = false
	m = Motore.new()
	m.carica(st)
	posti = st.get("posti", [0, -1, -1, -1])
	ia.facile = bool(st.get("facile", false))
	_apri_partita()

func _continua_online() -> void:
	_avviso("Cerco il salvataggio online...")
	var st := await net.carica_partita()
	if st.is_empty() or not st.has("v"):
		_avviso("Nessuna partita salvata online. " + net.last_error)
		return
	var dati = str_to_var(str(st["v"]))
	if not (dati is Dictionary):
		_avviso("Salvataggio online illeggibile.")
		return
	_carica_stato(dati)

func _avviso(t: String) -> void:
	var p := pannello(Color(0.1, 0.1, 0.12, 0.96), C_ORO, 2)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.position = Vector2(-300, 70)
	p.custom_minimum_size = Vector2(600, 0)
	var l := testo_lungo(t, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	schermo.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(3.5)
	tw.tween_callback(p.queue_free)

const REGOLE := """[b]Lo scopo.[/b] Ogni giocatore guida una classe sociale con obiettivi diversi. Dopo 5 round vince chi ha più Punti Vittoria (PV).

[b]Il round.[/b] [b]1. Preparazione[/b] (dal 2° round): interessi sui prestiti, calo della Prosperità, nuovi Eventi e Agenda dello Stato, si pesca fino a 7 carte, nuove Aziende, Accordi Commerciali ed Export, nuovi lavoratori (più immigrati secondo la Politica 7). [b]2. Azioni[/b]: 5 turni ciascuno, nell'ordine Classe Operaia, Classe Media, Classe Capitalista, Stato. In ogni turno si gioca una carta per il suo effetto (se il requisito è soddisfatto) oppure la si scarta per un'Azione base; in più si può fare un'Azione gratuita prima o dopo. [b]3. Produzione[/b]: le aziende pagano i salari e producono, la popolazione consuma Cibo, si controlla il FMI, si pagano le tasse. [b]4. Elezioni[/b]: si vota ogni Legge proposta. [b]5. Punteggio[/b].

[b]Le Leggi.[/b] Si propone di spostare una Politica nella sezione adiacente. Al voto ogni classe si dichiara favorevole o contraria, si pescano 5 cubi dal sacchetto (ogni cubo è un voto della sua classe), poi ognuno può spendere Influenza in segreto per aggiungere voti. A parità vince chi propone. Chi propone una legge approvata guadagna 3 PV, chi l'ha sostenuta con almeno un voto 1 PV. Con 1 Influenza si può chiedere la Votazione Immediata.

[b]Classe Operaia.[/b] Lavora nelle aziende degli altri per il salario, compra Cibo, Salute, Istruzione e Lusso: usarli (in quantità pari alla Popolazione) fa salire la Prosperità, che dà PV pari al nuovo valore. Sindacati, scioperi e manifestazioni. A fine partita PV per le Politiche in sezione A.
[b]Classe Media.[/b] Ha piccole aziende proprie e lavoratori nelle aziende altrui; vende beni, consuma, esporta (1 PV per transazione). PV per le Politiche in sezione B.
[b]Classe Capitalista.[/b] Costruisce aziende, paga salari, vende ai cittadini e all'estero. Nel Punteggio il Capitale dà PV secondo la tabella della Ricchezza, più 3 PV per ogni nuovo livello raggiunto. PV per le Politiche in sezione C.
[b]Stato.[/b] Cerca la Legittimità presso le tre classi: nel Punteggio prende PV pari alla somma delle due Legittimità più basse, poi le dimezza. Affronta gli Eventi, fornisce benefici, gestisce i servizi pubblici. PV per l'Agenda Politica.

[b]Prestiti.[/b] Se non si può pagare un costo obbligatorio si prende un Prestito da 50 (5 di interessi a round). Se lo Stato ha troppi prestiti interviene il FMI e cambia di forza le Politiche."""

func _menu_regole() -> void:
	pulisci()
	_sfondo_menu()
	var v := _riquadro_menu(900, 760)
	v.add_child(etichetta("REGOLE IN BREVE", F_NERO, 26, C_ORO))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(860, 600)
	v.add_child(sc)
	var r := ricco(REGOLE, 15)
	r.custom_minimum_size = Vector2(840, 0)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	sc.add_child(r)
	v.add_child(bottone("INDIETRO", mostra_menu if not in_partita else _chiudi_regole))

func _chiudi_regole() -> void:
	_apri_partita()

# ================================================================ online
var on_nome: LineEdit
var on_codice: LineEdit
var on_stato: Label
var lobby_box: VBoxContainer

func _menu_online() -> void:
	pulisci()
	_sfondo_menu()
	var v := _riquadro_menu(660, 600)
	v.add_child(etichetta("GIOCA ONLINE", F_NERO, 28, C_ORO))
	v.add_child(testo_lungo("Chi crea la stanza guida la Classe Operaia; gli amici che entrano col codice prendono, nell'ordine, Classe Media, Classe Capitalista e Stato. I posti vuoti li guida l'IA.", 15, C_SPENTO))
	var r1 := HBoxContainer.new()
	v.add_child(r1)
	r1.add_child(etichetta("Il tuo nome:", F_BOLD, 16))
	on_nome = LineEdit.new()
	on_nome.custom_minimum_size = Vector2(260, 0)
	on_nome.text = str(net.load_session().get("name", "Cittadino"))
	on_nome.max_length = 18
	r1.add_child(on_nome)
	v.add_child(bottone("CREA UNA STANZA", _online_crea, Color("#8a4b0f"), 20))
	var r2 := HBoxContainer.new()
	v.add_child(r2)
	on_codice = LineEdit.new()
	on_codice.placeholder_text = "CODICE"
	on_codice.max_length = 4
	on_codice.custom_minimum_size = Vector2(130, 0)
	r2.add_child(on_codice)
	r2.add_child(bottone("ENTRA", _online_entra, Color("#1e5a8a"), 18))
	var sess := net.load_session()
	if str(sess.get("room", "")) != "":
		r2.add_child(bottone("RIENTRA IN %s" % sess["room"], func():
			on_codice.text = str(sess["room"])
			_online_entra(), Color("#33465c"), 15))
	on_stato = testo_lungo("", 16, C_ORO)
	v.add_child(on_stato)
	lobby_box = VBoxContainer.new()
	v.add_child(lobby_box)
	v.add_child(bottone("INDIETRO", mostra_menu))

func _online_crea() -> void:
	on_stato.text = "Creo la stanza..."
	net._save({"name": on_nome.text})
	var c := await net.create_room(on_nome.text, {"n": 4})
	if c == "":
		on_stato.text = "Non riesco a creare la stanza: " + net.last_error
		return
	codice = c
	mio_posto = 0
	net.remember_room(c, 0)
	on_stato.text = "Stanza %s creata. Dai il codice agli amici, poi premi INIZIA." % c
	_lobby(true)

func _online_entra() -> void:
	var c := on_codice.text.strip_edges().to_upper()
	if c.length() != 4:
		on_stato.text = "Il codice ha 4 lettere."
		return
	on_stato.text = "Entro nella stanza %s..." % c
	net._save({"name": on_nome.text})
	var p := await net.join_room(c, on_nome.text, 4)
	if p < 0:
		on_stato.text = "Non riesco a entrare (stanza piena, inesistente o già iniziata). " + net.last_error
		return
	codice = c
	mio_posto = p
	net.remember_room(c, p)
	var room := await net.room(c)
	if room.get("status", "") == "playing":
		_avvia_da_stanza(room)
		return
	on_stato.text = "Sei nella stanza %s (%s). Aspetta che chi l'ha creata inizi la partita." % [c, Dati.NOMI_CLASSE[Dati.CLASSI[mini(p, 3)]]]
	_lobby(false)

func _lobby(host: bool) -> void:
	for ch in lobby_box.get_children():
		ch.queue_free()
	var lista := etichetta("", F_REG, 16)
	lobby_box.add_child(lista)
	if host:
		lobby_box.add_child(bottone("INIZIA LA PARTITA", _online_inizia, Color("#8a4b0f"), 20))
	while is_instance_valid(lista) and not in_partita:
		var room := await net.room(codice)
		if not is_instance_valid(lista):
			return
		var seats := Rete._as_dict(room.get("seats", {}))
		var t := "Giocatori nella stanza:\n"
		for k in seats:
			t += "  %s: %s\n" % [Dati.NOMI_CLASSE[Dati.CLASSI[mini(int(k), 3)]], seats[k].get("name", "?")]
		lista.text = t
		if not host and room.get("status", "") == "playing":
			_avvia_da_stanza(room)
			return
		await get_tree().create_timer(1.5).timeout

func _online_inizia() -> void:
	var room := await net.room(codice)
	var seats := Rete._as_dict(room.get("seats", {}))
	var seat_arr := []
	for k in 4:
		seat_arr.append(k if seats.has(str(k)) else -1)
	var game := {"seat": seat_arr, "seme": int(Time.get_unix_time_from_system()) % 1000000}
	if not await net.start_room(codice, game):
		on_stato.text = "Non riesco a iniziare: " + net.last_error
		return
	room["game"] = JSON.stringify(game)
	_avvia_da_stanza(room)

func _avvia_da_stanza(room: Dictionary) -> void:
	var game = JSON.parse_string(str(room.get("game", "{}")))
	if not (game is Dictionary):
		on_stato.text = "Dati della partita illeggibili."
		return
	online = true
	posti = []
	var flags := []
	for k in 4:
		posti.append(int(game["seat"][k]))
		flags.append(int(game["seat"][k]) < 0)
	m = Motore.new()
	m.nuova_partita({"seme": int(game["seme"]), "ia": flags})
	ia.facile = false
	var log := await net.get_decisions(codice, 0)
	var guard := 0
	while not m.s["fine"] and guard < 30000:
		guard += 1
		var a := m.attesa()
		if a.is_empty():
			break
		var posto: int = posti[a["g"]]
		var n_dec: int = m.s["decisioni"]
		if posto < 0:
			m.scegli(ia.scegli(m, a))
		elif log.has(n_dec):
			m.scegli(int(log[n_dec].get("i", 0)))
		else:
			break
	_apri_partita()

# ================================================================ la partita
func umano(i: int) -> bool:
	if i < 0 or i >= posti.size():
		return false
	if online:
		return posti[i] == mio_posto
	return posti[i] >= 0

func io() -> int:
	var a := m.attesa()
	if not a.is_empty() and umano(a["g"]):
		return a["g"]
	if ultimo_umano >= 0:
		return ultimo_umano
	for i in 4:
		if umano(i):
			return i
	return -1

func umani_locali() -> int:
	var n := 0
	for i in 4:
		if umano(i):
			n += 1
	return n

func _apri_partita() -> void:
	pulisci()
	in_partita = true
	mostrata = -1
	cambio_mostrato = -1
	eventi_visti = m.s["eventi"].size()
	var f := ColorRect.new()
	f.color = C_FONDO
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(f)
	# tavolo 3D con tabellone, plance e pedine
	vista3d = SubViewportContainer.new()
	vista3d.position = Vector2(0, 46)
	vista3d.size = Vector2(1212, 854)
	vista3d.stretch = true
	vista3d.mouse_filter = Control.MOUSE_FILTER_STOP
	schermo.add_child(vista3d)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_2X
	sv.handle_input_locally = false
	vista3d.add_child(sv)
	tavolo3d = Tavolo3D.new()
	sv.add_child(tavolo3d)
	tavolo3d.dettagli.connect(_dettagli_3d)
	vista3d.gui_input.connect(func(ev): tavolo3d.gestisci(ev))
	_costruisci_hud()
	_aggiorna_tutto()

func _colonna(x: float, w: float, y: float, h: float) -> Control:
	var c := Control.new()
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)
	schermo.add_child(c)
	return c

func _costruisci_hud() -> void:
	# barra superiore
	var top := pannello(Color("#171a1f"), Color(C_ORO, 0.35), 0)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, 46)
	schermo.add_child(top)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 16)
	top.add_child(th)
	th.add_child(etichetta("HEGEMONY", F_REG, 24, Color.WHITE))
	top_round = HBoxContainer.new()
	top_round.add_theme_constant_override("separation", 4)
	th.add_child(top_round)
	top_info = etichetta("", F_BOLD, 15, C_TESTO)
	top_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(top_info)
	th.add_child(bottone("VISTA", _cambia_vista, Color("#3a424d"), 13))
	th.add_child(bottone("PANNELLI", func(): pan_sx.visible = not pan_sx.visible, Color("#3a424d"), 13))
	th.add_child(bottone("ELENCO", func(): pan_sc.visible = not pan_sc.visible, Color("#3a424d"), 13))
	th.add_child(bottone("MANO", func(): pan_mano.visible = not pan_mano.visible, Color("#3a424d"), 13))
	th.add_child(bottone("DIARIO", _apri_diario, Color("#3a424d"), 13))
	th.add_child(bottone("REGOLE", _menu_regole, Color("#3a424d"), 13))
	th.add_child(bottone("VELOCITÀ IA", _cambia_velocita, Color("#3a424d"), 13))
	th.add_child(bottone("MENU", _menu_partita, Color("#5a3a1a"), 13))
	# colonne: sinistra (politiche, mercato estero, eventi), centro (tavolo + mano), destra (classi + scelte)
	var sx := ScrollContainer.new()
	sx.position = Vector2(6, 52)
	sx.size = Vector2(398, 842)
	sx.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	schermo.add_child(sx)
	pan_sx = sx
	sx.visible = false
	var fondo_sx := StyleBoxFlat.new()
	fondo_sx.bg_color = Color(0.1, 0.11, 0.13, 0.9)
	sx.add_theme_stylebox_override("panel", fondo_sx)
	var vs := VBoxContainer.new()
	vs.custom_minimum_size = Vector2(388, 0)
	vs.add_theme_constant_override("separation", 8)
	sx.add_child(vs)
	col_pol = VBoxContainer.new()
	vs.add_child(col_pol)
	col_eventi = VBoxContainer.new()
	vs.add_child(col_eventi)
	col_mercato = VBoxContainer.new()
	vs.add_child(col_mercato)
	var sc := ScrollContainer.new()
	sc.position = Vector2(410, 52)
	sc.size = Vector2(800, 588)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	schermo.add_child(sc)
	pan_sc = sc
	sc.visible = false
	var fondo_sc := StyleBoxFlat.new()
	fondo_sc.bg_color = Color(0.1, 0.11, 0.13, 0.94)
	sc.add_theme_stylebox_override("panel", fondo_sc)
	tavolo = VBoxContainer.new()
	tavolo.custom_minimum_size = Vector2(788, 0)
	tavolo.add_theme_constant_override("separation", 6)
	sc.add_child(tavolo)
	var mano_p := pannello(Color(0.15, 0.17, 0.2, 0.92), Color(1, 1, 1, 0.06), 1)
	mano_p.position = Vector2(6, 698)
	mano_p.size = Vector2(1204, 196)
	schermo.add_child(mano_p)
	pan_mano = mano_p
	var mv := VBoxContainer.new()
	mano_p.add_child(mv)
	mano_titolo = etichetta("", F_NERO, 13, C_ORO)
	mv.add_child(mano_titolo)
	var ms := ScrollContainer.new()
	ms.custom_minimum_size = Vector2(1184, 172)
	ms.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mv.add_child(ms)
	mano_box = HBoxContainer.new()
	mano_box.add_theme_constant_override("separation", 6)
	ms.add_child(mano_box)
	var dx := ScrollContainer.new()
	dx.position = Vector2(1216, 52)
	dx.size = Vector2(378, 456)
	dx.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	schermo.add_child(dx)
	col_giocatori = VBoxContainer.new()
	col_giocatori.custom_minimum_size = Vector2(366, 0)
	col_giocatori.add_theme_constant_override("separation", 6)
	dx.add_child(col_giocatori)
	var sp := pannello(Color("#262b32"), Color(C_ORO, 0.45), 2)
	sp.position = Vector2(1216, 514)
	sp.size = Vector2(378, 380)
	schermo.add_child(sp)
	var spv := VBoxContainer.new()
	spv.add_theme_constant_override("separation", 6)
	sp.add_child(spv)
	titolo_scelte = ricco("", 15, C_TESTO)
	titolo_scelte.custom_minimum_size = Vector2(356, 0)
	spv.add_child(titolo_scelte)
	var sps := ScrollContainer.new()
	sps.custom_minimum_size = Vector2(358, 296)
	sps.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	spv.add_child(sps)
	pannello_scelte = VBoxContainer.new()
	pannello_scelte.custom_minimum_size = Vector2(346, 0)
	pannello_scelte.add_theme_constant_override("separation", 5)
	sps.add_child(pannello_scelte)
	# diario (nascosto)
	diario_box = pannello(Color(0.1, 0.11, 0.13, 0.97), C_ORO, 2)
	diario_box.position = Vector2(410, 60)
	diario_box.size = Vector2(800, 560)
	diario_box.visible = false
	schermo.add_child(diario_box)
	var dv := VBoxContainer.new()
	diario_box.add_child(dv)
	dv.add_child(bottone("CHIUDI IL DIARIO", func(): diario_box.visible = false, Color("#3a424d"), 13))
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.custom_minimum_size = Vector2(780, 500)
	diario.add_theme_font_override("normal_font", F_REG)
	diario.add_theme_font_size_override("normal_font_size", 14)
	dv.add_child(diario)
	zoom_layer = Control.new()
	zoom_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schermo.add_child(zoom_layer)

func _cambia_vista() -> void:
	var v: int = (int(get_meta("vista", 0)) + 1) % 3
	set_meta("vista", v)
	match v:
		0:
			tavolo3d.reimposta_camera()
		1:
			tavolo3d.vista("tabellone")
		2:
			tavolo3d.vista("plance")

## Clic su una carta o una plancia del tavolo 3D: dettagli in italiano.
func _dettagli_3d(chiave: String) -> void:
	var parti := chiave.split(":")
	var t := ""
	match parti[0]:
		"azienda", "azienda_m":
			t = _tooltip_azienda(parti[1]) if m.s["aziende"].has(parti[1]) else _scheda_azienda(parti[1])
		"evento":
			var e := Dati.evento(parti[1])
			t = "%s\n%s" % [e["it"].to_upper(), m._testo_semplice(e["t"])]
		"export":
			var x: Dictionary = Dati.d()["export"][int(m.s["export"])]
			var righe := []
			for r in Dati.RISORSE:
				righe.append("%s: %d per %d, oppure %d per %d" % [Dati.NOMI_RIS[r], int(x[r][0][0]), int(x[r][0][1]), int(x[r][1][0]), int(x[r][1][1])])
			t = "CARTA EXPORT (vendite al Mercato Estero)\n" + "\n".join(righe)
		"accordo":
			var a: Dictionary = Dati.d()["accordi"][int(parti[1])]
			t = "ACCORDO COMMERCIALE: %d Cibo, %d Lusso per %d (dazio %d)" % [int(a["cibo"]), int(a["lus"]), int(a["costo"]), int(a["dazio"][m.polx(5)])]
		"agenda":
			t = "AGENDA POLITICA DELLO STATO: %d corrispondenze con le Politiche attuali (1 PV ciascuna nel Punteggio)." % m.agenda_corrispondenze()
		"disoccupati":
			t = "LAVORATORI DISOCCUPATI: %d della Classe Operaia, %d della Classe Media." % [m.disoccupati(0).size(), m.disoccupati(1).size()]
		"plancia":
			t = _testo_plancia(int(parti[1]))
	if t != "":
		_mostra_info(t)

func _scheda_azienda(aid: String) -> String:
	var d := Dati.az(aid)
	var t := "%s (%s) - costo %d\nProduce %d %s" % [d["n"], Dati.NOMI_IND[d["ind"]], int(d["costo"]), int(d["prod"]), Dati.NOMI_RIS[Dati.RIS_IND[d["ind"]]]]
	if not d["auto"] and int(d["sal"][0]) > 0:
		t += "\nSalari L1/L2/L3: %d/%d/%d" % [int(d["sal"][0]), int(d["sal"][1]), int(d["sal"][2])]
	return t

func _testo_plancia(c: int) -> String:
	var g := m.G(c)
	var t := "%s - %d PV\nDenaro %d, Influenza %d, Prestiti %d" % [m.nome(c).to_upper(), int(g["vp"]), m.soldi(c), int(g["inf"]), int(g["prestiti"])]
	if c in [0, 1]:
		t += "\nPopolazione %d (%d lavoratori), Prosperità %d" % [m.popolazione(c), m.lavoratori(c).size(), int(g["prosp"])]
	if c == 2:
		t += "\nIntroiti %d, Capitale %d, livello di Ricchezza %d" % [int(g["rev"]), int(g["cap"]), int(g["ricchezza"])]
	if c == 3:
		t += "\nLegittimità: Operai %d, Ceto medio %d, Capitalisti %d" % [int(g["leg"][0]), int(g["leg"][1]), int(g["leg"][2])]
	return t

func _mostra_info(t: String) -> void:
	if info3d != null and is_instance_valid(info3d):
		info3d.queue_free()
	info3d = pannello(Color(0.08, 0.09, 0.11, 0.95), C_ORO, 2)
	info3d.position = Vector2(330, 60)
	info3d.custom_minimum_size = Vector2(560, 0)
	var v := VBoxContainer.new()
	info3d.add_child(v)
	var l := testo_lungo(t, 16)
	l.custom_minimum_size = Vector2(540, 0)
	v.add_child(l)
	v.add_child(bottone("CHIUDI", func(): info3d.queue_free(), Color("#3a424d"), 13))
	schermo.add_child(info3d)

func _apri_diario() -> void:
	diario_box.visible = not diario_box.visible
	_aggiorna_diario()

func _cambia_velocita() -> void:
	velocita = {1.0: 3.0, 3.0: 12.0, 12.0: 0.5, 0.5: 1.0}.get(velocita, 1.0)
	_avviso("Velocità dell'IA: %s" % {1.0: "normale", 3.0: "veloce", 12.0: "velocissima", 0.5: "lenta"}[velocita])

func _menu_partita() -> void:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.75)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(velo)
	var v := VBoxContainer.new()
	v.position = Vector2(620, 300)
	v.custom_minimum_size = Vector2(360, 0)
	v.add_theme_constant_override("separation", 10)
	velo.add_child(v)
	v.add_child(bottone("TORNA ALLA PARTITA", func(): velo.queue_free(), Color("#2e5f2e"), 18))
	if not online:
		v.add_child(bottone("SALVA ANCHE ONLINE", func():
			velo.queue_free()
			_salva(true)
			_avviso("Partita salvata su questo dispositivo e online."), Color("#33465c"), 16))
	v.add_child(bottone("ESCI AL MENU", func():
		if not online:
			_salva(true)
		mostra_menu(), Color("#5a3a1a"), 16))

# ---------------------------------------------------------------- ciclo
func _process(delta: float) -> void:
	if not in_partita or m == null:
		return
	_effetti_nuovi()
	if m.s["fine"]:
		if mostrata != -2:
			mostrata = -2
			_aggiorna_tutto()
			_mostra_fine()
		return
	var a := m.attesa()
	if a.is_empty():
		return
	var g: int = a["g"]
	if posti[g] < 0:
		attesa_ia += delta * velocita
		var pausa := 0.9 if a.get("tipo", "") == "turno" else 0.35
		if attesa_ia >= pausa:
			attesa_ia = 0.0
			titolo_scelte.text = "[b]%s[/b] sta decidendo..." % m.nome(g)
			var k := ia.scegli(m, a)
			m.scegli(k)
			_aggiorna_tutto()
			if not online:
				_salva(false)
	elif umano(g):
		var n: int = m.s["decisioni"]
		if mostrata != n:
			if not online and umani_locali() > 1 and ultimo_umano >= 0 and ultimo_umano != g and cambio_mostrato != n and _decisione_privata(a):
				cambio_mostrato = n
				_passa_dispositivo(g)
				return
			if cambio_mostrato == n and has_meta("cambio_aperto"):
				return
			mostrata = n
			ultimo_umano = g
			_aggiorna_tutto()
			_mostra_scelte(a)
	elif online and not aspetto_rete:
		titolo_scelte.text = "Aspetto la mossa di [b]%s[/b]..." % m.nome(g)
		_aspetta_remoto()

func _decisione_privata(a: Dictionary) -> bool:
	return a.get("tipo", "") in ["turno", "scarta", "base", "influenza"]

func _passa_dispositivo(g: int) -> void:
	set_meta("cambio_aperto", true)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.94)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(velo)
	var v := VBoxContainer.new()
	v.position = Vector2(560, 330)
	v.custom_minimum_size = Vector2(480, 0)
	velo.add_child(v)
	var l := etichetta("Tocca a: %s" % m.nome(g), F_NERO, 32, Dati.COLORI[Dati.CLASSI[g]])
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	v.add_child(testo_lungo("Passa il dispositivo: la mano resta nascosta finché non premi il pulsante.", 17))
	v.add_child(bottone("SONO PRONTO", func():
		remove_meta("cambio_aperto")
		velo.queue_free()
		ultimo_umano = g
		mostrata = -1, Color("#8a4b0f"), 22))

func _aspetta_remoto() -> void:
	aspetto_rete = true
	var n: int = m.s["decisioni"]
	var d = await net.get_decision(codice, n)
	if d is Dictionary and d.has("i") and int(m.s["decisioni"]) == n:
		m.scegli(int(d["i"]))
		_aggiorna_tutto()
	else:
		await get_tree().create_timer(1.0).timeout
	aspetto_rete = false

func _decidi(i: int) -> void:
	_chiudi_zoom()
	for c in pannello_scelte.get_children():
		if c is Button:
			c.disabled = true
	if online:
		var n: int = m.s["decisioni"]
		var ok := await net.post_decision(codice, n, {"i": i})
		if not ok:
			_avviso("Rete: non riesco a inviare la mossa (" + net.last_error + "). Riprova.")
			mostrata = -1
			return
	m.scegli(i)
	_aggiorna_tutto()
	if not online:
		_salva(false)

func _salva(subito: bool) -> void:
	if online or m == null:
		return
	m.s["posti"] = posti.duplicate()
	var testo := var_to_str(m.s)
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.WRITE)
	if f:
		f.store_string(testo)
		f.close()
	var ora := Time.get_unix_time_from_system()
	if (subito or ora - ultimo_salvataggio > 45.0) and not salvataggio_in_corso:
		ultimo_salvataggio = ora
		salvataggio_in_corso = true
		await net.salva_partita({"v": testo})
		salvataggio_in_corso = false

# ---------------------------------------------------------------- scelte
func _mostra_scelte(a: Dictionary) -> void:
	for c in pannello_scelte.get_children():
		c.queue_free()
	var g: int = a["g"]
	var col: Color = Dati.COLORI[Dati.CLASSI[g]]
	titolo_scelte.text = "[color=#%s][b]%s[/b][/color]\n%s" % [col.lightened(0.25).to_html(false), m.nome(g).to_upper(), testo_icone(str(a["testo"]), 14)]
	var ops: Array = a["opzioni"]
	for i in ops.size():
		var o: Dictionary = ops[i]
		var testo := str(o["t"])
		var tinta := Color("#3a424d")
		if testo.begins_with("Gioca:"):
			tinta = col.darkened(0.45)
		elif testo.begins_with("Fine turno") or testo.begins_with("Basta") or testo.begins_with("No"):
			tinta = Color("#2f343b")
		var b := bottone(testo, _decidi.bind(i), tinta, 14)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pannello_scelte.add_child(b)
	_aggiorna_mano()

# ================================================================ aggiornamento grafico
func _aggiorna_tutto() -> void:
	if not in_partita:
		return
	_aggiorna_top()
	_aggiorna_politiche()
	_aggiorna_eventi()
	_aggiorna_mercato()
	_aggiorna_tavolo()
	if tavolo3d != null:
		tavolo3d.aggiorna(m)
	_aggiorna_giocatori()
	_aggiorna_mano()
	if diario_box.visible:
		_aggiorna_diario()
	var a := m.attesa()
	if not a.is_empty() and not umano(a["g"]):
		for c in pannello_scelte.get_children():
			c.queue_free()

const NOMI_FASI := {"preparazione": "Preparazione", "azioni": "Azioni", "produzione": "Produzione", "elezioni": "Elezioni", "punteggio": "Punteggio", "fine": "Fine partita"}

func _aggiorna_top() -> void:
	for c in top_round.get_children():
		c.queue_free()
	for r in range(1, 6):
		var p := pannello(C_ORO if r == int(m.s["round"]) else Color("#3a424d"), Color(1, 1, 1, 0.1), 1)
		p.custom_minimum_size = Vector2(28, 28)
		var l := etichetta(str(r), F_NERO, 14, C_SCURO if r == int(m.s["round"]) else C_SPENTO)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		top_round.add_child(p)
	var fase: String = NOMI_FASI.get(m.s["fase"], m.s["fase"])
	var t := "Round %d • %s" % [int(m.s["round"]), fase]
	if m.s["fase"] == "azioni":
		t += " • turno %d di 5 • tocca a %s" % [int(m.s["turno"]) + 1, m.nome(int(m.s["attivo"]))]
	t += "   |   Moltiplicatore tasse: %d" % m.moltiplicatore()
	top_info.text = t

const EFFETTI_POL := [
	["9 aziende pubbliche, FMI con 2 prestiti", "6 aziende pubbliche, FMI con 2 prestiti", "3 aziende pubbliche, FMI con 1 prestito"],
	["Salario minimo L3", "Salario minimo L2", "Salario minimo L1"],
	["Moltiplicatore base 3, welfare x2", "Moltiplicatore base 2, welfare x1", "Moltiplicatore base 1, welfare x0"],
	["Sanità gratuita, +2 molt.", "Sanità a 5, +1 molt.", "Sanità a 10"],
	["Istruzione gratuita, +2 molt.", "Istruzione a 5, +1 molt.", "Istruzione a 10"],
	["Dazi alti (cibo +10, lusso +6), 0 accordi", "Dazi medi (+5/+3), 1 accordo", "Nessun dazio, 2 accordi"],
	["Nessun immigrato", "1 immigrato per classe", "2 immigrati per classe"],
]

func _aggiorna_politiche() -> void:
	for c in col_pol.get_children():
		c.queue_free()
	var p := pannello(C_PANNELLO, Color(C_ORO, 0.3), 1)
	col_pol.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var h := HBoxContainer.new()
	v.add_child(h)
	var t := titolo_sezione("Tabella politica")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(etichetta("A SOCIALISMO · B CENTRO · C NEOLIBERISMO", F_BOLD, 9, C_SPENTO))
	var ag := []
	if m.G(Motore.ST)["agenda"] >= 0:
		ag = Dati.d()["agende"][int(m.G(Motore.ST)["agenda"])]
	for k in 7:
		var riga := HBoxContainer.new()
		riga.add_theme_constant_override("separation", 3)
		v.add_child(riga)
		var num := pannello(Dati.COLORI_POL[k], Color(1, 1, 1, 0.15), 1)
		num.custom_minimum_size = Vector2(26, 44)
		num.tooltip_text = Dati.POLITICHE[k]
		var nl := etichetta(str(k + 1), F_NERO, 18, Color.WHITE)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.add_child(nl)
		riga.add_child(num)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 1)
		riga.add_child(cv)
		cv.add_child(etichetta(Dati.POLITICHE[k].to_upper(), F_BOLD, 10, C_SPENTO))
		var sezioni := HBoxContainer.new()
		sezioni.add_theme_constant_override("separation", 3)
		cv.add_child(sezioni)
		var pr = m.s["prop"][k]
		for x in 3:
			var sez: String = Dati.SEZ[x]
			var attiva: bool = m.pol(k) == sez
			var colore: Color = Dati.COLORI_POL[k] if attiva else Color(Dati.COLORI_POL[k], 0.22)
			var bordo := Color(1, 1, 1, 0.05)
			var sp := 1
			if pr != null and str(pr["sez"]) == sez:
				bordo = Dati.COLORI[Dati.CLASSI[int(pr["c"])]]
				sp = 3
			var cella := pannello(colore, bordo, sp)
			cella.custom_minimum_size = Vector2(110, 30)
			cella.tooltip_text = "%d%s: %s" % [k + 1, sez, EFFETTI_POL[k][x]]
			var cl := HBoxContainer.new()
			cella.add_child(cl)
			cl.add_child(etichetta("%d%s" % [k + 1, sez], F_NERO, 12, Color.WHITE if attiva else Color(1, 1, 1, 0.5)))
			var eff := etichetta(EFFETTI_POL[k][x].split(",")[0], F_REG, 9, Color.WHITE if attiva else Color(1, 1, 1, 0.45))
			eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			eff.custom_minimum_size = Vector2(70, 0)
			cl.add_child(eff)
			if k < 5 and not ag.is_empty() and ag[k] == sez:
				cella.tooltip_text += "\n(nell'Agenda politica dello Stato)"
				var stella := icona("vp", 12, Color("#c9cdd2"))
				cl.add_child(stella)
			sezioni.add_child(cella)
	# sacchetto
	var bs := HBoxContainer.new()
	bs.add_theme_constant_override("separation", 8)
	v.add_child(bs)
	bs.add_child(etichetta("SACCHETTO VOTI", F_NERO, 11, C_ORO))
	for c in 3:
		var cubo := icona("cubo", 16, Dati.COLORI[Dati.CLASSI[c]])
		bs.add_child(cubo)
		bs.add_child(etichetta("%d" % int(m.s["borsa"][c]), F_BOLD, 14))
	bs.add_child(etichetta("(riserva %d/%d/%d)" % [int(m.s["riserva"][0]), int(m.s["riserva"][1]), int(m.s["riserva"][2])], F_REG, 10, C_SPENTO))

func _aggiorna_eventi() -> void:
	for c in col_eventi.get_children():
		c.queue_free()
	var p := pannello(C_PANNELLO, Color(C_ORO, 0.3), 1)
	col_eventi.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(titolo_sezione("Eventi (lo Stato deve affrontarli)"))
	if m.s["eventi_tav"].is_empty():
		v.add_child(etichetta("Nessun evento sul tabellone.", F_REG, 12, C_SPENTO))
	for eid in m.s["eventi_tav"]:
		v.add_child(_carta_evento(eid, 372))

func _carta_evento(eid: String, w: float) -> Control:
	var e := Dati.evento(eid)
	var p := pannello(Color("#2f353c"), Color(C_ORO, 0.7), 2)
	p.custom_minimum_size = Vector2(w, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var h := HBoxContainer.new()
	v.add_child(h)
	var badge := pannello(C_ORO, Color(0, 0, 0, 0), 0)
	badge.add_child(etichetta("ULTIM'ORA", F_NERO, 9, C_SCURO))
	h.add_child(badge)
	h.add_child(etichetta(e["it"].to_upper(), F_NERO, 12, Color.WHITE))
	var t := ricco(testo_icone(e["t"], 12), 12, Color("#e6e9ec"))
	t.custom_minimum_size = Vector2(w - 20, 0)
	v.add_child(t)
	var pen := "Senza azione: "
	if e["pen"] is String:
		pen += "-1 Legittimità a due classi a scelta"
	else:
		var parti := []
		for x in e["pen"]:
			parti.append("%d %s" % [int(x[1]), Dati.NOMI_BREVI[x[0]]])
		pen += ", ".join(parti)
	var premi := []
	for k in e["sc"]:
		premi.append("%s: %s" % [Dati.NOMI_BREVI.get(k, k), _descrivi_premio(str(e["sc"][k]))])
	v.add_child(ricco("[color=#f6b33c]%s[/color]\n[color=#c9cdd2]Ricompense: %s[/color]" % [pen, "; ".join(premi)], 11))
	return p

func _descrivi_premio(pr: String) -> String:
	var f := pr.split(":")
	match f[0]:
		"tok":
			return "gettone Legittimità"
		"leg":
			return "+%s Legittimità" % f[1]
		"leg_per":
			return "+1 Legittimità ogni %s" % f[1]
		"tok_per":
			return "gettone ogni %s" % f[1]
		"vp_per":
			return "%s PV ogni %s" % [f[3] if f.size() > 3 else "1", f[1]]
		"vp":
			return "%s PV" % f[1]
		"leg_tutte":
			return "+1 Legittimità a tutte"
	return pr

func _aggiorna_mercato() -> void:
	for c in col_mercato.get_children():
		c.queue_free()
	var p := pannello(C_PANNELLO, Color(C_ORO, 0.3), 1)
	col_mercato.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(titolo_sezione("Mercato estero"))
	var x: Dictionary = Dati.d()["export"][int(m.s["export"])]
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	v.add_child(g)
	for r in Dati.RISORSE:
		var h := HBoxContainer.new()
		h.add_child(icona(r, 18))
		h.add_child(etichetta("%d per %d · %d per %d" % [int(x[r][0][0]), int(x[r][0][1]), int(x[r][1][0]), int(x[r][1][1])], F_BOLD, 13))
		g.add_child(h)
	var imp := HBoxContainer.new()
	imp.add_theme_constant_override("separation", 6)
	v.add_child(imp)
	imp.add_child(etichetta("IMPORT:", F_NERO, 11, C_ORO))
	for r in ["cibo", "lus"]:
		imp.add_child(icona(r, 16))
		imp.add_child(etichetta("%d (+%d dazio)" % [m.prezzo_estero(r), m.dazio(r)], F_SEMI, 12))
	if not m.s["accordi_tav"].is_empty():
		v.add_child(etichetta("ACCORDI COMMERCIALI:", F_NERO, 11, C_ORO))
		for k in m.s["accordi_tav"]:
			var a: Dictionary = Dati.d()["accordi"][int(k)]
			var h2 := HBoxContainer.new()
			if int(a["cibo"]) > 0:
				h2.add_child(etichetta(str(int(a["cibo"])), F_BOLD, 13))
				h2.add_child(icona("cibo", 16))
			if int(a["lus"]) > 0:
				h2.add_child(etichetta(str(int(a["lus"])), F_BOLD, 13))
				h2.add_child(icona("lus", 16))
			h2.add_child(etichetta("per %d (dazio %d)" % [int(a["costo"]), int(a["dazio"][m.polx(5)])], F_SEMI, 12))
			v.add_child(h2)
	# servizi pubblici
	v.add_child(etichetta("SERVIZI PUBBLICI (venduti dallo Stato):", F_NERO, 11, C_ORO))
	var sp := HBoxContainer.new()
	sp.add_theme_constant_override("separation", 6)
	v.add_child(sp)
	for r in ["sal", "ist", "inf"]:
		sp.add_child(icona(r, 18))
		sp.add_child(etichetta("%d/%d a %d" % [int(m.s["servizi"][r]), m.capienza_pubblica(r), m.prezzo_pubblico(r)], F_BOLD, 12))

# ---------------------------------------------------------------- tavolo (aziende e lavoratori)
func _aggiorna_tavolo() -> void:
	for c in tavolo.get_children():
		c.queue_free()
	_settore("Settore privato · Classe Capitalista (%d/12)" % m.s["priv_cc"].size(), m.s["priv_cc"], Dati.COLORI["CC"], 6)
	_settore("Settore privato · Classe Media (%d/8)" % m.s["priv_mc"].size(), m.s["priv_mc"], Dati.COLORI["MC"], 8)
	var pub: Array = m.s["pub"].duplicate()
	_settore("Settore pubblico · Stato (%d aperte, %d chiuse)" % [pub.size(), m.s["pub_giu"].size()], pub, Dati.COLORI["ST"], 9)
	var coop := m.aziende_di(Motore.WC)
	if not coop.is_empty():
		_settore("Cooperative agricole · Classe Operaia", coop, Dati.COLORI["WC"], 6)
	# disoccupati
	var p := pannello(Color("#2a3038"), Color(1, 1, 1, 0.08), 1)
	tavolo.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var h0 := HBoxContainer.new()
	v.add_child(h0)
	h0.add_child(titolo_sezione("Lavoratori disoccupati"))
	if m.s["dimostr"]:
		var man := pannello(Color("#c8161d"), Color.WHITE, 1)
		man.add_child(etichetta("MANIFESTAZIONE IN CORSO", F_NERO, 11, Color.WHITE))
		h0.add_child(man)
	for c in [Motore.WC, Motore.MC]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 1)
		v.add_child(h)
		var lab := etichetta(Dati.NOMI_BREVI[Dati.CLASSI[c]] + ":", F_BOLD, 12, Dati.COLORI[Dati.CLASSI[c]])
		lab.custom_minimum_size = Vector2(90, 0)
		h.add_child(lab)
		var dis := m.disoccupati(c)
		dis.sort_custom(func(a, b): return str(m.lav(a)["sk"]) < str(m.lav(b)["sk"]))
		for wid in dis:
			h.add_child(meeple(m.lav(wid)["sk"], c, 20))
		if dis.is_empty():
			h.add_child(etichetta("nessuno", F_REG, 12, C_SPENTO))

func _settore(titolo: String, lista: Array, col: Color, posti_vuoti: int) -> void:
	var p := pannello(Color(col, 0.08), Color(col, 0.45), 1)
	tavolo.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	v.add_child(titolo_sezione(titolo, col.lightened(0.2)))
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 5)
	g.add_theme_constant_override("v_separation", 5)
	v.add_child(g)
	for aid in lista:
		g.add_child(_azienda(aid))
	if lista.is_empty():
		v.add_child(etichetta("Nessuna azienda.", F_REG, 12, C_SPENTO))

func _azienda(aid: String) -> Control:
	var d := Dati.az(aid)
	var a: Dictionary = m.az(aid)
	var col: Color = Dati.COLORI_IND[d["ind"]]
	if d["ind"] == "sal":
		col = Color("#c8161d")
	var oper := m.operativa(aid)
	var p := pannello(Color("#f4f3ef") if oper else Color("#c9c9c4"), col, 2)
	p.custom_minimum_size = Vector2(124, 0)
	p.add_theme_stylebox_override("panel", _stile_carta(Color("#f4f3ef") if oper else Color("#bdbdb8"), col))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var art := immagine("res://assets/aziende/%s.webp" % (aid if not aid.begins_with("coop") else "coop"), 120, 40)
	if not oper:
		art.modulate = Color(0.7, 0.7, 0.7)
	v.add_child(art)
	var band := pannello(col, Color(0, 0, 0, 0), 0)
	band.add_theme_stylebox_override("panel", stile(col, Color(0, 0, 0, 0), 0, 3))
	var nl := etichetta(d["n"].to_upper(), F_NERO, 9, Color.WHITE)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size = Vector2(108, 0)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band.add_child(nl)
	v.add_child(band)
	# lavoratori
	var lw := HBoxContainer.new()
	lw.add_theme_constant_override("separation", 0)
	v.add_child(lw)
	if d["auto"]:
		lw.add_child(icona("mac", 20, Color("#454a50")))
		lw.add_child(etichetta("automatica", F_SEMI, 10, C_SCURO))
	else:
		for k in d["slot"].size():
			var wid: String = a["lav"][k]
			if wid == "":
				lw.add_child(meeple(d["slot"][k], -1, 18, false, true))
			else:
				var w := m.lav(wid)
				lw.add_child(meeple(w["sk"], int(w["c"]), 18, bool(w["imp"])))
		if d["tipo"] == "MC" and d["dip"] != "":
			lw.add_child(etichetta("+", F_BOLD, 12, C_SCURO))
			if a["dip"] == "":
				lw.add_child(meeple(d["dip"], -1, 18, false, true))
			else:
				var w2 := m.lav(a["dip"])
				lw.add_child(meeple(w2["sk"], int(w2["c"]), 18, bool(w2["imp"])))
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	v.add_child(info)
	var ris: String = Dati.RIS_IND[d["ind"]]
	var prod := m.produzione(aid)
	info.add_child(etichetta(str(prod), F_NERO, 13, C_SCURO))
	info.add_child(icona(ris, 15))
	if d["tipo"] == "MC" and int(d.get("bonus", 0)) > 0:
		info.add_child(etichetta("+%d" % int(d["bonus"]), F_BOLD, 10, C_SCURO))
	if a.get("mac", false):
		info.add_child(icona("mac", 13, Color("#454a50")))
	if not d["auto"] and int(d["sal"][0]) > 0:
		var sal := etichetta(" L%d·%d" % [int(a["sal"]), m.salario(aid)], F_BOLD, 11, Color("#8a2b20") if int(a["sal"]) == 3 else C_SCURO)
		info.add_child(sal)
	if a.get("sc", false):
		var sc := pannello(Color("#c8161d"), Color(0, 0, 0, 0), 0)
		sc.add_child(etichetta("SCIOPERO", F_NERO, 9, Color.WHITE))
		v.add_child(sc)
	p.tooltip_text = _tooltip_azienda(aid)
	return p

func _stile_carta(bg: Color, bordo: Color) -> StyleBoxFlat:
	var s := stile(bg, bordo, 2, 6)
	s.content_margin_left = 2
	s.content_margin_right = 2
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s

func _tooltip_azienda(aid: String) -> String:
	var d := Dati.az(aid)
	var a: Dictionary = m.az(aid)
	var t := "%s (%s) — costo %d\n" % [d["n"], Dati.NOMI_IND[d["ind"]], int(d["costo"])]
	t += "Produce %d %s" % [m.produzione(aid), Dati.NOMI_RIS[Dati.RIS_IND[d["ind"]]]]
	if int(d.get("mac", 0)) > 0:
		t += " (+%d con un Macchinario)" % int(d["mac"])
	if d["tipo"] == "MC" and d["dip"] != "":
		t += "\nDipendente della Classe Operaia (%s): +%d, salario %d/%d/%d" % [Dati.NOMI_IND[d["dip"]], int(d["bonus"]), int(d["sal"][0]), int(d["sal"][1]), int(d["sal"][2])]
	elif not d["auto"] and int(d["sal"][0]) > 0:
		t += "\nSalari L1/L2/L3: %d/%d/%d (ora L%d)" % [int(d["sal"][0]), int(d["sal"][1]), int(d["sal"][2]), int(a["sal"])]
	var req := []
	for x in d["slot"]:
		req.append(Dati.NOMI_IND[x])
	if not req.is_empty():
		t += "\nLavoratori: " + ", ".join(req)
	if m.impegnata(aid):
		t += "\nLavoratori impegnati (sdraiati): non si spostano fino alla produzione."
	return t

# ---------------------------------------------------------------- plance delle classi
func _aggiorna_giocatori() -> void:
	for c in col_giocatori.get_children():
		c.queue_free()
	for i in 4:
		col_giocatori.add_child(_plancia(i))

func _riga_val(h: HBoxContainer, ic: String, val: String, col := C_TESTO, d := 16.0) -> void:
	if ic != "":
		h.add_child(icona(ic, d))
	h.add_child(etichetta(val, F_BOLD, 13, col))

func _plancia(i: int) -> Control:
	var cl: String = Dati.CLASSI[i]
	var col: Color = Dati.COLORI[cl]
	var g := m.G(i)
	var attivo := not m.attesa().is_empty() and int(m.attesa()["g"]) == i
	var p := pannello(Color(col.darkened(0.72), 0.95), col if attivo else Color(col, 0.45), 3 if attivo else 1)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var h := HBoxContainer.new()
	v.add_child(h)
	var stemma := pannello(col, Color(0, 0, 0, 0), 0)
	stemma.custom_minimum_size = Vector2(10, 10)
	h.add_child(stemma)
	var n := etichetta(Dati.NOMI_CLASSE[cl].to_upper(), F_NERO, 13, col.lightened(0.3))
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	var chi := "TU" if umano(i) else ("ONLINE" if online and posti[i] >= 0 else "IA")
	h.add_child(etichetta(chi, F_BOLD, 11, C_ORO if umano(i) else C_SPENTO))
	var pv := pannello(Color("#c9cdd2"), Color(0, 0, 0, 0), 0)
	pv.add_child(etichetta("%d PV" % int(g["vp"]), F_NERO, 13, C_SCURO))
	h.add_child(pv)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 4)
	v.add_child(r1)
	if i == Motore.CC:
		_riga_val(r1, "soldi", "%d introiti + %d capitale" % [int(g["rev"]), int(g["cap"])], C_ORO)
	else:
		_riga_val(r1, "soldi", str(m.soldi(i)) + (" tesoro" if i == Motore.ST else ""), C_ORO)
	_riga_val(r1, "inf", str(int(g["inf"])) + (" pers." if i == Motore.ST else ""))
	if int(g["prestiti"]) > 0:
		r1.add_child(etichetta("PRESTITI: %d" % int(g["prestiti"]), F_NERO, 11, Color("#ff6b5b")))
	r1.add_child(etichetta("carte %d" % g["mano"].size(), F_REG, 11, C_SPENTO))
	match i:
		Motore.WC, Motore.MC:
			var r2 := HBoxContainer.new()
			r2.add_theme_constant_override("separation", 4)
			v.add_child(r2)
			_riga_val(r2, "prosp", str(int(g["prosp"])))
			r2.add_child(etichetta("Pop. %d (%d lav.: %d occ., %d disocc.)" % [m.popolazione(i), m.lavoratori(i).size(), m.occupati(i).size(), m.disoccupati(i).size()], F_SEMI, 11))
			var r3 := HBoxContainer.new()
			r3.add_theme_constant_override("separation", 3)
			v.add_child(r3)
			r3.add_child(etichetta("Beni:", F_SEMI, 11, C_SPENTO))
			for r in Dati.RISORSE:
				_riga_val(r3, r, str(int(g["beni"][r])), C_TESTO, 15)
			if i == Motore.MC:
				var r4 := HBoxContainer.new()
				r4.add_theme_constant_override("separation", 3)
				v.add_child(r4)
				r4.add_child(etichetta("Magazzino:", F_SEMI, 11, C_SPENTO))
				for r in Dati.RISORSE:
					_riga_val(r4, r, "%d (%d)" % [int(g["mag"][r]), int(g["prezzi"][r])], C_TESTO, 15)
			else:
				var r5 := HBoxContainer.new()
				v.add_child(r5)
				r5.add_child(etichetta("Sindacati:", F_SEMI, 11, C_SPENTO))
				for ind in Dati.INDUSTRIE:
					if g["sind"][ind] != "":
						r5.add_child(meeple(ind, Motore.WC, 16))
				if m.sindacati() == 0:
					r5.add_child(etichetta("nessuno", F_REG, 11, C_SPENTO))
		Motore.CC:
			var r6 := HBoxContainer.new()
			r6.add_theme_constant_override("separation", 3)
			v.add_child(r6)
			r6.add_child(etichetta("Magazzino:", F_SEMI, 11, C_SPENTO))
			for r in Dati.RISORSE:
				_riga_val(r6, r, "%d (%d)" % [int(g["mag"][r]), int(g["prezzi"][r])], C_TESTO, 15)
			var r7 := HBoxContainer.new()
			r7.add_theme_constant_override("separation", 4)
			v.add_child(r7)
			r7.add_child(etichetta("Zona franca: %d cibo, %d lusso · Ricchezza liv. %d" % [int(g["ftz"]["cibo"]), int(g["ftz"]["lus"]), int(g["ricchezza"])], F_SEMI, 11))
			var r8 := HBoxContainer.new()
			v.add_child(r8)
			r8.add_child(etichetta("Mercato:", F_SEMI, 11, C_SPENTO))
			var nomi := []
			for aid in g["mercato"]:
				nomi.append("%s (%d)" % [Dati.az(aid)["n"], int(Dati.az(aid)["costo"])])
			var lm := testo_lungo(", ".join(nomi), 10, C_TESTO)
			lm.custom_minimum_size = Vector2(290, 0)
			r8.add_child(lm)
		Motore.ST:
			var r9 := HBoxContainer.new()
			r9.add_theme_constant_override("separation", 6)
			v.add_child(r9)
			r9.add_child(etichetta("Legittimità:", F_SEMI, 11, C_SPENTO))
			for c in 3:
				var sc := icona("scudo", 16, Dati.COLORI[Dati.CLASSI[c]])
				r9.add_child(sc)
				var tk := int(g["tok"][c])
				r9.add_child(etichetta("%d%s" % [int(g["leg"][c]), " (+%d)" % tk if tk > 0 else ""], F_BOLD, 13))
			var r10 := HBoxContainer.new()
			v.add_child(r10)
			var ag: Array = Dati.d()["agende"][int(g["agenda"])]
			var parti := []
			for k in 5:
				parti.append("%d%s" % [k + 1, ag[k]])
			r10.add_child(etichetta("Agenda politica: %s (%d corrispondenze)" % [" ".join(parti), m.agenda_corrispondenze()], F_SEMI, 11))
			var ben := []
			for c in 3:
				var b: Dictionary = g["ben"][c]
				var cose := []
				for k in b:
					if int(b[k]) > 0:
						cose.append("%d %s" % [int(b[k]), {"soldi": "denaro", "cubi": "cubi"}.get(k, Dati.NOMI_RIS.get(k, k))])
				if not cose.is_empty():
					ben.append("%s: %s" % [Dati.NOMI_BREVI[Dati.CLASSI[c]], ", ".join(cose)])
			if not ben.is_empty():
				var lb := testo_lungo("Benefici da ritirare — " + "; ".join(ben), 10, C_ORO)
				lb.custom_minimum_size = Vector2(340, 0)
				v.add_child(lb)
	if i in [Motore.MC, Motore.CC] and i == io() and not g["mercato"].is_empty() and i == Motore.MC:
		var rm := HBoxContainer.new()
		v.add_child(rm)
		rm.add_child(etichetta("Mercato:", F_SEMI, 11, C_SPENTO))
		var nomi2 := []
		for aid in g["mercato"]:
			nomi2.append("%s (%d)" % [Dati.az(aid)["n"], int(Dati.az(aid)["costo"])])
		var lm2 := testo_lungo(", ".join(nomi2), 10, C_TESTO)
		lm2.custom_minimum_size = Vector2(290, 0)
		rm.add_child(lm2)
	return p

# ---------------------------------------------------------------- mano
func _aggiorna_mano() -> void:
	for c in mano_box.get_children():
		c.queue_free()
	var me := io()
	if me < 0:
		mano_titolo.text = "STAI GUARDANDO UNA PARTITA DELL'IA"
		return
	var g := m.G(me)
	mano_titolo.text = "LA TUA MANO · %s (%d carte)" % [m.nome(me).to_upper(), g["mano"].size()]
	var a := m.attesa()
	var giocabili := {}
	if not a.is_empty() and int(a["g"]) == me and a.get("tipo", "") == "turno":
		var ops: Array = a["opzioni"]
		for k in ops.size():
			var v = ops[k]["v"]
			if v is Array and v.size() > 1 and str(v[0]) == "eff":
				giocabili[str(v[1])] = k
	for cid in g["mano"]:
		var carta := _carta_azione(cid, 92, giocabili.has(cid))
		carta.gui_input.connect(_clic_carta.bind(cid, giocabili.get(cid, -1)))
		mano_box.add_child(carta)

func _carta_azione(cid: String, w: float, evidenzia := false) -> Control:
	var c := Dati.carta(cid)
	var col: Color = Dati.COLORI[c["cls"]]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _stile_carta(C_CARTA, C_ORO if evidenzia else Color(col, 0.6)))
	p.custom_minimum_size = Vector2(w, w * 1.85)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	v.add_child(immagine("res://assets/carte/%s.webp" % cid, w - 4, (w - 4) * 0.65))
	var tl := etichetta(c["it"].to_upper(), F_NERO, int(w / 11.5), C_SCURO)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.custom_minimum_size = Vector2(w - 6, 0)
	v.add_child(tl)
	var riga := ColorRect.new()
	riga.color = col
	riga.custom_minimum_size = Vector2(0, 2)
	v.add_child(riga)
	var fs := int(w / 13.5)
	var t := ricco(testo_icone(c["t"], fs), fs, Color("#1c1f23"))
	t.custom_minimum_size = Vector2(w - 6, 0)
	v.add_child(t)
	if not c["req"].is_empty():
		var ok := m.req_ok(cid)
		var rq := pannello(Color("#7b73b3") if ok else Color("#9a9a9a"), Color(0, 0, 0, 0), 0)
		rq.add_theme_stylebox_override("panel", stile(Dati.COLORI_POL[int(str(c["req"][0])[0]) - 1] if ok else Color("#9a9a9a"), Color(0, 0, 0, 0), 0, 4))
		rq.add_child(etichetta("REQUISITO " + " / ".join(c["req"]), F_NERO, int(w / 14), Color.WHITE))
		v.add_child(rq)
	if not c["leg"].is_empty():
		var parti := []
		for x in c["leg"]:
			parti.append("%+d Legittimità %s%s" % [int(x[1]), Dati.NOMI_BREVI[x[0]], (" ogni %d" % int(x[2])) if int(x[2]) > 0 else ""])
		v.add_child(etichetta(", ".join(parti), F_BOLD, int(w / 15), Color("#555b62")))
	return p

func _clic_carta(ev: InputEvent, cid: String, opzione: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_mostra_zoom(cid, opzione)

func _mostra_zoom(cid: String, opzione: int) -> void:
	_chiudi_zoom()
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_chiudi_zoom())
	zoom_layer.add_child(velo)
	zoom_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.position = Vector2(620, 120)
	velo.add_child(v)
	var carta := _carta_azione(cid, 330)
	carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(carta)
	if opzione >= 0:
		v.add_child(bottone("GIOCA QUESTA CARTA", _decidi.bind(opzione), Color("#8a4b0f"), 18))
	v.add_child(etichetta("(clic fuori per chiudere)", F_REG, 12, C_SPENTO))

func _chiudi_zoom() -> void:
	if zoom_layer == null:
		return
	for c in zoom_layer.get_children():
		c.queue_free()
	zoom_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _aggiorna_diario() -> void:
	var righe: Array = m.s["log"].slice(-120)
	var t := ""
	for r in righe:
		var s := str(r)
		if s.begins_with("---"):
			t += "\n[b][color=#f6b33c]%s[/color][/b]\n" % s
		else:
			t += s + "\n"
	diario.text = t

# ---------------------------------------------------------------- effetti visivi
func _effetti_nuovi() -> void:
	var ev: Array = m.s["eventi"]
	if ev.size() < eventi_visti:
		eventi_visti = 0
	while eventi_visti < ev.size():
		var e: Dictionary = ev[eventi_visti]
		eventi_visti += 1
		match str(e.get("tipo", "")):
			"esito":
				var k: int = e["pol"]
				var titolo := "LEGGE %d%s %s" % [k + 1, e["sez"], "APPROVATA" if e["passa"] else "RESPINTA"]
				_mostra_banner(titolo, "%s · favorevoli %d, contrari %d · cubi: %s" % [Dati.POLITICHE[k], int(e["fav"]), int(e["con"]), m._descrivi_cubi(e["cubi"])], Color("#2e7d32") if e["passa"] else Color("#b71c1c"))
			"round":
				_mostra_banner("ROUND %d" % int(e["n"]), "Inizia un nuovo round", C_ORO)
			"fmi":
				_mostra_banner("INTERVIENE IL FMI", "Lo Stato è insolvente: le Politiche cambiano di forza", Color("#b71c1c"))
			"manifestazione":
				_mostra_banner("MANIFESTAZIONE", "I disoccupati scendono in piazza", Dati.COLORI["WC"])
			"carta":
				if not umano(int(e["g"])):
					_mostra_banner(m.nome(int(e["g"])).to_upper(), "gioca «%s»" % Dati.carta(e["c"])["it"], Dati.COLORI[Dati.CLASSI[int(e["g"])]], 1.6)
			"azione":
				if not umano(int(e["g"])):
					_mostra_banner(m.nome(int(e["g"])).to_upper(), Motore.NOMI_AZIONI.get(e["a"], e["a"]), Dati.COLORI[Dati.CLASSI[int(e["g"])]], 1.4)

func _mostra_banner(titolo: String, sotto: String, col: Color, durata := 2.4) -> void:
	if banner != null and is_instance_valid(banner):
		banner.queue_free()
	banner = pannello(Color(0.08, 0.09, 0.11, 0.94), col, 3)
	banner.position = Vector2(470, 250)
	banner.custom_minimum_size = Vector2(680, 0)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(v)
	var l := etichetta(titolo, F_NERO, 30, col.lightened(0.3))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var s := testo_lungo(sotto, 16)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	schermo.add_child(banner)
	banner.modulate = Color(1, 1, 1, 0)
	var tw := banner.create_tween()
	tw.tween_property(banner, "modulate", Color.WHITE, 0.25)
	tw.tween_interval(durata / maxf(1.0, velocita * 0.6))
	tw.tween_property(banner, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(banner.queue_free)

func _mostra_fine() -> void:
	for c in pannello_scelte.get_children():
		c.queue_free()
	var vinc: int = m.s["vincitore"]
	titolo_scelte.text = "[b]PARTITA FINITA[/b]\nVince %s!" % m.nome(vinc)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.8)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(velo)
	var p := pannello(Color("#22272e"), C_ORO, 3)
	p.position = Vector2(500, 200)
	p.custom_minimum_size = Vector2(600, 0)
	velo.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var l := etichetta("VINCE %s" % m.nome(vinc).to_upper(), F_NERO, 30, Dati.COLORI[Dati.CLASSI[vinc]].lightened(0.2))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var ord := [0, 1, 2, 3]
	ord.sort_custom(func(a, b): return int(m.G(a)["vp"]) > int(m.G(b)["vp"]))
	for i in ord:
		var h := HBoxContainer.new()
		v.add_child(h)
		var n := etichetta(m.nome(i), F_BOLD, 20, Dati.COLORI[Dati.CLASSI[i]])
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(etichetta("%d PV" % int(m.G(i)["vp"]), F_NERO, 20))
	v.add_child(testo_lungo("Politiche finali: " + " ".join(range(7).map(func(k): return "%d%s" % [k + 1, m.pol(k)])), 15, C_SPENTO))
	v.add_child(bottone("NUOVA PARTITA", func():
		if not online:
			DirAccess.remove_absolute(SALVA_LOCALE)
		_menu_nuova(), Color("#8a4b0f"), 18))
	v.add_child(bottone("GUARDA IL TAVOLO", func(): velo.queue_free(), Color("#3a424d"), 15))
