class_name EquipmentSlotUI
extends PanelContainer

signal equip_slot_double_clicked(slot_key: String)

@export var slot_key: String = ""
@export var slot_label: String = ""

func _ready() -> void:
	%HolderName.text = slot_label
	
func set_equipment(item: ItemData) -> void:
	if item == null:
		%EquipmentPlaceholder.texture = null
		%ItemName.text = "空"
	else:
		%EquipmentPlaceholder.texture = item.icon
		#%EquipmentPlaceholder.color = item.icon_color
		%ItemName.text = item.item_name

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		equip_slot_double_clicked.emit(slot_key)
