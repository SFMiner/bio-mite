# Screenshot gate (windowed, not headless). Env: BM_OUT=<absolute png>, optional BM_LEVEL=1-5,
# BM_PICK="1A,1B,2A,2B,3A,3B" (chromosome ids added in order), BM_FUSE=1, BM_FACTS=1, BM_LABELS=0.
# ../../Godot_v4.5-stable_win64.exe --path . --resolution 1280x720 --script res://tools/screenshot.gd
extends SceneTree


func _init() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	get_root().add_child(main)
	await process_frame
	var level: String = OS.get_environment("BM_LEVEL")
	if not level.is_empty():
		main.load_level(int(level))
	for id: String in OS.get_environment("BM_PICK").split(",", false):
		for v: ChromosomeVisual in main.bank_visuals:
			if v.chromosome.id == id:
				main.add_to_reactor(v.chromosome)
				break
	if OS.get_environment("BM_FUSE") == "1":
		main.fuse()
	if OS.get_environment("BM_LABELS") == "0":
		main.toggle_labels()
	if OS.get_environment("BM_FACTS") == "1":
		main.show_facts()
	for i: int in range(8):
		await process_frame
	get_root().get_texture().get_image().save_png(OS.get_environment("BM_OUT"))
	quit()
