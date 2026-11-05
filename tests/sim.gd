## Partite automatiche tutte IA: godot --headless --path . -s res://tests/sim.gd -- PARTITE
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var partite := int(args[0]) if args.size() > 0 else 3
	var rapida := args.size() > 1 and args[1] == "rapida"
	var vitt := [0, 0, 0, 0]
	var t0 := Time.get_ticks_msec()
	var tot_vp := [0, 0, 0, 0]
	for k in partite:
		var m := Motore.new()
		m.nuova_partita({"seme": 1000 + k * 7919})
		var ai := IA.new()
		ai.rapida = rapida
		ai.casuale = args.size() > 1 and args[1] == "casuale"
		var passi := 0
		while not m.s["fine"] and passi < 20000:
			var a := m.attesa()
			if a.is_empty():
				push_error("partita %d bloccata senza attesa (fase %s)" % [k, m.s["fase"]])
				print("\n".join(m.s["log"].slice(-20)))
				break
			if passi > 15000:
				print("CICLO? ", a.get("tipo", ""), " ", a["testo"], " ", a["opzioni"].map(func(o): return o["t"]))
				if passi > 15010:
					break
			m.scegli(ai.scegli(m, a))
			passi += 1
		if m.s["fine"]:
			vitt[m.s["vincitore"]] += 1
		var pv := []
		for i in 4:
			pv.append(m.s["g"][i]["vp"])
			tot_vp[i] += int(m.s["g"][i]["vp"])
		print("partita %d: vince %s, PV %s, decisioni %d, round %d, politiche %s, prestiti %s" % [k, m.nome(maxi(0, m.s["vincitore"])), str(pv), passi, m.s["round"], "".join(m.s["pol"]), str(m.s["g"].map(func(g): return g["prestiti"]))])
	print("vittorie %s  PV medi %s  %d ms" % [str(vitt), str(tot_vp.map(func(x): return x / maxi(1, partite))), Time.get_ticks_msec() - t0])
	quit()
