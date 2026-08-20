# 临时工具：验证 LedgeClimb 上爬状态（用后删除，内联结构复刻 probe）
# 自建平台 tile 58 列 rows -26..-14（[928,944) × y∈[-416,-224)，右面 x=944，左面 x=928，顶面 y=-416）
extends SceneTree

var player: CharacterBody2D = null
var tilemap: TileMapLayer = null

func _initialize() -> void:
	_main()

func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)

func _release(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)

func _main() -> void:
	var scene: PackedScene = load("res://playground.tscn")
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await physics_frame
	player = inst.get_node("Player")
	tilemap = inst.get_node("TileMapLayer")
	for y in range(-26, -14):
		tilemap.set_cell(Vector2i(58, y), 0, Vector2i(0, 0))
	await physics_frame
	await physics_frame

	print("=== 场景1：挂右面 + jump ===")
	await _scenario(Vector2(952, -389), "jump")

	print("=== 场景2：挂右面 + move_up ===")
	await _scenario(Vector2(952, -389), "move_up")

	print("=== 场景3：平台顶上方加遮挡 + jump（应退回挂边） ===")
	for y in range(-28, -27):
		tilemap.set_cell(Vector2i(58, y), 0, Vector2i(0, 0))
	await physics_frame
	await _scenario(Vector2(952, -389), "jump")
	for y in range(-28, -27):
		tilemap.erase_cell(Vector2i(58, y))
	await physics_frame

	print("=== 场景4：挂左面 + jump ===")
	await _scenario(Vector2(920, -389), "jump")
	quit()


func _scenario(pos: Vector2, action: String) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	player.change_state(player.get_state("Wall/LedgeGrab"))
	await physics_frame
	await physics_frame
	var held: String = player.current_state.name if player.current_state else "null"
	if held != "LedgeGrab":
		print("  ⚠️ 挂边失败，状态=", held)
	_press(action)
	var last_state := ""
	var seq: Array = []
	for i in 150:
		await physics_frame
		var st: String = player.current_state.name if player.current_state else "null"
		if st != last_state:
			seq.append("%s@%d" % [st, i])
			last_state = st
		if st == "Idle" or st == "Run":
			break
	_release(action)
	var seq_str := " -> ".join(seq)
	for i in 60:
		await physics_frame
	var final_st: String = player.current_state.name if player.current_state else "null"
	var p := player.global_position
	var ok: bool
	if seq_str.contains("LedgeClimb") and final_st == "Idle" and player.is_on_floor() and not player.is_on_wall():
		ok = true  # 爬上平台顶站稳
	elif seq_str.contains("LedgeClimb") and final_st == "LedgeGrab":
		ok = true  # 空间不足退回挂边（预期）
	else:
		ok = false
	print("序列: ", seq_str)
	print("60帧后: ", final_st, " pos=(%.1f, %.1f) on_floor=%s on_wall=%s → %s" % [
		p.x, p.y, player.is_on_floor(), player.is_on_wall(),
		("OK" if ok else "FAIL")])
