class_name Player extends CharacterBody2D


#region /// State Machine Variables
var current_state: PlayerState = null

@onready var states_machine_container: Node = $States

#endregion


#region /// 物理参数

#region /// run
# 默认奔跑速度
const default_run_speed: float = 200.0
# 默认奔跑加速度
@export var accel: float = 2400.0
# 默认奔跑倍率
@export var DEFAULT_MOVE_SPEED_MULTIPLIER: float = 1.0
# 移速倍率表
var move_speed_modifiers: Array[float] = [DEFAULT_MOVE_SPEED_MULTIPLIER]
#endregion

#region /// jump
# 默认跳跃高度
const default_jump_height: float = 100.0
# 默认跳高倍率
@export var DEFAULT_JUMP_HEIGHT_MULTIPLIER: float = 0.7
# 跳高倍率表
var jump_height_modifiers: Array[float] = [DEFAULT_JUMP_HEIGHT_MULTIPLIER]
# 跳跃截取系数 
@export var jump_cut_multiplier: float = 0.6
# 跳跃状态
enum JumpType { GROUND, COYOTE, AIR, BUFFER, WALL }
var current_jump_type

#endregion

#region /// air movement
# 空中移动移速倍率
const air_move_speed: float = 0.6
# 空中加速灵敏度
@export var air_accel: float = 800.0
# 空中速度衰减灵敏度
@export var air_decel: float = 400.0

# 多端跳次数
var extra_air_jumps: int = 1
# 剩余多端跳次数多段跳
var remaining_air_jumps = extra_air_jumps

# 跳跃预输入窗口
@export var jump_buffer_time: float = 0.15
# 跳跃与输入窗口剩余时间
var jump_buffer_timer: float = 0.0

# 土狼跳
var can_coyote_jump: bool = true
# 平面边缘掉落检测
var is_falling_off_ledge: bool = false


#endregion

#region /// gravity
@export var GRAVITATIONAL_ACCELERATION: float = 980.0
@export var NORMAL_GRAVITY_RATE: float = 1.0
var gravity: float = GRAVITATIONAL_ACCELERATION * NORMAL_GRAVITY_RATE
var gravity_enabled: bool = true
# 脱离墙锁：置位后 airborne 跳过贴墙检测（玩家从 WallGrab 脚底离墙后自由落体，不被拉回）
var wall_escape: bool = false
# 脱离锁剩余时间：锁在"完全离开墙面"或超时后自动复位。
# 修复 B1-②：旧实现只在落地/跳跃时复位，脱墙后整段下落都跳过贴墙检测，再贴墙不回 WallGrab。
var wall_escape_time: float = 0.0
const WALL_ESCAPE_DURATION: float = 0.5
#endregion

#region /// friction
# 默认摩擦系数
const default_cof: float = 1.0
# 摩擦倍率
@export var DEFAULT_FRICTION_MULTIPLIER: float = 1.0
# 摩擦倍率表
var cof_modifiers: Array[float] = [DEFAULT_FRICTION_MULTIPLIER]

# 地面材质倍率
var ground_friction_multiplier: float = 1.0
#endregion

#endregion


#region /// Animation

enum FacingDir { LEFT, RIGHT }
enum WallContact { NONE, FULL, LEDGE_TOP, SLIDING }
var facing: FacingDir

var _missing_anim_warned: Dictionary = {}

@onready var player_anim: AnimatedSprite2D = %PlayerAnim

#endregion

var MAX_JUMP_VEL: float


func  _ready() -> void:
	# 初始化 states
	initialize_states()
	initialize_facing()
	pass
#region /// 射线调试可视化

@export var debug_draw_rays: bool = true

