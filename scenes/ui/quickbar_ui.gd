extends PanelContainer

func _ready() -> void:
	_refresh_all()
	QuickbarManager.quickbar_changed.connect(_refresh_all)
	
	
func _refresh_all() -> void:
	var row = $MarginContainer/QuickBarRow
	for i in row.get_child_count():
		var slot := row.get_child(i) as QuickBarSlotUI
		if i < QuickbarManager.quickbar.size():
			slot.slot_index = i
			slot.set_item(QuickbarManager.quickbar[i])
		if not slot.quickbar_slot_used.is_connected(_on_quickbar_slot_use):
			slot.quickbar_slot_used.connect(_on_quickbar_slot_use)


func _on_quickbar_slot_use(index: int) -> void:
	QuickbarManager.use_slot(index)


# 监听用户键盘输入事件
func _input(event: InputEvent) -> void:
	for i in 9:
		if event.is_action_pressed("quickbar_"+str(i+1)):
			# 触发QuickbarManager的物品使用方法
			QuickbarManager.use_slot(i)
			get_viewport().set_input_as_handled() # 停止广播
			
