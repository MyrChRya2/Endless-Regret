class_name LedgeClimb extends WallState

# 上爬状态（过程式）：从 LedgeGrab / LedgeSlide 按 jump 进入。
# 流程：初始化检测（平台顶在射线内 + 头顶净空）→ 失败立即回退（LedgeGrab 挂边 / LedgeSlide 滑落）；
#       成功 → 以 CLIMB_SPEED 两阶段爬升：先垂直上升到平台顶面，再水平平移站上台面 →
#       落地后按输入进 Run / Idle。
# 两阶段原因：对角插值在垂直段玩家盒还与墙体重叠，x 平移会被 move_and_slide 推回（x 卡住），
# 垂直升过墙顶后 x 一次性补跳——表现为 x 瞬间变化。先升后移则两段都不撞墙，x 平滑。
# 过程式（非瞬移）：位置由每帧速度驱动，配合 ledge_climb 动画（占位空帧，帧确定后对齐速度）。

# 上爬速度（px/s）：可配置；动画帧确定后对齐
const CLIMB_SPEED: float = 150.0
# 动画帧分配（可配置）：垂直上升段播放前 N 帧，水平平移段播放后 M 帧
# （总和建议等于动画帧数；实际以动画帧数为准自适应截断）
const CLIMB_VERT_FRAMES: int = 2
const CLIMB_HORIZ_FRAMES: int = 4

var _started: bool = false
var _arrived: bool = false
var _from_pos: Vector2 = Vector2.ZERO
var _to_pos: Vector2 = Vector2.ZERO
var _total_dist: float = 0.0
# 爬升期间跟踪的移动方向（-1/0/+1）：到达时继承该方向的速度（玩家爬升中按的方向 = 想跑的方向）
var _climb_dir: float = 0.0


func enter() -> void:
	player.play_anim("ledge_climb")
	player.gravity_enabled = false  # 爬升过程位置由速度驱动，不受重力
	player.velocity = Vector2.ZERO
	_started = false
	_arrived = false
	_climb_dir = 0.0


func exit() -> void:
	player.gravity_enabled = true
	player.player_anim.speed_scale = 1.0  # 恢复自动播放（物理驱动期间置 0）


func physics_process(_delta: float) -> PlayerState:
	# 首帧：初始化爬升路径；检测失败 → 立即回退，不启动过程
	if not _started:
		_started = true
		if not _setup():
			return _fallback()
	if not _arrived:
		var step := CLIMB_SPEED * _delta
		# 阶段1：垂直上升到平台顶面（y 向下为正，目标更小=更高）
		if player.global_position.y > _to_pos.y:
			player.global_position.y = maxf(player.global_position.y - step, _to_pos.y)
		# 阶段2：水平平移站上台面（垂直到位后，盒底已贴平台顶，平移不撞墙）
		else:
			player.global_position.x = move_toward(player.global_position.x, _to_pos.x, step)
		player.velocity = Vector2.ZERO
		# 物理驱动动画：爬升进度（已走距离/总距离）→ 动画帧，动画正好持续整个爬升
		_update_climb_anim()
		# 跟踪移动方向：爬升期间按住的方向 = 到达后想跑的方向
		var dir := Input.get_axis("move_left", "move_right")
		if dir != 0.0:
			_climb_dir = sign(dir)
		if player.global_position.distance_to(_to_pos) < 0.5:
			player.global_position = _to_pos
			_arrived = true
		return null
	# 到达：位置已贴着平台顶面（_to_pos.y = top_y），交给当帧 move_and_slide 判定落地；
	# 落地后按输入进 Run / Idle
	player.gravity_enabled = true
	if player.is_on_floor():
		var move_dir := Input.get_axis("move_left", "move_right")
		if move_dir != 0.0 or _climb_dir != 0.0:
			# 以当前输入为准，否则用爬升期间跟踪的方向（继承移动意图）；
			# 用统一加速度函数起步（_handle_h_move 曲线），进 Run 后继续加速到目标跑速
			var dir := move_dir if move_dir != 0.0 else _climb_dir
			player._handle_h_move(_delta, dir)
			return player.get_state("Run")
		return player.get_state("Idle")
	return null


# 初始化爬升路径：终点 = 平台顶面上（x 向平台内侧移 16px = 碰撞盒宽，站上平台顶面）
func _setup() -> bool:
	var wall_normal := player.get_wall_normal()
	if wall_normal == Vector2.ZERO:
		return false
	var target_x: float = player.global_position.x - sign(wall_normal.x) * 16.0
	var hit := player.get_ledge_top_hit()
	if hit.is_empty():
		return false
	var top_y: float = float(hit.position.y)
	# 头顶空间检测：平台顶上方（爬上后身体将占用的 27px）不能被遮挡，否则爬升穿模
	if not _has_headroom(target_x, top_y):
		return false
	_from_pos = player.global_position
	_to_pos = Vector2(target_x, top_y)  # 结束位置：脚底贴着平台顶面（瓦片上表面）
	_total_dist = _from_pos.distance_to(_to_pos)
	return true


# 物理驱动动画：垂直段播前 CLIMB_VERT_FRAMES 帧，水平段播后 CLIMB_HORIZ_FRAMES 帧
# （两段各自按阶段进度映射帧）；speed_scale=0 停自动播放，帧由爬升位置决定
func _update_climb_anim() -> void:
	var anim := player.player_anim
	anim.speed_scale = 0.0
	var total: int = anim.sprite_frames.get_frame_count(anim.animation)
	if total <= 0:
		return
	var v_count := mini(CLIMB_VERT_FRAMES, total)  # 垂直段帧数（自适应）
	var frame := 0
	if player.global_position.y > _to_pos.y:
		# 垂直上升段：前 v_count 帧
		var v_progress := 0.0
		var v_range := _from_pos.y - _to_pos.y
		if v_range > 0.001:
			v_progress = clampf((_from_pos.y - player.global_position.y) / v_range, 0.0, 1.0)
		frame = clampi(int(round(v_progress * float(v_count - 1))), 0, v_count - 1)
	else:
		# 水平平移段：后 total-v_count 帧
		var h_start := v_count
		var h_count := maxi(0, total - v_count)
		if h_count > 0:
			var h_progress := 0.0
			var h_range := _from_pos.x - _to_pos.x
			if absf(h_range) > 0.001:
				h_progress = clampf((_from_pos.x - player.global_position.x) / h_range, 0.0, 1.0)
			frame = clampi(h_start + int(round(h_progress * float(h_count - 1))), h_start, total - 1)
		else:
			frame = v_count - 1  # 无水平帧 → 停在垂直段末帧
	anim.frame = frame


# 爬升失败回退：头顶仍贴着平台顶 → 退回 LedgeGrab 保持挂边；否则退回 LedgeSlide 继续滑落
# （LedgeClimb 可从 LedgeGrab 或 LedgeSlide 进入，回退到来源场景）
func _fallback() -> PlayerState:
	if player.is_head_touching_ledge():
		return player.get_state("Wall/LedgeGrab")
	return player.get_state("Wall/LedgeSlide")


# 空间检测：平台顶上方 6/14/22px × 碰撞盒宽度 3 列采样，任一点埋入碰撞体 → 无净空
func _has_headroom(target_x: float, top_y: float) -> bool:
	for dy in [6.0, 14.0, 22.0]:
		for sx in [-6.0, 0.0, 6.0]:
			if player._point_inside_world(Vector2(target_x + sx, top_y - dy)):
				return false
	return true
