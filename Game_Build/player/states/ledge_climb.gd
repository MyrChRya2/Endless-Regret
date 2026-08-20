class_name LedgeClimb extends WallState

# 上爬状态（过程式）：从 LedgeGrab / LedgeSlide 按 jump 进入。
# 流程：初始化检测（平台顶在射线内 + 头顶净空）→ 失败立即回退（LedgeGrab 挂边 / LedgeSlide 滑落）；
#       成功 → 在 CLIMB_DURATION 内把玩家位置线性插值到平台顶面上方 → 进 Idle（重力落定贴合）。
# 过程式（非瞬移）：位置由每帧插值驱动，配合 ledge_climb 动画（占位空帧，帧确定后对齐时长）。

# 爬升过程时长（秒）：占位值，待 ledge_climb 动画帧确定后对齐（或改为动画帧驱动）
const CLIMB_DURATION: float = 0.2
# 爬升终点：脚底距平台顶的余量（防穿透，进 Idle 后由重力落定贴合）
const CLIMB_END_CLEARANCE: float = 20

var _started: bool = false
var _elapsed: float = 0.0
var _from_pos: Vector2 = Vector2.ZERO
var _to_pos: Vector2 = Vector2.ZERO


func enter() -> void:
	player.play_anim("ledge_climb")
	player.gravity_enabled = false  # 爬升过程位置由插值驱动，不受重力
	player.velocity = Vector2.ZERO
	_started = false
	_elapsed = 0.0


func exit() -> void:
	player.gravity_enabled = true


func physics_process(_delta: float) -> PlayerState:
	# 首帧：初始化爬升路径；检测失败 → 立即回退，不启动过程
	if not _started:
		_started = true
		if not _setup():
			return _fallback()
	# 过程推进：线性插值 from → to
	_elapsed += _delta
	var t := clampf(_elapsed / CLIMB_DURATION, 0.0, 1.0)
	player.global_position = _from_pos.lerp(_to_pos, t)
	player.velocity = Vector2.ZERO
	if t >= 1.0:
		# 爬到终点 → 进 Idle（exit 恢复重力，当帧 move_and_slide 落定贴合平台顶）
		return player.get_state("Airborne")
	return null


# 初始化爬升路径：终点 = 平台顶面上方（x 向平台内侧移 16px = 碰撞盒宽，站上平台顶面）
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
	_to_pos = Vector2(target_x, top_y - CLIMB_END_CLEARANCE)
	return true


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
