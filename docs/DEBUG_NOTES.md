# EndlessRegret — 调试知识笔记（Godot 2D 射线判定）

> 记录 2026-08 挂边判定调试中验证过的原理、陷阱与最佳实践。
> 新经验持续追加到本文档，作为本项目调试知识库。

---

## 1. Godot 2D 射线判定原理（intersect_ray）

### 基本用法

```gdscript
var params := PhysicsRayQueryParameters2D.create(from, to)  # from/to 是世界坐标
params.collision_mask = collision_mask   # 只检测指定碰撞层（位掩码）
params.exclude = [get_rid()]             # 排除自己（起点在自身碰撞盒内时必加）
var hit := get_world_2d().direct_space_state.intersect_ray(params)
```

### 返回字段

| 字段 | 类型 | 含义 |
|---|---|---|
| `hit.is_empty()` | bool | 空字典 = 未命中 |
| `hit.position` | Vector2 | 命中点（世界坐标） |
| `hit.normal` | Vector2 | 命中面法线（单位向量） |
| `hit.collider` | Object | 命中的碰撞体节点（如 TileMapLayer） |
| `hit.shape` | int | 复合碰撞体内的子形状索引 |

### 关键机制

- **同步查询**：调用即返回结果，**没有信号**（`Area2D` 才有 `body_entered` 等信号）
- 返回**最近**的命中点
- `collision_mask` 默认 1（第 1 层），与玩家的 `collision_mask` 保持一致即可命中玩家能碰的地形

---

## 2. 陷阱 1：射线端点埋在碰撞体内部

**现象**：玩家顶住 16px 厚的天花板时，头顶垂直射线有时返回空（不命中）；瓦片厚一点又命中。
**原因**：Godot 2D 的 `intersect_ray` 对**起点位于碰撞体内部**的检测**不可靠**（可能返回空）。玩家贴住天花板时，射线起点（头顶上方 14px）恰好钻进 16px 厚砖内部。
**验证**：用微型圆形 `intersect_shape` 检测端点是否埋在碰撞体里：

```gdscript
func _point_inside_world(point: Vector2) -> bool:
	var shape := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.5
	shape.shape = circle
	shape.transform = Transform2D(0.0, point)
	shape.collision_mask = collision_mask
	shape.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(shape).is_empty()
```

**规避**：设计射线时保证**两端都在目标表面之外**：
- 检测**头顶下方的平台顶**（挂边场景）：起点在空气、终点进平台体内部 → **可靠**
- 检测**头顶上方的天花板**：贴住时起点必然钻进砖内 → **不可靠**，改用 `is_on_ceiling()` 或把射线改方向

---

## 3. 陷阱 2：TileMapLayer 斜法线（凹形凸分解）

**现象**：横平竖直的矩形瓦片（碰撞多边形输出 = `[(-8,-8),(8,-8),(8,8),(-8,8)]`），命中法线却是**固定的斜方向**（如 `(-1,-2)/√5`、`(1,-5)/√26`），且**与命中点位置无关、多次复现**。

**原因**：Godot 的 `TileMapLayer` 会把相邻瓦片**合并成复合碰撞体**；当布局存在**凹角**（台阶、错缝、L/T 形拐角）时，合并形状是凹多边形，物理引擎只能处理凸形，于是**自动凸分解**成多个凸块——分解连接线是斜边，射线命中分解线时返回斜法线。

**证据链**（本次调试验证）：
1. 瓦片碰撞多边形输出为标准矩形 → 排除"瓦片本身斜"
2. 玩家位置变化后法线**精确复现** → 排除"数值噪声/角部巧合"
3. 命中点瓦片内 UV 在中部（不在角上）→ 排除"命中顶点"
4. `hit.shape` 字段不同（第一处 shape:20、第二处 shape:2）→ 命中复合体不同子形状

**验证方法**：
```gdscript
# 输出命中瓦片的碰撞多边形顶点
var td := tilemap.get_cell_tile_data(cell)
if td and td.get_collision_polygons_count(0) > 0:
	print(td.get_collision_polygon_points(0, 0))
```

**规避**：判定"平台顶"**不要依赖法线方向**，改用高度判据（见 §6）。

---

## 4. 陷阱 3：GDScript 类型推断

| 写法 | 结果 | 正确写法 |
|---|---|---|
| `var x := hit.position` | ❌ Cannot infer type（Dictionary 值是 Variant） | `var x: Vector2 = hit.position` |
| `hit.position.y - head_y` 参与运算 | ⚠️ Variant 运算，静态检查警告 | `float(hit.position.y) - head_y` |
| 三元两侧类型不一致（StringName vs String） | ❌ `INCOMPATIBLE_TERNARY` | 用 `str()` 统一：`str(collider.name) if collider else "null"` |
| `var dir := -sign(x) * Vector2.RIGHT` | ❌ 一元负号作用于函数返回值无法推断 | `var dir: Vector2 = -sign(x) * Vector2.RIGHT` |

**规律**：`:=` 只在右侧类型可静态推断时可用；凡是 `Dictionary` 取出的值（Variant）、函数返回值上做运算，都要**显式标注类型**或用 `float()`/`str()`/`as` 转换。

---

## 5. 调试工具集（已验证有效）

