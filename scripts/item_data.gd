class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, BATTERY, CONSUMABLE }

@export var item_name: String = ""
@export var item_type: ItemType = ItemType.WEAPON
@export var description: String = ""
@export var icon: Texture2D

# 武器属性
@export var attack: int = 1  # 攻击力
@export var attack_speed: float = 1.0  # 攻速