func _draw() -> void:
	if not debug_draw_rays:
		return
	var wall_normal := get_wall_normal()
	if wall_normal == Vector2.ZERO:
		return
	var wall_dir: Vector2 = -sign(wall_normal.x) * Vector2.RIGHT
		
	# ① 头顶垂直射线（与实际判定一致：x 偏移到墙表面内侧 10px）
	#    绿 = 有效挂边 / 黄 = 命中但高度或法线不符 / 红 = 未命中
	var x_off: float = -sign(wall_normal.x) * 10.0
	var v_from := global_position + Vector2(x_off, -41.0)
	var v_to := global_position + Vector2(x_off, -13.0)
	var v_hit := get_ledge_top_hit()
	var v_color: Color
	if v_hit.is_empty():
		v_color = Color(1.0, 0.35, 0.35)
	elif is_head_touching_ledge():
		v_color = Color(0.0, 1.0, 0.0)
	else:
		v_color = Color(1.0, 1.0, 0.0)
	draw_line(v_from - global_position, v_to - global_position, v_color, 1.5)
	if not v_hit.is_empty():
		draw_circle(Vector2(v_hit.position) - global_position, 3.0, v_color)
		
	# ② 头顶水平射线（头顶附近朝墙 20px）：青 = 命中 / 橙 = 未命中
	var h_color := Color(0.0, 0.8, 1.0) if _wall_ray_hit(-25.0, 20.0) else Color(1.0, 0.5, 0.0)
	draw_line(
		Vector2(0.0, -25.0),
		Vector2(0.0, -25.0) + wall_dir * 20.0,
		h_color, 1.5)
		
	# ③ 脚底水平射线（脚底附近朝墙 20px）：青 = 命中 / 橙 = 未命中
	var f_color := Color(0.0, 0.8, 1.0) if is_feet_touching_wall() else Color(1.0, 0.5, 0.0)
	draw_line(
		Vector2(0.0, -2.0),
		Vector2(0.0, -2.0) + wall_dir * 20.0,
		f_color, 1.5)
		
		
func _draw_ray(from_world: Vector2, to_world: Vector2, hit: bool) -> void:
	var color := Color(0.0, 1.0, 0.0) if hit else Color(1.0, 0.35, 0.35)
	draw_line(from_world - global_position, to_world - global_position, color, 1.5)
	

# 检测一个世界坐标点是否在碰撞体内部（用微型圆形 intersect_shape）
# 同时被生产逻辑使用：is_head_touching_ledge() 用它过滤"墙体内瓦片接缝"误判
var _debug_point_shape := CircleShape2D.new()
func _point_inside_world(point: Vector2) -> bool:
	_debug_point_shape.radius = 0.5
	var shape := PhysicsShapeQueryParameters2D.new()
	shape.shape = _debug_point_shape
	shape.transform = Transform2D(0.0, point)
	shape.collision_mask = collision_mask
	shape.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(shape).is_empty()
	
#endregion


