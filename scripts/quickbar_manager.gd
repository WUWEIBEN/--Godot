extends Node

signal quickbar_changed

const QUICKBAR_SIZE = 9

var quickbar:Array = []

# 初始化格子
func _ready() -> void:
	quickbar.resize(QUICKBAR_SIZE)

# 放入物品
func set_slot(index:int, item: ItemData) -> void:
	if index < 0 or index > QUICKBAR_SIZE:
		return
	quickbar[index] = item
	quickbar_changed.emit()
	
# 清空格子
func clear_slot(index: int) -> void:
	set_slot(index, null)

#使用物品
func use_slot(index: int) -> void:
	var item := quickbar[index] as ItemData
	if item == null:
		return
	
	match item.item_type:
		ItemData.ItemType.WEAPON, ItemData.ItemType.ARMOR, ItemData.ItemType.BATTERY:
			for i in range(InventoryManager.BACKPACK_SIZE):
				if InventoryManager.backpack[i] == item:
					InventoryManager.equip(i)
					return
		ItemData.ItemType.CONSUMABLE:
			# ?触发消耗品
			pass

func swap_slots(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_a >= QUICKBAR_SIZE:
		return
	if index_b < 0 or index_b >= QUICKBAR_SIZE:
		return
	var temp = quickbar[index_a]
	quickbar[index_a] = quickbar[index_b]
	quickbar[index_b] = temp
	quickbar_changed.emit()