- **射线可视化**：`_draw()` + `_process` 里 `queue_redraw()`；绘制坐标 = 世界坐标 `- global_position`（draw_line 用节点局部坐标）；三色语义：**绿=有效命中、黄=命中但法线无效、红=未命中**
- **对照射线**：加一条"脚底向下"射线验证查询管道本身是否正常（站地上应命中）
- **点内部检测**：微型圆 `intersect_shape` 判断射线端点是否埋在碰撞体里（`_point_inside_world`）
- **瓦片反查**：`local_to_map` → `get_cell_tile_data` → `get_collision_polygon_points` 输出命中瓦片碰撞多边形
- **自动打印**：`is_on_ceiling()` 上升沿（用 `_was_on_ceiling` 记忆上一帧）触发 print，抓"顶住瞬间"的完整数据，不用盯 HUD

---

## 6. 判定最佳实践（挂边系统）

- **平台顶判据 = 高度判据**（替代法线判据，避开凸分解斜法线）：

```gdscript
# 头顶垂直射线命中，且命中点高度与头顶齐平（容差 4px）
var is_ledge := not hit.is_empty() \
	and abs(float(hit.position.y) - (global_position.y - 27.0)) <= 4.0
```

- **完整贴墙**（WallGrab）：头顶 + 脚底水平射线都命中
- **挂边**（LedgeGrab）：头顶齐平平台顶 ∧ 脚底贴墙
- **其余贴墙** → LedgeSlide 滑落（保持重力）
- 挂边吸附：`global_position.y = 命中点.y + 27`（碰撞盒顶贴平台顶表面）
- 挂边保持：`gravity_enabled = false` + 每帧吸附（防抖动）；退出时恢复重力
- 上扒：先做头顶空间检测（头顶上方 27px 有遮挡不爬，防穿模）

---

## 7. 本次结论备忘

1. 射线查询管道本身工作正常（对照射线验证）
2. "顶到天花板不绿" = 距离问题（离天花板 21.79px 超出 14px 覆盖范围）+ 时机问题（没贴住）
3. "薄厚瓦片表现不同" = 射线起点钻进碰撞体内部的 2D 查询不可靠行为
4. "固定斜法线" = TileMapLayer 凹形凸分解，不是瓦片问题

---

## 8. 陷阱 4：垂直射线 x 位置打偏（玩家中心在墙外）

**现象**：玩家贴墙下滑时，垂直射线（头顶±14px）和长程射线（头顶上方 33px）都**从未命中**墙顶（`l_ledge_dy` 恒为 "—"），但水平射线正常命中——挂边永不触发。

**原因**：玩家碰撞盒 16 宽（半宽 8px），贴墙时碰撞盒边缘贴墙表面，**玩家中心距墙表面 8px（在墙体外）**。墙（包括墙顶表面）从墙表面向墙内延伸，垂直射线打在玩家中心 x → 永远碰不到墙顶。水平射线能命中是因为它朝墙面方向打 20px（穿过了空隙 + 墙体）。

**修复**：垂直射线的 x 偏移到墙表面内侧：

```gdscript
func get_ledge_top_hit() -> Dictionary:
	var wall_normal := get_wall_normal()
	var x_offset: float = 0.0
	if wall_normal != Vector2.ZERO:
		x_offset = -sign(wall_normal.x) * 10.0   # 墙表面在中心外 8px，偏移 10px = 墙内 2px
	return _raycast(
		global_position + Vector2(x_offset, -41.0),
		global_position + Vector2(x_offset, -13.0)
	)
```

**教训**：检测"贴着的墙"时，射线起点必须放在**墙表面/墙体内**，不能放在玩家中心——玩家中心天然在墙外（碰撞盒半宽的差距），垂直方向的射线会系统性打偏。

**追加教训（偏移量的边界）**：偏移也不要**过大**——偏移 12px（墙内 4px）在**薄墙/墙角**场景会穿透到墙后，检测到玩家没贴的那面墙的顶部（B 墙顶），导致挂边误判（玩家挂在错误位置）。偏移 10px（墙内 2px）是安全值：既保证在墙体内，又不至于穿透到墙后结构。

---

## 9. 陷阱 5：凸分解斜边骗过"高度判据"（挂边误判）

**现象**：玩家在**墙角**起跳/下落贴墙时，被误判挂边（Airborne → LedgeSlide → LedgeGrab）。修改墙角瓦片布局后问题消失。

**原因**：墙角布局是凹形，TileMapLayer 凸分解出 **45° 斜边**。垂直射线命中的是**斜边**（法线 `(-0.707,-0.707)`）而不是真实墙顶表面；斜边命中点的高度恰好落在挂边容差内（dy ∈ [-8,0]），**仅用高度判据无法区分"真实墙顶"和"斜边"**。

**修复**：高度判据 + 法线判据**组合**：

```gdscript
func is_head_touching_ledge() -> bool:
	var hit := get_ledge_top_hit()
	if hit.is_empty():
		return false
	var dy := float(hit.position.y) - (global_position.y - 27.0)
	if dy > 0.0 or dy < -LEDGE_TOLERANCE:
		return false
	return float(hit.normal.y) < -0.9   # 接近水平朝上 = 真实墙顶；斜边（-0.707 等）被过滤
```

**教训**：TileMapLayer 凸分解斜边的问题**不止**影响法线判据——它产生的斜边**高度**也能骗过纯几何判据。可靠的"平台顶"判定需要**高度 + 法线双判据**：高度确认"头顶在边缘位置"，法线确认"命中面是水平的"。

**判断法线阈值参考**：真实墙顶 `(0,-1)` → `-1.0`；45° 斜边 → `-0.707`；`-0.9` 阈值允许约 26° 以内的偏差，能过滤典型的凸分解斜边。