# 每帧推送挂边判定状态到 Debug HUD（临时调试，用完删）
var _last_contact_str: String = ""
func _debug_ledge_status() -> void:
	var head_y := global_position.y - 27.0
	var ledge_hit := get_ledge_top_hit()
	var ledge_dy := "—"
	if not ledge_hit.is_empty():
		# 正 = 平台顶在头顶下方（玩家还没滑到）；负 = 平台顶在头顶上方（滑过头了）
		ledge_dy = str(float(ledge_hit.position.y) - head_y)
	
	# 加长垂直射线（头顶上方 33px → 脚底）：判断头顶上方区域到底有没有东西
	var far_hit := _raycast(
		global_position + Vector2(0.0, -60.0),
		global_position + Vector2(0.0, 0.0)
	)
	
	var contact := classify_wall_contact()
	var contact_name := "NONE"
	match contact:
		WallContact.FULL:
			contact_name = "FULL"
		WallContact.LEDGE_TOP:
			contact_name = "LEDGE_TOP"
		WallContact.SLIDING:
			contact_name = "SLIDING"
	
	DebugManager.set_value("l_state", current_state.name if current_state else "null")
	DebugManager.set_value("l_contact", contact_name)
	DebugManager.set_value("l_on_wall", is_on_wall())
	DebugManager.set_value("l_vel_y", velocity.y)
	DebugManager.set_value("l_head_ray", _wall_ray_hit(-25.0, 20.0))
	DebugManager.set_value("l_feet_ray", is_feet_touching_wall())
	DebugManager.set_value("l_ledge_hit", not ledge_hit.is_empty())
	DebugManager.set_value("l_ledge_dy", ledge_dy)
	DebugManager.set_value("l_head_touch", is_head_touching_ledge())
	# 垂直射线实际扫描范围 + 头顶位置
	DebugManager.set_value("l_ray_from", str(global_position + Vector2(0.0, -41.0)))
	DebugManager.set_value("l_ray_to", str(global_position + Vector2(0.0, -13.0)))
	DebugManager.set_value("l_head_y", head_y)
	# 加长射线状态
	DebugManager.set_value("l_far_hit", not far_hit.is_empty())
	if not far_hit.is_empty():
		DebugManager.set_value("l_far_hit_y", str(float(far_hit.position.y)))
		DebugManager.set_value("l_far_dy", str(float(far_hit.position.y) - head_y))
	else:
		DebugManager.set_value("l_far_hit_y", "—")
		DebugManager.set_value("l_far_dy", "—")
	
	# 接触分类变化时打印完整射线状态（控制台直接看）
	if contact_name != _last_contact_str:
		_last_contact_str = contact_name
		print("🟡 接触变化: ", contact_name,
			" pos=", global_position,
			" head_y=", head_y,
			" 垂直from=", global_position + Vector2(0.0, -41.0),
			" 垂直to=", global_position + Vector2(0.0, -13.0),
			" 垂直hit=", ledge_hit,
			" 长程hit=", not far_hit.is_empty(),
			" 长程hit_y=", float(far_hit.position.y) if not far_hit.is_empty() else "—",
			" 头顶水平=", _wall_ray_hit(-25.0, 20.0),
			" 脚底水平=", is_feet_touching_wall())


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		var next_state = current_state.handle_input(event)
		if next_state != null:
			change_state(next_state)
		
	
func _process(_delta: float) -> void:
	if current_state:
		var next_state = current_state.process(_delta)
		if next_state != null:
			change_state(next_state)
		
	_push_debug_data()
	
	if debug_draw_rays:
		queue_redraw()
	pass


func _physics_process(_delta: float) -> void:
	# 执行状态机逻辑
	if current_state:
		var next_state = current_state.physics_process(_delta)
		if next_state != null:
			change_state(next_state)
	
	# 重力
	if gravity_enabled:
		velocity.y += gravity * _delta
	
	# 移动并处理碰撞
	move_and_slide()
	update_ground_friction_from_tile()
	
	# 朝向更新
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		set_facing(FacingDir.RIGHT if input_dir > 0 else FacingDir.LEFT)
		
	# 落地重置资源（仅在 velocity.y >= 0 时归零，避免清除跳跃速度）
	if is_on_floor() and velocity.y >= 0:
		velocity.y = 0
		reset_remaining_air_jump()
		can_coyote_jump = true
		wall_escape = false
		wall_escape_time = 0.0
	
	# 脱离锁复位（B1-②）：完全离开墙面（is_on_wall=false）立即复位；仍贴墙则超时兜底复位。
	# 目的：锁只在"脱墙过渡"期间生效（防贴墙检测把玩家瞬间拉回），
	# 一旦玩家真的离开了墙面，后续再贴墙必须能重新进入 WallGrab。
	if wall_escape:
		if not is_on_wall():
			wall_escape = false
			wall_escape_time = 0.0
		else:
			wall_escape_time -= _delta
			if wall_escape_time <= 0.0:
				wall_escape = false
				wall_escape_time = 0.0
	
func initialize_states() -> void:
	_recursive_init(states_machine_container)
	var default_state = get_state("Idle")
	if default_state:
		current_state = default_state
		current_state.enter()
		print("✅ 状态机初始化完成，当前状态：", current_state.name)
	else:
		print("❌ 错误：找不到 ", default_state, " 状态！")
	
	
