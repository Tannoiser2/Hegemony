## Screenshot dell'interfaccia: xvfb-run godot --path . -s res://tests/foto.gd -- [menu|partita] [decisioni] [file]
extends SceneTree

func _initialize():
	var args := OS.get_cmdline_user_args()
	var modo := args[0] if args.size() > 0 else "partita"
	var dec := int(args[1]) if args.size() > 1 else 0
	var file := args[2] if args.size() > 2 else "/tmp/foto.png"
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if modo == "partita":
		main.scelta_umani = [true, false, false, false]
		main._avvia_locale()
		main.velocita = 0.0
		var ia := IA.new()
		ia.rapida = true
		var k := 0
		while (k < dec or not main.umano(main.m.attesa().get("g", -1))) and not main.m.s["fine"] and k < dec + 400:
			var a: Dictionary = main.m.attesa()
			main.m.scegli(ia.scegli(main.m, a))
			k += 1
		main.mostrata = -1
		main.velocita = 1.0
		main._aggiorna_tutto()
		main.eventi_visti = main.m.s["eventi"].size()
	elif modo == "regole":
		main._menu_regole()
	for i in 20:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(file)
	print("salvato ", file)
	quit()
