extends CharacterBody2D

const SPEED = 200.0

var _current_weapon: ItemData = null


# ========== 角色主程序 ==========
func _ready() -> void:
	InventoryManager.equipment_changed.connect(_on_equipment_changed)
	_on_equipment_changed()
	
	# 连接武器信号
	$WeaponRange.body_entered.connect(_on_weapon_range_entered)
	$WeaponRange.body_exited.connect(_on_weapon_range_exited)
	# 连接拾取范围信号
	$PickupRange.area_entered.connect(_on_pickup_range_entered)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * SPEED
	move_and_slide()

	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	if not sprite:
		return

	# 角色动画状态：移动时播放 run，静止时播放 idle
	if direction.length_squared() < 0.01:
		sprite.play("idle")
	else:
		sprite.play("run")

	## 武器朝向：优先朝攻击目标，其次朝移动方向翻转
	if is_instance_valid(_attack_target):
		var to_target := _attack_target.global_position - global_position
		$WeaponPivot.rotation = to_target.angle()
	elif direction.length_squared() > 0.01:
		$WeaponPivot.rotation = direction.angle()

	# 左右翻转
	if direction.x > 0:
		sprite.flip_h = false
		$WeaponPivot.scale.y = 1.0
	elif direction.x < 0:
		sprite.flip_h = true
		$WeaponPivot.scale.y = -1.0
		
	# 攻击系统
	_process_attack(delta)
	_process_swing(delta)


# ========== 攻击系统 ==========
var _attack_target: ResourceNode = null  # 当前正在攻击的资源点（null = 没有目标）
var _attack_cooldown: float = 0.0  # 挥砍后冷却计时，冷却完才能再次挥砍
var _is_swinging: bool = false   # 正在挥砍中（true = 播放挥砍动画，不触发新的）
var _swing_timer: float = 0.0    # 当前挥砍已持续的时间（秒），用来算挥砍进度
var _swing_has_hit: bool = false   # 本次挥砍是否已经造成过伤害（防止一次挥砍打多次）
var _swing_rest_rot: float = 0.0
var _swing_rest_pos: Vector2 = Vector2.ZERO


# --------- 武器范围检测 ---------
func _on_weapon_range_entered(body: Node2D) -> void:
	if body.is_in_group("resources") and body is ResourceNode:
		_attack_target = body as ResourceNode


func _on_weapon_range_exited(body: Node2D) -> void:
	if body == _attack_target:
		_attack_target = null


# --------- 攻击逻辑 ---------
func _process_attack(delta: float) -> void:
	# 没有武器、没有目标、正在挥砍 → 跳过
	if _current_weapon == null:
		return
	if not is_instance_valid(_attack_target):
		_attack_target = null
		return
	if _is_swinging:
		return
		
	# 冷却计时
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_start_swing()
	
	
func _start_swing() -> void:
	_is_swinging = true
	_swing_timer = 0.0
	_swing_has_hit = false
	var sprite := $WeaponPivot/WeaponSprite as Sprite2D
	_swing_rest_rot = sprite.rotation
	_swing_rest_pos = sprite.position


func _process_swing(delta: float) -> void:
	if not _is_swinging:
		return
		
	_swing_timer += delta
	var speed := _current_weapon.attack_speed if _current_weapon else 1.0
	var duration := 0.45 / speed
	var sprite := $WeaponPivot/WeaponSprite as Sprite2D
	
	if _swing_timer >= duration:
		# 挥砍结束
		sprite.rotation = _swing_rest_rot
		sprite.position = _swing_rest_pos
		_is_swinging = false
		_attack_cooldown = 0.3 / speed
		return
	
	var progress := _swing_timer / duration
	# 举起武器
	if progress < 0.3:
		var phase := progress / 0.3
		sprite.rotation = _swing_rest_rot + lerpf(0.0, deg_to_rad(-40.0), ease(phase, -2.0))
		sprite.position = _swing_rest_pos + Vector2(
			lerpf(0.0, -6.0, ease(phase, -2.0)),
			lerpf(0.0, -10.0, ease(phase, -2.0))
		)
	elif progress < 0.55:
		var phase := (progress - 0.3) / 0.25
		sprite.rotation = _swing_rest_rot + lerpf(deg_to_rad(-40.0), deg_to_rad(70.0), ease(phase, 3.0))
		sprite.position = _swing_rest_pos + Vector2(
			lerpf(-6.0, 10.0, ease(phase, 3.0)),
			lerpf(-10, 6, ease(phase, 3.0))
		)
		if not _swing_has_hit and phase >= 0.15:
			_deal_damage_to_target()
	else:
		# 收回阶段
		var phase := (progress - 0.55) / 0.45  # 0→1，本段内进度
		sprite.rotation = _swing_rest_rot + lerpf(deg_to_rad(70.0), 0.0, ease(phase, 1.5)) + sin(phase * PI) * deg_to_rad(3.0)
		sprite.position = _swing_rest_pos + Vector2(
			lerpf(10.0, 0.0, ease(phase, 1.5)),
			lerpf(6.0, 0.0, ease(phase, 1.5))
		)


func _deal_damage_to_target() -> void:
	_swing_has_hit = true
	if not is_instance_valid(_attack_target):
		return
	var dmg := _current_weapon.attack if _current_weapon else 0
	_attack_target.take_damage(dmg)


# ========== 装备变化 ==========
func _on_equipment_changed() -> void:
	_current_weapon = InventoryManager.equipment["weapon"] as ItemData
	var sprite := $WeaponPivot/WeaponSprite as Sprite2D
	if _current_weapon == null:
		sprite.visible = false
		sprite.texture = null
	else:
		sprite.texture = _current_weapon.icon
		sprite.scale = _current_weapon.weapon_scale
		sprite.offset = _current_weapon.weapon_offset
		sprite.visible = true


# ========== 头顶堆栈 ==========
var head_stack: Array = []
var max_head_stack: int = 10

func can_pickup() -> bool:
	return head_stack.size() < max_head_stack


func add_to_head_stack(data: ItemData) -> bool:
	if not can_pickup():
		return false
	head_stack.append(data)
	_update_head_display()
	print("拾取矿石！当前堆叠: ", head_stack.size(), "/", max_head_stack)
	return true


func remove_all_from_head() -> Array:
	var items := head_stack.duplicate()
	head_stack.clear()
	_update_head_display()
	return items
	
func pop_from_head() -> ItemData:
	if head_stack.is_empty():
		return null
	var data = head_stack.pop_back()
	_update_head_display()
	return data


func _update_head_display() -> void:
	# 清除旧显示
	for child in $HeadStack.get_children():
		child.queue_free()
		
	# 重新生成堆叠精灵
	for i in head_stack.size():
		var sprite := Sprite2D.new()
		var data := head_stack[i] as ItemData
		if data and data.icon:
			sprite.texture = data.icon
		else:
			# 占位颜色 —— 这是可见的
			var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.55, 0.35, 0.15))
			sprite.texture = ImageTexture.create_from_image(img)
		sprite.scale = Vector2(0.4, 0.4)
		sprite.position = Vector2(randf_range(-3, 3), -i * 5.0)
		$HeadStack.add_child(sprite)
		
	# 显示计数
	var label := Label.new()
	label.text = "%d/%d" % [head_stack.size(), max_head_stack]
	label.position = Vector2(-12, 2)
	label.add_theme_font_size_override("size", 12)
	$HeadStack.add_child(label)


func _on_pickup_range_entered(area: Area2D) -> void:
	if area.is_in_group("dropped_items") and area is DroppedItem:
		if can_pickup():
			area.attract_to(self)
