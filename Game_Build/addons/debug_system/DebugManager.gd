extends Node

# 调试开关
@export var enable_prints: bool = true
@export var enable_indicators: bool = true
@export var enable_state_logs: bool = true


# UI引用
var ui_instance: Node = null
# 数据存储
var _data: Dictionary = {}
var _ui_initialized: bool = false


func _ready() -> void:
	_setup_ui()
	
func _setup_ui() -> void:
	if _ui_initialized:
		return
		
	var script_dir = get_script().get_path().get_base_dir()
	var ui_path = script_dir.path_join("debug_ui.tscn")
	
	if not ResourceLoader.exists(ui_path):
		push_warning("⚠️ 警告: 未找到 debug_ui.tscn，调试界面不可用")
		return
		
	var ui_scene = load(ui_path)
	ui_instance = ui_scene.instantiate()
	
	
	ui_instance.visible = false
	get_tree().root.add_child.call_deferred(ui_instance)
	
	_ui_initialized = true
	
	
# 数据推送接口
func set_value(key: String, value: Variant):
	_data[key] = value
	

func get_value(key: String) -> Variant:
	return _data.get(key)
	
	
func get_all_data() -> Dictionary:
	return _data.duplicate()
	
	
func clear() -> void:
	_data.clear()


func _print_debug(message: String) -> void:
	if enable_prints:
		print(message)
		
		
func log_state_change(from: String, to: String) -> void:
	if enable_state_logs:
		print("🔄 [状态机] ", from, " -> ", to)
