class_name ResourceNode
extends StaticBody2D

@export var hp: int = 5
@export var max_hp: int = 5
@export var drop_count: int = 3
@export var drop_item_data: ItemData
@export var drop_scene: PackedScene  # 掉落物场景
@export var texture_color: Color = Color(0.55, 0.35, 0.15)
@export var particle_color: Color = Color(0.55, 0.35, 0.15)

var _current_hp: int
var _trail: GPUParticles2D = null

func _ready() -> void:
	_current_hp = max_hp

	if $Sprite2D.texture == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(texture_color)
		$Sprite2D.texture = ImageTexture.create_from_image(img)

	_particle_setup()


func _particle_setup() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 180.0
	mat.gravity = Vector3(0, 200, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = particle_color
	mat.lifetime_randomness = 0.5
	$GPUParticles2D.process_material = mat


func take_damage(amount: int) -> void:
	_current_hp -= amount
	_spawn_hit_particles(amount)
	_spawn_drops(1)  # 每次挥砍掉 1 个碎片
	_hit_flash()  # 受击动画
	print(name, " HP: ", _current_hp, "/", max_hp)
	if _current_hp <= 0:
		_die()

# 受伤粒子（伤害越高粒子越多）
func _spawn_hit_particles(damage: int) -> void:
	$GPUParticles2D.amount = max(1, damage * 2)
	var mat := $GPUParticles2D.process_material as ParticleProcessMaterial
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 20 + damage * 15.0
	$GPUParticles2D.restart()
	$GPUParticles2D.emitting = true


# 受伤动画
func _hit_flash() -> void:
	# 闪白
	$Sprite2D.modulate = Color(3, 3, 3)
	var tween := create_tween()
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.01)  # 0.08 秒降回正常
	
	#抖动
	var shake := create_tween()
	shake.tween_property($Sprite2D, "position:x", -5, 0.03)
	shake.tween_property($Sprite2D, "position:x", 0, 0.03)


func _die() -> void:
	_spawn_death_dust()                               # 少量粉尘过渡
	$Sprite2D.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	_spawn_drops(drop_count)                          # 死亡时爆出剩余碎片
	get_tree().create_timer(0.8).timeout.connect(queue_free)


func _spawn_death_dust() -> void:
	$GPUParticles2D.amount = 8
	var mat := $GPUParticles2D.process_material as ParticleProcessMaterial
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 60.0
	$GPUParticles2D.restart()
	$GPUParticles2D.emitting = true


func _spawn_drops(count: int) -> void:
	if drop_scene == null or drop_item_data == null:
		return
	for i in count:
		var drop := drop_scene.instantiate() as DroppedItem
		drop.item_data = drop_item_data
		get_tree().current_scene.add_child(drop)
		drop.scatter(global_position, 180.0)
	
	
