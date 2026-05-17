extends PanelContainer



func _ready() -> void:
	hide()
	_refresh_all()  # 刷新
	InventoryManager.inventory_changed.connect(_refresh_all)
	InventoryManager.equipment_changed.connect(_refresh_all)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = not visible
		if visible:
			_refresh_all()
	
func _refresh_all() -> void:
	_refresh_backpack()
	_refresh_equipment()
	
	
func _refresh_backpack() -> void:
	var grid := $MarginContainer/VBoxContainer/BackpackGrid
	for i in grid.get_child_count():
		var slot := grid.get_child(i) as SlotUI
		slot.slot_index = i
		if i < InventoryManager.backpack.size():
			slot.set_item(InventoryManager.backpack[i])
		if not slot.slot_double_clicked.is_connected(_on_slot_double_clicked):
			slot.slot_double_clicked.connect(_on_slot_double_clicked)
	
	
func _refresh_equipment() -> void:
	var row := $MarginContainer/VBoxContainer/EquipmentRow
	for child in row.get_children():
		var slot := child as EquipmentSlotUI
		var item := InventoryManager.equipment.get(slot.slot_key) as ItemData
		slot.set_equipment(item)
		if not slot.equip_slot_double_clicked.is_connected(_on_equip_slot_double_clicked):
			slot.equip_slot_double_clicked.connect(_on_equip_slot_double_clicked)
		
	
	
func _on_slot_double_clicked(index: int) -> void:
	InventoryManager.equip(index)
	
func _on_equip_slot_double_clicked(slot_key: String) -> void:
	InventoryManager.unequip(slot_key)