func _recursive_init(node: Node) -> void:
	for child in node.get_children():
		if child is PlayerState:
			child.player = self
			child.init()
	# 持续递归
		if child.get_child_count() > 0:
			_recursive_init(child)
	
	
func change_state(new_state:PlayerState) -> void:
	if new_state == null:
		print("⚠️ change_state 收到 null，忽略")
		return
	if new_state == current_state:
		print("ℹ️ 尝试切换到当前状态 [", current_state.name, "]，已忽略")
		return
		
	var from_name = "NULL"
	if current_state:
		from_name = current_state.name
	var to_name = new_state.name
	DebugManager.log_state_change(from_name, to_name)
	
	if current_state:
		current_state.exit()
		
	current_state = new_state
	current_state.enter()
	
	
func get_state(path: String) -> PlayerState:
	return states_machine_container.get_node(path)
	
	
# 当前移动倍率
func _get_total_move_speed_multiplier() -> float:
	var total_move_speed := 1.0
	for move_speed_midiier in move_speed_modifiers:
		total_move_speed *= move_speed_midiier
	return total_move_speed
# 最终移速
func _get_effective_move_speed() -> float:
	return default_run_speed * _get_total_move_speed_multiplier()


# 当前跳跃倍率
func _get_total_jump_height_multiplier() -> float:
	var total_jump_height := 1.0
	for jump_height_modifier in jump_height_modifiers:
		total_jump_height *= jump_height_modifier
	return total_jump_height
# 最终跳跃高度
func _get_effective_jump_height() -> float:
	return default_jump_height * _get_total_jump_height_multiplier()
	

# 当前摩擦倍率
func _get_total_cof_multiplier() -> float:
	var total_cof := 1.0
	for cof_modifier in cof_modifiers:
		total_cof *= cof_modifier
	return total_cof
# 最终摩擦系数
func _get_effective_cof() -> float:
	return default_cof * _get_total_cof_multiplier() * ground_friction_multiplier
	
func update_ground_friction_from_tile() -> void:
	var last_collision = get_last_slide_collision()
	var multiplier = 1.0
	
	if last_collision != null:
		var collider = last_collision.get_collider()
		
		if collider is TileMapLayer:
			var tilemap: TileMapLayer = collider
			var local_pos = tilemap.to_local(last_collision.get_position())
			var coords = tilemap.local_to_map(local_pos)
			var tile_data = tilemap.get_cell_tile_data(coords)
			
			if tile_data and  tile_data.has_custom_data("friction"):
				multiplier = tile_data.get_custom_data("friction")
				
	ground_friction_multiplier = multiplier
	
func reset_remaining_air_jump() -> int:
	remaining_air_jumps = extra_air_jumps
	return remaining_air_jumps
	

func initialize_facing() -> void:
	facing = FacingDir.RIGHT
	
	
#region /// 动画方法

func _handle_anim(anim_name: String) -> bool:
	if player_anim.sprite_frames.has_animation(anim_name):
		# 动画存在，正常播放（避免重复播放同一个动画）
		if player_anim.animation != anim_name:
			player_anim.play(anim_name)
		return true
	else:
		# 动画缺失：输出错误，并尝试播放 error 占位动画
		if not _missing_anim_warned.has(anim_name):
			_missing_anim_warned[anim_name] = true
			push_error("动画 '", anim_name, "' 不存在，使用 error 占位动画")
			
		if player_anim.sprite_frames.has_animation("error"):
			if player_anim.animation != "error":
				player_anim.play("error")
		else:
			# 连 error 动画都没有，则停止动画并显示第一帧（或保持当前帧）
			player_anim.stop()
			
	DebugManager.set_value("current_anim", anim_name)
	
	return false
	
	
	
# 时间驱动地面动画
func play_anim(anim_base: String) -> void:
	var suffix = "_right" if facing == FacingDir.RIGHT else "_left"
	var anim_name = anim_base + suffix
	_handle_anim(anim_name)

