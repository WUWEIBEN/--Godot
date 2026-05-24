class_name DroppedItem
extends Area2D

signal picked_up(item_data)

func _ready() -> void:
	# 给一点随机旋转，让物品看起来自然
	rotation = randf_range(0, TAU)
	
	# 用 item_data的图标作为显示
	if item_data and item_data.icon:
		$Sprite2D.texture = item_data.icon
	else:
		# 未设置 icon 时用颜色占位
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.55, 0.35, 0.15))
		$Sprite2D.texture = ImageTexture.create_from_image(img)
		
	_setup_trail()


func _physics_process(delta: float) -> void:
	if _attracted and is_instance_valid(_target):
		# 由慢到快飞向标
		_pickup_elapsed += delta
		var dir := _target.global_position - global_position
		var dist := dir.length()
		if dist < PICKUP_DISTANCE:
			if _target.has_method("add_to_head_stack"):
				if _target.add_to_head_stack(item_data):
					picked_up.emit(item_data)
					queue_free()
			return
		var speed_progress := minf(_pickup_elapsed / 0.4, 1.0)
		var current_speed := lerpf(30.0, PICKUP_SPEED, ease(speed_progress, -2.0))
		_velocity = dir.normalized() * current_speed
	else:
		# 重力
		_velocity.y += GRAVITY * delta
		# 撞地反弹
		if global_position.y >= _landing_y:
			global_position.y = _landing_y
			_velocity.y = -_velocity.y * BOUNCE
			_velocity.x *= 0.85  #落地摩擦
			if abs(_velocity.y) < 15.0:
				_velocity.y = 0.0
				_settled = true
				if _trail:
					_trail.emitting = false  # 落地停拖尾
				
	global_position += _velocity * delta
	rotation += _angular_velocity * delta
	_angular_velocity *= 0.97  # 角速度衰减，跟摩擦力一样


# =========掉落物品飞行特效=========
const PICKUP_SPEED := 400.0
const FRICTION := 0.92
const GRAVITY := 300.0              # 像素/秒²，把碎片往下拉
const BOUNCE := 0.4                 # 撞地后保留 40% 速度
const PICKUP_DISTANCE := 10.0  # 距离玩家多远算"到达"

var item_data: ItemData
var _velocity: Vector2 = Vector2.ZERO  # 当前移动速度（弹射或飞向玩家）
var _target: Node2D = null  # 吸附目标（玩家），null = 未吸附
var _attracted: bool = false  # 是否已被通知开始吸附
var _pickup_elapsed: float = 0.0  # 吸附已持续的时间，用于由慢到快加速
var _landing_y: float = 0.0                 # 地面 Y 坐标，用于撞地反弹
var _settled: bool = false  # 是否已完成弹射落地
var _trail: GPUParticles2D = null
var _angular_velocity: float = 0.0  # 旋转角速度（弧度/秒）


func scatter(origin: Vector2, force: float) -> void:
	global_position = origin
	# 在矿石周围随机选一个落地点，y 偏移随机
	_landing_y = origin.y + randf_range(-20, 40)   # 落地点始终在矿石下方
	_velocity.x = randf_range(-force * 0.3, force * 0.3)  # 左右散开
	_velocity.y = -randf_range(force * 1.0, force * 1.5)  # 向上抛出（负Y）
	_settled = false
	if _trail:
		_trail.emitting = true
	_angular_velocity = abs(_velocity.y) * 0.05  # 上抛越高转越快
	_angular_velocity *= signf(randf_range(-1, 1))  # 随机旋转方向


func attract_to(target: Node2D) -> void:
	if not _settled:
		return
	_target = target
	_attracted = true
	_pickup_elapsed = 0.0


func _setup_trail() -> void:
	_trail = GPUParticles2D.new()
	_trail.amount = 20
	_trail.lifetime = 0.8
	_trail.one_shot = false
	_trail.local_coords = false
	_trail.emitting = false  # 默认不发射
	_trail.modulate = Color(1, 0.85, 0.3, 0.8)
	
	var mat := ParticleProcessMaterial.new()
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 0
	mat.initial_velocity_max = 0
	mat.scale_min = 1.0
	mat.scale_max = 2.0
	mat.color = Color(1, 0.85, 0.3, 0.4)
	_trail.process_material = mat
	
	var tex_img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	tex_img.fill(Color.WHITE)
	_trail.texture = ImageTexture.create_from_image(tex_img)
	
	add_child(_trail)


	

	
	

		
		
		
		
		
		
		
