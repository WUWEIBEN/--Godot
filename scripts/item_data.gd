class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, BATTERY, CONSUMABLE, RESOURCE }

@export var item_name: String = ""
@export var item_type: ItemType = ItemType.WEAPON
@export var description: String = ""
@export var icon: Texture2D

# 武器属性
@export var attack: int = 1  # 攻击力
@export var attack_speed: float = 1.0  # 攻速
@export var weapon_scale: Vector2 = Vector2(0.4, 0.4) # 素材大小调节
@export var weapon_offset: Vector2 = Vector2(-8, 0) # 素材偏移