# 物理驱动空中动画
func update_air_animation() -> void:
	var suffix: String
	if velocity.x > 0.0:
		suffix = "_right"
	elif velocity.x < 0.0:
		suffix = "_left"
	else:
		suffix = "_right" if player_anim.animation.ends_with("_right") else "_left"
		
	var anim_name: String = ("airborne") + suffix
	
	if not _handle_anim(anim_name):
		return
		
	var max_vel = sqrt(2.0 * gravity * _get_effective_jump_height())
	if max_vel <= 0.0:
		player_anim.frame = 0
		return
		
	var t = clamp((velocity.y + max_vel) / (2.0 * max_vel), 0.0, 1.0)
	var index = int(round(t * (player_anim.sprite_frames.get_frame_count(anim_name) - 1)))
	player_anim.frame = index
		
#endregion


	# 调试HUD数据抓取
func _push_debug_data() -> void:
	if not DebugManager:
		return
		
	#DebugManager.set_value("player_vel", velocity.length())
	#DebugManager.set_value("player_vel_x", velocity.x)
	#DebugManager.set_value("player_vel_y", velocity.y)
	#DebugManager.set_value("is_on_floor", is_on_floor())
	#DebugManager.set_value("facing", facing)
	#DebugManager.set_value("facing", facing)
	#DebugManager.set_value("now_pressed", _get_key_input())
	#DebugManager.set_value("can_coyote_jump", can_coyote_jump)
	#DebugManager.set_value("remaining_air_jump", remaining_air_jumps)
	#DebugManager.set_value("jump_type", current_jump_type)
	_debug_ledge_status()

	
	
	# 临时按键抓取
func _get_key_input() -> String:
	if Input.is_key_pressed(KEY_A):
		return "A"
	elif Input.is_key_pressed(KEY_D):
		return "D"
	else:
		return ""


func set_facing(dir: FacingDir) -> void:
	if facing != dir:
		facing = dir


# 垂直移动
func _handle_jump() -> void:
	var jump_vel := sqrt(2 * gravity * _get_effective_jump_height())
	velocity.y = -jump_vel
	wall_escape = false
	wall_escape_time = 0.0
	
	
# 水平移动
func _handle_h_move(_delta: float, move_dir) -> void:
	var target_speed = move_dir * _get_effective_move_speed()
	if move_dir != 0:
		velocity.x = move_toward(velocity.x, target_speed, accel * _delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, accel * _delta)
		
		
# 空中水平移动
func _handle_air_move(_delta: float, move_dir) -> void:
	var target_speed = move_dir * _get_effective_move_speed()
	if move_dir != 0:
		velocity.x = move_toward(velocity.x, target_speed, air_accel * _delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_decel * _delta)


#region /// 墙判定

# 挂边判定容差：头顶与平台顶表面的允许偏差（px）
const LEDGE_TOLERANCE: float = 8.0
# 挂边"接近距离"：玩家头顶需高于墙顶超过该值（从上方足够远处滑向墙顶）才允许挂边。
# 防止坠落/撞墙时头顶恰好接近墙顶（dy 小）被瞬间抓住
const LEDGE_APPROACH_MIN: float = 12.0


# 通用射线查询：从 from 到 to 发一条代码射线，返回命中结果（空字典 = 未命中）
func _raycast(from: Vector2, to: Vector2) -> Dictionary:
	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(params)


# 垂直向下射线：检测玩家头顶上方的"墙顶表面"（挂边位置）
# 关键：x 必须偏移到墙表面内侧——玩家中心在墙外 8px（碰撞盒半宽），
# 垂直射线打在玩家中心会永远打不到墙顶（墙顶表面从墙表面才开始）
# 偏移不宜过大（如 12px 深入墙内 4px）：薄墙/墙角场景会检测到墙后的瓦片，导致挂边误判
func get_ledge_top_hit() -> Dictionary:
	var wall_normal := get_wall_normal()
	var x_offset: float = 0.0
	if wall_normal != Vector2.ZERO:
		# 墙表面在玩家中心外 8px（碰撞盒半宽），偏移 10px = 墙表面内侧 2px
		x_offset = -sign(wall_normal.x) * 10.0
	return _raycast(
		global_position + Vector2(x_offset, -41.0),
		global_position + Vector2(x_offset, -13.0)
	)


