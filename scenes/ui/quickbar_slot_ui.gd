class_name QuickBarSlotUI
extends PanelContainer

signal quickbar_slot_used(slot_index: int)

var slot_index:int = -1
var current_item: ItemData = null

# 拿到Item信息，记录下来
func set_item(item: ItemData ) -> void:
	current_item = item
	%Index.text = str(slot_index+1)
	if current_item == null:
		%QuickBarHolder.texture = null
	else:
		%QuickBarHolder.texture = current_item.icon
		
# 拖拽放置：判断是否可以接受
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item")

# 拖拽放置：处理放置
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var item := data["item"] as ItemData
	#if item != null:
		#QuickbarManager.set_slot(slot_index, item)
	if item == null:
		return
	if data.get("source") == "quickbar":
		var source_index: int = data["source_index"]
		QuickbarManager.swap_slots(source_index, slot_index)
	else:
		QuickbarManager.set_slot(slot_index, item)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and  event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			quickbar_slot_used.emit(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			QuickbarManager.clear_slot(slot_index)  # 右键清空
			
func _get_drag_data(_at_position: Vector2) -> Variant:
	if current_item == null:
		return null
	var preview := TextureRect.new()
	preview.texture = current_item.icon
	preview.custom_minimum_size = Vector2(48, 48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	
	return {"item": current_item, "source": "quickbar", "source_index": slot_index}
