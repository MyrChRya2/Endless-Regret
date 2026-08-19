# 临时工具：单元级验证 is_head_touching_ledge()（用后删除）
# 直接摆放玩家位置调用判定函数，验证：
#   A. 合法墙顶（自建墙 B：tile 58 rows -24..-9，右面 x=944，顶面 y=-384，上方无遮挡）→ 应 true
#   B. 墙体内瓦片接缝（原地图柱子 x=0 列，接缝 y=0）→ 应 false（B1-① 修复点）
#   C. 合法墙顶、容差边界（dy=-8）→ 应 true
extends SceneTree

var player: CharacterBody2D = null
var tilemap: TileMapLayer = null

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
		tilemap.set_cell(Vector2i(58, y), 0, Vector2i(0, 0))
	await physics_frame
	await physics_frame

	# A. 合法墙顶：贴墙 B 右面 x=944，头顶 -380（dy=-4）
	_place(Vector2(952, -353))
	var a: bool = player.is_head_touching_ledge()
	print("A. 合法墙顶（dy=-4）: ", a, "  ", "OK 判定为墙顶" if a else "FAIL 被误拒")

	# C. 合法墙顶、容差边界：头顶 -376（dy=-8）
	_place(Vector2(952, -349))
	var c: bool = player.is_head_touching_ledge()
	print("C. 合法墙顶（dy=-8）: ", c, "  ", "OK 判定为墙顶" if c else "FAIL 被误拒")

	# B. 墙体接缝：柱子 [0,16) 列，玩家贴右面 x=16，头顶 0.0（接缝 y=0 处）
	_place(Vector2(24, 27.0))
	var b: bool = player.is_head_touching_ledge()
	print("B. 墙体内瓦片接缝（y=0）: ", b, "  ", "OK 正确拒绝（修复生效）" if not b else "FAIL 接缝仍被误判为墙顶")
	quit()

func _place(pos: Vector2) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	player.change_state(player.get_state("Airborne"))
	player.move_and_slide()
