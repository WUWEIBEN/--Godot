class_name CollectionZone
extends Area2D

signal resources_deposited(item_count: int)

@export var filter_enabled: bool = false  # 开启后只接受特定类型
@export var filter_type: int = ItemData.ItemType.RESOURCE

var stored: Dictionary = {}
var _deposit_player: Node2D = null  # 正在上缴的玩家引用
var _deposit_timer: float = 0.0     # 上缴间隔计时器
var _is_depositing: bool = false    # 是否正在上缴中
var _stored_count: int = 0          # 本次上缴的物品计数


func _ready() -> void:
	# 生成占位标记贴图（半透明圈，后续替换美术资源）
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.85, 0.0, 0.3))
	$Sprite2D.texture = ImageTexture.create_from_image(img)
	
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not _is_depositing:
		return
	_deposit_timer += delta
	if _deposit_timer >= 0.15:
		_deposit_timer = 0.0
		_deposit_next()


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("pop_from_head"):
		return
	if not body.has_method("can_pickup"):
		return
	if  body.head_stack.size() <= 0:
		return
	if _is_depositing:
		return
		
	_deposit_player = body
	_is_depositing = true
	_deposit_timer = 0.0
	
	
func _deposit_next() -> void:
	var data = _deposit_player.pop_from_head()
	if data == null:
		_is_depositing = false
		if _stored_count > 0:
			resources_deposited.emit(_stored_count)
			_print_stored()
		return
	
	# 创建飞行精灵，从头顶抛物线飞到回收
	var fly_item := Sprite2D.new()
	if data and data.icon:
		fly_item.texture = data.icon
	else:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.55, 0.35, 0.15))
		fly_item.texture = ImageTexture.create_from_image(img)
	fly_item.scale = Vector2(0.4,0.4)
	var start_pos := _deposit_player.global_position + Vector2(0, -40)
	fly_item.global_position = start_pos
	get_tree().current_scene.add_child(fly_item)
	
	var tween := create_tween()
	tween.tween_method(func(t: float):
		var pos := start_pos.lerp(global_position, t)
		pos.y -= sin(t * PI) * 60
		fly_item.global_position = pos
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		fly_item.queue_free()
		if not _can_accept(data.item_type):
			return
		var type_name: String = data.item_name
		stored[type_name] = stored.get(type_name, 0) + 1
		_stored_count += 1
	)


func _can_accept(item_type: ItemData.ItemType) -> bool:
	if not filter_enabled:
		return true
	return item_type == filter_type
	
	
func _print_stored() -> void:
	print("=== 回收区存储 ===")
	for type_name in stored:
		print("  %s: %d 个" % [type_name, stored[type_name]])
	print("=================")
