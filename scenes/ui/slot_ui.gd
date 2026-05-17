class_name SlotUI
extends PanelContainer

signal slot_double_clicked(slot_index: int)

var slot_index: int = -1
var current_item: ItemData = null      # ← 新增：保存当前物品引用

# 设置格子
func set_item(item: ItemData) -> void:
	current_item = item 
	if item == null:
		%IconPlaceholder.texture = null
		%ItemName.text = ""
	else:
		%IconPlaceholder.texture = item.icon
		%ItemName.text = item.item_name
		
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		slot_double_clicked.emit(slot_index)

# 拖拽开始
func _get_drag_data(_at_position: Vector2) -> Variant:
	if current_item == null:
		return null
	
	var preview := TextureRect.new()
	preview.texture = current_item.icon
	preview.custom_minimum_size = Vector2(48,48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	
	return{"item": current_item, "source": "backpack"}
