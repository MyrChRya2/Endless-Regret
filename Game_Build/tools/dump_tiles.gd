# 临时工具：解码 playground 地形为带坐标 ASCII 图（用后删除）
extends SceneTree


func _initialize() -> void:
	var scene: PackedScene = load("res://playground.tscn")
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	await process_frame
	var tilemap: TileMapLayer = inst.get_node("TileMapLayer")
	var cells: Array[Vector2i] = tilemap.get_used_cells()
	var min_x := 99999
	var max_x := -99999
	var min_y := 99999
	var max_y := -99999
	for c in cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)
	print("bounds x:", min_x, "..", max_x, "  y:", min_y, "..", max_y)
	var grid := {}
	for c in cells:
		grid[c] = true
	# 顶部列号标尺（每 10 列一个数字）
	var ruler := "     "
	for x in range(min_x, max_x + 1):
		var ax: int = absi(x)
		var d: int = ax % 10
		ruler += str(d)
	print(ruler)
	# 左侧行号
	for y in range(min_y, max_y + 1):
		var line := "%4d " % y
		for x in range(min_x, max_x + 1):
			line += "#" if grid.has(Vector2i(x, y)) else "."
		print(line)
	quit()
