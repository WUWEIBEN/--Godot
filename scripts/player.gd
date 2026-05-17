extends CharacterBody2D

const SPEED = 200.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = direction * SPEED
	move_and_slide()
	
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	if not sprite:
		return
	
	# 移动时播放 run，静止时播放 idle
	if direction.length_squared() < 0.01:
		sprite.play("idle")
	else:
		sprite.play("run")
		
	# 左右翻转
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
