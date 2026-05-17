extends Node

# 信号：背包或装备发生变化时通知UI刷新
signal inventory_changed
signal equipment_changed

const BACKPACK_SIZE := 16

# 背包：存的是 ItemData，空位为null
var backpack: Array = []
# 装备：按槽位类型存储
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"battery": null
}

func _ready() -> void:
	backpack.resize(BACKPACK_SIZE)
	# 初始测试：放一个矿稿进背包
	add_item(load("res://resource/equipment/pickaxe.tres"))
	
# 放入背包，遍历背包格子，如果扫到为空就放到对应位置，成功发出背包变动信号和ture，失败返回false
func add_item(item: ItemData) -> bool:
	for i in range(BACKPACK_SIZE):
		if backpack[i] == null:
			backpack[i] = item
			inventory_changed.emit()  # 发出仓库变化的信号
			return true  # 放入成功
	return false  # 放入失败
	
# 移出背包，根据索引剔除背包元素，成功发出背包变动信号
func remove_item(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < BACKPACK_SIZE:
		backpack[slot_index] = null
		inventory_changed.emit()

# 装上装备
func equip(slot_index: int) -> void:
	var item := backpack[slot_index] as ItemData
	if item == null:
		return 
		
	# 确定装备槽位类型
	var slot_key := _get_equip_slot(item.item_type)
	if slot_key == "":
		return
		
	# 如果该槽位已有装备，先换回背包空位（不走 add_item，避免重复发信号）
	if equipment[slot_key] != null:
		var old := equipment[slot_key] as ItemData
		equipment[slot_key] = null  # 卸装备
		add_item(old)  # 老装备放回背包
		
	# 装备新装备
	equipment[slot_key] = item
	backpack[slot_index] = null
	
	# 发出变更信号
	equipment_changed.emit()
	
# 卸装备
func unequip(slot_key: String) -> void:
	var item := equipment[slot_key] as ItemData
	if item == null:
		return
		
	if not add_item(item):
		return
		
	equipment[slot_key] = null
	equipment_changed.emit()

	
func _get_equip_slot(type: ItemData.ItemType) -> String:
	match type:
		ItemData.ItemType.WEAPON:
			return "weapon"
		ItemData.ItemType.ARMOR:
			return "armor"
		ItemData.ItemType.BATTERY:
			return "battery"
	return ""
	
