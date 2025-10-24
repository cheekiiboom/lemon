extends CharacterBody2D

@export var fall_acceleration = 75

var target_velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var collision_shape_2d: CollisionShape2D = $CollisionShape2D
	
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	target_velocity.y = target_velocity.y + (fall_acceleration * delta)
	velocity = target_velocity
	move_and_slide()
	pass
