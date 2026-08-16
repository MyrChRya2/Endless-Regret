extends CanvasLayer


@onready var dynamic_label: Label = $Panel/VBoxContainer/DynamicLabel


func _ready() -> void:
	visible = true
	_sync_all_data()
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		visible = !visible
		
		
func _process(_delta: float) -> void:
	if not visible:
		return
	_sync_all_data()
	
	
func _sync_all_data() -> void:
	var data = DebugManager.get_all_data() if DebugManager else {}
	
	var text = ""
	var keys = data.keys()
	keys.sort()
	for key in keys:
		text += key + ": " + str(data[key]) + "\n"
		
	dynamic_label.text = text