# 头顶与墙顶的高度差：正 = 头顶在墙顶上方（还没滑到）；负 = 头顶在墙顶下方（滑过了）；未命中 = 大数
func get_ledge_dy() -> float:
	var hit := get_ledge_top_hit()
	if hit.is_empty():
		return 99999.0
	return float(hit.position.y) - (global_position.y - 27.0)


# 头顶是否"顶着平台顶"：垂直射线命中，且命中点高度与头顶齐平
# 双判据：
#   1. 高度判据：头顶在墙顶下方 0~容差（不高于墙顶，避免上拉；也不低于太多）
#   2. 法线判据：命中面接近水平朝上（normal.y < -0.9 = 真实墙顶）
#      过滤 TileMapLayer 凹形凸分解的斜边（45° 等）——斜边高度可能恰好落在容差内，
#      仅用高度判据会把玩家误挂到斜边上（墙角场景的挂边误判根源）
#   3. 空间判据：命中面正上方必须是空的（真实墙顶）。过滤"墙体内瓦片接缝"误判（B1-①）：
#      垂直射线偏移进墙体内部后，会命中相邻瓦片的接缝边界——接缝法线同样是 (0,-1) 的水平面，
#      与真实墙顶无法区分，但接缝上方仍有瓦片（墙体延续），真实墙顶上方是空的。
func is_head_touching_ledge() -> bool:
	var hit := get_ledge_top_hit()
	if hit.is_empty():
		return false
	var dy := float(hit.position.y) - (global_position.y - 27.0)
	if dy > 0.0 or dy < -LEDGE_TOLERANCE:
		return false
	if float(hit.normal.y) >= -0.9:
		return false
	# 命中面上方 2px 处若埋在碰撞体里 → 是墙体内的接缝，不是墙顶
	if _point_inside_world(Vector2(float(hit.position.x), float(hit.position.y) - 2.0)):
		return false
	return true


# 沿墙面方向的水平射线，从玩家局部高度 local_y 处打出，返回是否命中
func _wall_ray_hit(local_y: float, ray_length: float) -> bool:
	var wall_normal := get_wall_normal()
	if wall_normal == Vector2.ZERO:
		return false
	var dir: Vector2 = -sign(wall_normal.x) * Vector2.RIGHT
	return not _raycast(
		global_position + Vector2(0.0, local_y),
		global_position + Vector2(0.0, local_y) + dir * ray_length
	).is_empty()


# 脚底是否贴墙：脚底水平射线命中
func is_feet_touching_wall() -> bool:
	return _wall_ray_hit(-2.0, 20.0)


# 分类当前贴墙接触状态（供状态机分发）：
#   NONE      —— 未贴墙
#   FULL      —— 头顶+脚底水平都命中（完整贴墙 → WallGrab 慢速下滑）
#   LEDGE_TOP —— 头顶顶着墙顶（→ LedgeGrab 挂边；不要求脚底贴墙，薄平台脚底会滑出侧面）
#   SLIDING   —— 其余（→ LedgeSlide 滑落）
func classify_wall_contact() -> WallContact:
	if not is_on_wall():
		return WallContact.NONE
	# 挂边：头顶顶着墙顶（高度判据）
	if is_head_touching_ledge():
		return WallContact.LEDGE_TOP
	# 完整贴墙：头顶 + 脚底水平都命中
	if _wall_ray_hit(-25.0, 20.0) and is_feet_touching_wall():
		return WallContact.FULL
	return WallContact.SLIDING

#endregion
