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

	print("=== 场景1：挂右面 + jump → LedgeClimb → Idle ===")
	await _scenario(Vector2(952, -389), "jump", "CLIMB")

	print("=== 场景2：挂右面 + move_up（入口已移除 → 保持挂边） ===")
	await _scenario(Vector2(952, -389), "move_up", "STAY")

	print("=== 场景3：平台顶上方加遮挡 + jump（应退回挂边） ===")
	for y in range(-28, -27):
		tilemap.set_cell(Vector2i(58, y), 0, Vector2i(0, 0))
	await physics_frame
	await _scenario(Vector2(952, -389), "jump", "FALLBACK_GRAB")
	for y in range(-28, -27):
		tilemap.erase_cell(Vector2i(58, y))
	await physics_frame

	print("=== 场景4：挂左面 + jump → Idle ===")
	await _scenario(Vector2(920, -389), "jump", "CLIMB")

	print("=== 场景5：LedgeSlide 触墙 FULL → 切回 WallGrab ===")
	# 玩家贴完整墙（头顶 -407 脚底 -380 均在墙高 [-416,-224) 内），强制进 LedgeSlide
	player.global_position = Vector2(952, -380)
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	player.change_state(player.get_state("Wall/LedgeSlide"))
	await physics_frame
	var s5 := ""
	var last5 := ""
	for i in 20:
		await physics_frame
		var st5: String = player.current_state.name if player.current_state else "null"
		if st5 != last5:
			s5 += ("" if s5 == "" else " -> ") + "%s@%d" % [st5, i]
			last5 = st5
		if st5 == "WallGrab":
			break
	print("序列: ", s5)
	print("→ %s" % ("OK 切回 WallGrab" if last5 == "WallGrab" else "FAIL 最终=" + last5))

	print("=== 场景6：LedgeSlide 中 jump → LedgeClimb → Idle（头顶在平台顶上方 6px） ===")
	# 头顶 -422（平台顶 -416 上方 6px，接触 SLIDING），强制进 LedgeSlide 后按 jump
	player.global_position = Vector2(952, -395)
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	player.change_state(player.get_state("Wall/LedgeSlide"))
	await physics_frame
	_press("jump")
	var s6 := ""
	var last6 := ""
	for i in 120:
		await physics_frame
		var st6: String = player.current_state.name if player.current_state else "null"
		if st6 != last6:
			s6 += ("" if s6 == "" else " -> ") + "%s@%d" % [st6, i]
			last6 = st6
		if st6 == "Idle":
			break
	_release("jump")
	print("序列: ", s6)
	for i in 60:
		await physics_frame
	print("→ %s" % ("OK 滑落中 jump 扒上平台" if last6 == "Idle" else "FAIL 最终=" + last6))

	print("=== 场景7：LedgeSlide 中 jump 但平台顶不在射线范围（应回 LedgeSlide 继续滑） ===")
	# 头顶 -436（平台顶上方 20px，超出射线 head±14），强制进 LedgeSlide 后按 jump
	player.global_position = Vector2(952, -409)
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	player.change_state(player.get_state("Wall/LedgeSlide"))
	await physics_frame
	_press("jump")
	var s7 := ""
	var plain7: Array = []
	var last7 := ""
	for i in 60:
		await physics_frame
		var st7: String = player.current_state.name if player.current_state else "null"
		if st7 != last7:
			s7 += ("" if s7 == "" else " -> ") + "%s@%d" % [st7, i]
			plain7.append(st7)
			last7 = st7
		if st7 != "LedgeSlide" and st7 != "LedgeClimb":
			break
	_release("jump")
	print("序列: ", s7)
	# 预期：LedgeClimb 失败回退 LedgeSlide（继续滑落）；后续滑落中接触 FULL → WallGrab 是新逻辑的正常表现
	var ci: int = plain7.find("LedgeClimb")
	var si: int = plain7.find("LedgeSlide", ci + 1)
	print("→ %s" % ("OK 失败回退 LedgeSlide" if ci >= 0 and si > ci else "FAIL 序列=" + s7))
	quit()


# pos: 挂边位置；action: 按键；expect: CLIMB=爬上去 / STAY=保持挂边 / FALLBACK_GRAB=退回挂边
func _scenario(pos: Vector2, action: String, expect: String) -> void:
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
	match expect:
		"CLIMB":
			ok = seq_str.contains("LedgeClimb") and final_st == "Idle" and player.is_on_floor() and not player.is_on_wall()
		"STAY":
			ok = not seq_str.contains("LedgeClimb") and final_st == "LedgeGrab"
		"FALLBACK_GRAB":
			ok = seq_str.contains("LedgeClimb") and final_st == "LedgeGrab"
	print("序列: ", seq_str)
	print("60帧后: ", final_st, " pos=(%.1f, %.1f) on_floor=%s on_wall=%s → %s" % [
		p.x, p.y, player.is_on_floor(), player.is_on_wall(),
		("OK" if ok else "FAIL")])
