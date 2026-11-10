## Prova dei gesti a tocco sul tavolo 3D (un dito sposta, due dita zoom e rotazione, tocco breve = dettagli).
extends SceneTree
func _initialize():
	var t := Tavolo3D.new()
	root.add_child(t)
	await process_frame
	var dettagli := []
	t.dettagli.connect(func(x): dettagli.append(x))
	var m := Motore.new()
	m.nuova_partita({"seme": 3})
	t.aggiorna(m)
	var b0 := t.bersaglio
	var ev := InputEventScreenTouch.new(); ev.index = 0; ev.pressed = true; ev.position = Vector2(500, 400); t.gestisci(ev)
	var dr := InputEventScreenDrag.new(); dr.index = 0; dr.position = Vector2(560, 430); dr.relative = Vector2(60, 30); t.gestisci(dr)
	ev = InputEventScreenTouch.new(); ev.index = 0; ev.pressed = false; ev.position = Vector2(560, 430); t.gestisci(ev)
	print("pan: ", b0 != t.bersaglio)
	var d0 := t.dist
	var y0 := t.yaw
	for i in [0, 1]:
		ev = InputEventScreenTouch.new(); ev.index = i; ev.pressed = true; ev.position = Vector2(400 + i * 200, 400); t.gestisci(ev)
	dr = InputEventScreenDrag.new(); dr.index = 1; dr.position = Vector2(700, 450); dr.relative = Vector2(100, 50); t.gestisci(dr)
	print("pizzico zoom: ", t.dist < d0, "  rotazione: ", t.yaw != y0)
	for i in [0, 1]:
		ev = InputEventScreenTouch.new(); ev.index = i; ev.pressed = false; t.gestisci(ev)
	t.reimposta_camera()
	await process_frame
	var p: Vector2 = t.cam.unproject_position(t.px(252, 1380))
	ev = InputEventScreenTouch.new(); ev.index = 0; ev.pressed = true; ev.position = p; t.gestisci(ev)
	ev = InputEventScreenTouch.new(); ev.index = 0; ev.pressed = false; ev.position = p; t.gestisci(ev)
	print("tocco su una carta: ", dettagli)
	quit()
