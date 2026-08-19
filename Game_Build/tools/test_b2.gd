# 临时工具：验证 Bug ②（wall_escape 脱离锁未复位）修复（用后删除）
# 地形：高墙 B = tile 58 列 rows -24..-9（世界 x∈[928,944)，y∈[-384,-144)），原地图该区域为空气
# 场景1：escape=true 在空中下落（无墙）→ 锁应立即复位
# 场景2：escape=false 贴着高墙下落 → 应进入 WallGrab（再贴墙生效）
# 场景3：escape=true 贴着高墙下落 → 修复后应在锁超时后重新进入 WallGrab
extends SceneTree

var player: CharacterBody2D = null
var tilemap: TileMapLayer = null

const WALL_X := 58  # tile 列
const FACE_X := float(WALL_X + 1) * 16.0  # 右面世界 x = 944
const DT := 1.0 / 60.0
const ESC_DUR := 0.5  # 与 player.WALL_ESCAPE_DURATION 一致

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
	for y in range(-24, -9):
		tilemap.set_cell(Vector2i(WALL_X, y), 0, Vector2i(0, 0))
	await physics_frame
	await physics_frame

	print("=== 场景1：escape=true 在空中下落，锁应复位 ===")
	var r1 := _sim_air_escape_clear()
	print(r1)

	print("=== 场景2：escape=false 贴墙下落，应回 WallGrab ===")
	var r2 := _sim_regrab(false)
	print(r2)

	print("=== 场景3：escape=true 贴墙下落，锁超时后应回 WallGrab ===")
	var r3 := _sim_regrab(true)
	print(r3)
	quit()


# 瞬移到指定位置并刷新碰撞状态（避免上一位置的状态残留）
func _place(pos: Vector2, escape: bool) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	player.wall_escape = escape
	player.wall_escape_time = ESC_DUR
	player.can_coyote_jump = false
	player.change_state(player.get_state("Airborne"))
	player.move_and_slide()  # 刷新 is_on_floor / is_on_wall 为新位置


func _sim_air_escape_clear() -> String:
	# 空中点 (1024, -520)：tile 64，rows -32..-29 均为空气（下方 row -27 平台距 88px）
	_place(Vector2(1024, -520), true)
	Input.action_release("move_left")
	Input.action_release("move_right")
	var cleared := -1
	for i in 30:
		player._process(DT)
		player._physics_process(DT)
		if not player.wall_escape and cleared < 0:
			cleared = i
	if cleared >= 0:
		return "✅ 锁在第 %d 帧复位（玩家不在墙上）" % cleared
	return "❌ 30 帧后锁仍未复位（bug：整段下落跳过贴墙检测）"


func _sim_regrab(start_escape: bool) -> String:
	# 贴墙点：盒 [944,960) 与墙面齐平，头顶 -327 / 脚底 -300 均在墙高范围内
	_place(Vector2(FACE_X + 8.0, -300), start_escape)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_press("move_left")
	var last_state := ""
	var grabbed_at := -1
	var escape_cleared_at := -1
	for i in 300:
		player._process(DT)
		player._physics_process(DT)
		var st: String = player.current_state.name if player.current_state else "null"
		if st != last_state:
			last_state = st
		if st == "WallGrab" and grabbed_at < 0:
			grabbed_at = i
		if not player.wall_escape and escape_cleared_at < 0:
			escape_cleared_at = i
		if st == "Idle" or st == "Run":
			break
	Input.action_release("move_left")
	var esc := "（起始锁=%s）" % str(start_escape)
	if grabbed_at >= 0:
		return "✅ 重新进入 WallGrab @帧%d %s（锁复位@帧%d）" % [grabbed_at, esc, escape_cleared_at]
	return "❌ 未再进入 WallGrab %s → 最终状态 %s" % [esc, last_state]
