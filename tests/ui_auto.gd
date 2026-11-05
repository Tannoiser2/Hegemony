## Partita intera dall'interfaccia: le scelte "umane" passano da _decidi (prende l'IA). Controlla salvataggio e ripresa.
extends SceneTree

func _initialize():
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred(main)

func _run(main):
	await process_frame
	main.scelta_umani = [true, true, false, true]
	main._avvia_locale()
	main.velocita = 200.0
	var ia := IA.new()
	ia.rapida = true
	var t0 := Time.get_ticks_msec()
	var ricaricata := false
	while not main.m.s["fine"] and Time.get_ticks_msec() - t0 < 400000:
		await process_frame
		if main.has_meta("cambio_aperto"):
			main.remove_meta("cambio_aperto")
			main.mostrata = -1
			for c in main.schermo.get_children():
				if c is ColorRect and c.color.a > 0.9:
					c.queue_free()
			main.ultimo_umano = main.m.attesa().get("g", -1)
			continue
		var a: Dictionary = main.m.attesa()
		if not a.is_empty() and main.umano(a["g"]) and main.mostrata == int(main.m.s["decisioni"]):
			main.mostrata = -5
			await main._decidi(ia.scegli(main.m, a))
		if not ricaricata and int(main.m.s["round"]) == 3:
			ricaricata = true
			main._salva(true)
			var prima: Dictionary = main.m.s.duplicate(true)
			main._continua_locale()
			print("ripresa dal salvataggio: ", "OK" if main.m.s == prima else "DIVERSA")
	print("fine partita: ", main.m.s["fine"], " vincitore ", main.m.s["vincitore"], " PV ", main.m.s["g"].map(func(g): return g["vp"]), " decisioni ", main.m.s["decisioni"], " ms ", Time.get_ticks_msec() - t0)
	quit()
