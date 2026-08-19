# 临时工具：自动扫描 B1 挂边误判复现点（用后删除）
# 方法：枚举所有墙面（实心格水平相邻的空气格），在每个高度模拟"下落+朝墙按键"，
# 记录状态机走向与接触分类，找出"应进 WallGrab 却进了 LedgeSlide/LedgeGrab"的位置。
extends SceneTree

var player: CharacterBody2D = null
var tilemap: TileMapLayer = null
var grid := {}

const TILE := 16

func _initialize() -> void:
	_main()

func _main() -> void:
	var scene: PackedScene = load("res://playground.tscn")
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await physics_frame
	player = inst.get_node("Player")
	tilemap = inst.get_node("TileMapLayer")
	for c in tilemap.get_used_cells():
		grid[c] = true

	var faces := _collect_wall_faces()
	print("=== 墙面数量: ", faces.size())
	var bug1_count := 0
	for face in faces:
		bug1_count += await _test_face_bug1(face)
	print("=== BUG1 复现点数: ", bug1_count)
	quit()


func _solid(c: Vector2i) -> bool:
	return grid.has(c)


# 收集墙面：空气格 (ax, ay) 左侧/右侧是实心格 → 一个墙面
# face = { x: 玩家中心应处的 x, dir: 按键方向, wall_x: 墙面世界 x, col: 墙面所在实心格 x, y_top: 墙面顶行, y_bottom: 墙面底行 }
func _collect_wall_faces() -> Array:
	var faces: Array = []
	var checked := {}
	for c in grid:
		# 检查 (c.x, c.y) 左侧空气
		var left := Vector2i(c.x - 1, c.y)
		var right := Vector2i(c.x + 1, c.y)
		if not _solid(left) and not checked.has(left):
			checked[left] = true
			faces.append({
				"face_x": float(c.x) * TILE,          # 墙面世界 x（左侧面）
				"center_x": float(c.x) * TILE - 8.0,  # 玩家贴墙中心 x
				"dir": "move_right",
				"col": c.x,
			})
		if not _solid(right) and not checked.has(right):
			checked[right] = true
			faces.append({
				"face_x": float(c.x + 1) * TILE,
				"center_x": float(c.x + 1) * TILE + 8.0,
				"dir": "move_left",
				"col": c.x,
			})
	return faces


func _reset_player(pos: Vector2) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	player.wall_escape = false
	player.can_coyote_jump = false
	player.change_state(player.get_state("Airborne"))


# 模拟"下落+朝墙按键"，返回状态序列 [ [帧号, 状态, 接触, dy, wall_escape], ... ]
# 手动驱动 _physics_process 紧循环，避免逐帧 await（快几百倍）
func _sim(pos: Vector2, dir: String, max_frames: int) -> Array:
	_reset_player(pos)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_press(dir)
	var dt := 1.0 / 60.0
	var log: Array = []
	for i in max_frames:
		player._process(dt)
		player._physics_process(dt)
		var st: String = player.current_state.name if player.current_state else "null"
		var contact: int = player.classify_wall_contact()
		log.append([i, st, contact, player.get_ledge_dy(), player.wall_escape, player.global_position])
		if st in ["LedgeGrab", "Idle", "Run"] or (st == "Airborne" and i > 30 and player.is_on_floor()):
			break
	Input.action_release(dir)
	return log


func _contact_name(c: int) -> String:
	match c:
		player.WallContact.FULL: return "FULL"
		player.WallContact.LEDGE_TOP: return "LEDGE_TOP"
		player.WallContact.SLIDING: return "SLIDING"
		_: return "NONE"


# 测试一面墙：沿墙高每隔 8px 试一个起始高度
func _test_face_bug1(face: Dictionary) -> int:
	var col: int = face["col"]
	# 墙面纵向范围：该实心列从 y_top 到 y_bottom 连续实心
	var ys: Array = []
	for c in grid:
		if c.x == col:
			ys.append(c.y)
	if ys.is_empty():
		return 0
	ys.sort()
	var y_top: int = ys[0]
	var y_bottom: int = ys[ys.size() - 1]
	# 找最长连续段（墙面可能分成多段）
	var segments: Array = []
	var seg_start: int = ys[0]
	var seg_end: int = ys[0]
	for i in range(1, ys.size()):
		if ys[i] == seg_end + 1:
			seg_end = ys[i]
		else:
			segments.append([seg_start, seg_end])
			seg_start = ys[i]
			seg_end = ys[i]
	segments.append([seg_start, seg_end])

	var bug_count := 0
	for seg in segments:
		var top: int = seg[0]
		var bottom: int = seg[1]
		var seg_len: int = bottom - top + 1
		if seg_len < 3:
			continue  # 太矮，不算完整墙面
		# 起始高度：头顶在墙面顶下方 ≥1.5 瓦片（墙面顶超出射线扫描范围），且脚底在墙面底上方 ≥3 瓦片
		var y_start: float = float(top) * TILE + 8.0 + 27.0      # 头顶 ≈ 墙面顶下方 8px+27px
		var y_end: float = float(bottom) * TILE - 48.0           # 脚底至少离墙面底 3 瓦片
		var steps := 0
		var y: float = y_start
		while y <= y_end and steps < 20:
			steps += 1
			var pos := Vector2(face["center_x"] - 2.0, y)
			var log := await _sim(pos, face["dir"], 300)
			var wrong := _judge_bug1(log)
			if wrong:
				bug_count += 1
				var entry := _find_transition(log)
				print("⚠️ BUG1: 墙列=", col, " 段=", top, "..", bottom, " 起始y=", y,
					" 结果=", wrong, " 序列=", _summary(log), " 入口=", entry)
			y += 8.0
	return bug_count


func _judge_bug1(log: Array) -> String:
	# 玩家进了 LedgeSlide 或 LedgeGrab，但整个过程从未出现"头顶真的接近墙面顶"的条件
	# 简化判据：进了 LedgeGrab / LedgeSlide，且从未 dy > LEDGE_APPROACH_MIN（即 _was_above 不可能置位）→ 仍异常
	var entered := false
	var saw_approach := false
	var saw_full := false
	for row in log:
		var st: String = row[1]
		var dy: float = row[3]
		if st == "LedgeGrab" or st == "LedgeSlide":
			entered = true
		if dy > 12.0 and dy < 99990.0:
			saw_approach = true
		if row[2] == player.WallContact.FULL:
			saw_full = true
	if not entered:
		return ""
	if saw_full and not saw_approach:
		return "FULL接触但进滑落/挂边(无接近过程)"
	if entered and not saw_full and not saw_approach:
		return "直接进滑落/挂边(无FULL无接近)"
	return ""


func _find_transition(log: Array) -> String:
	for row in log:
		if row[1] == "LedgeSlide" or row[1] == "LedgeGrab" or row[1] == "WallGrab":
			return "帧" + str(row[0]) + " 状态=" + str(row[1]) + " 接触=" + _contact_name(row[2]) + " dy=" + str(row[3]) + " escape=" + str(row[4])
	return "无"


func _summary(log: Array) -> String:
	var states: Array = []
	var last := ""
	for row in log:
		if row[1] != last:
			states.append(row[1])
			last = row[1]
	return " -> ".join(states)
