# 临时：B4 回归——玩家从 Airborne 贴墙（margin 边界 x=712.08，间隙 0.08px）进入 WallGrab，验证无乒乓
extends SceneTree

var player: CharacterBody2D = null
var tilemap: TileMapLayer = null

const DT := 1.0 / 60.0

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
	await physics_frame
	await physics_frame

	Input.action_release("move_left")
	Input.action_release("move_right")
	# 玩家盒左缘 = 712.08 - 8 = 704.08，与墙面（tile 43 右面 704）间隙 0.08px（接触 margin 边界）
	player.global_position = Vector2(712.08, -260)
	player.velocity = Vector2(0, 20)
	player.move_and_slide()  # 刷新碰撞状态（悬空：无地面无墙）
	player.change_state(player.get_state("Airborne"))
	Input.action_press("move_left")  # 按向墙
	var flips := 0
	var prev := ""
	var seq: Array = []
	var stable_wall := false
	for i in 180:
		player._process(DT)
		player._physics_process(DT)
		var st: String = player.current_state.name if player.current_state else "null"
		if st != prev:
			seq.append("%s@%d" % [st, i])
			prev = st
		if (st == "WallGrab" or st == "Airborne") and st != prev:
			pass  # 切换计数用下面的逻辑
		if i > 60 and st == "WallGrab" and player.is_on_wall():
			stable_wall = true
			break
	Input.action_release("move_left")
	# 统计 WallGrab/Airborne 交替次数
	var in_wg := false
	for s in seq:
		var name := (s as String).split("@")[0]
		if name == "WallGrab" and not in_wg:
			flips += 1
			in_wg = true
		elif name != "WallGrab":
			in_wg = false
	print("序列: ", " -> ".join(seq))
	print("→ %s（WallGrab 进入次数=%d，最终状态=%s，稳定贴墙=%s）" % [
		"OK 无乒乓" if flips <= 1 else "FAIL 乒乓",
		flips, prev, str(stable_wall)])
	quit()
