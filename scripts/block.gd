class_name Block
extends CharacterBody2D

@export var fall_acceleration = 250
@export var color = 1
@export var texture: Texture2D
@export var block_scale: Vector2
@export_flags_2d_physics var collision_layers_2d: int
@export var raycast_offset: float = 1.1
@export var destroy_delay: float = 0.2

var target_velocity = Vector2.ZERO
var raycasts = {
	Direction.UP: RayCast2D.new(),
	Direction.DOWN: RayCast2D.new(),
	Direction.LEFT: RayCast2D.new(),
	Direction.RIGHT: RayCast2D.new()
}
var collision_shape = CollisionShape2D.new()
var sprite = Sprite2D.new()
var destroy_queued = false
enum Direction {UP,DOWN,LEFT,RIGHT,NONE}

var freeze_block = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_sprite()
	add_collision_box()
	add_raycast(Direction.UP)
	add_raycast(Direction.DOWN)
	add_raycast(Direction.LEFT)
	add_raycast(Direction.RIGHT)
	pass

func add_sprite() -> bool:
	sprite.texture = texture
	sprite.apply_scale(block_scale)
	add_child(sprite)
	return true

func add_raycast(direction) -> bool:
	var target_position = Vector2.ZERO
	match direction:
		Direction.UP:
			target_position = Vector2(0, -block_height()*.5)
		Direction.DOWN:
			target_position = Vector2(0, block_height()*.5)
		Direction.LEFT:
			target_position = Vector2(-block_width()*.5, 0)
		Direction.RIGHT:
			target_position = Vector2(block_width()*.5, 0)
	target_position *= Vector2(raycast_offset, raycast_offset)
	raycasts[direction].target_position = target_position
	raycasts[direction].force_raycast_update()
	raycasts[direction].collision_mask = collision_layers_2d
	add_child(raycasts[direction])
	return true

func block_height():
	return sprite.get_rect().size.y * block_scale.y
func block_width():
	return sprite.get_rect().size.x * block_scale.x

func add_collision_box() -> bool:
	var rect = RectangleShape2D.new()
	rect.extents = Vector2(block_width()*.5, block_height()*.5)
	collision_shape.shape = rect
	add_child(collision_shape)
	return true

func get_color():
	return color

func enable_gravity():
	freeze_block = false
	collision_shape.disabled = false

# Freeze the block
# Useful for swapping blocks
func set_freeze_block(freeze: bool) -> void:
	collision_shape.disabled = freeze
	if freeze:
		freeze_block = freeze
	else:
		await get_tree().create_timer(0.1).timeout
		enable_gravity()
	# TODO: Fix the blocks from shifting 
	#		after re-enabling collision + gravity

# destroy this block
func destroy() -> void:
	destroy_queued = true
	for direction in raycasts:
		var rc = raycasts[direction]
		if rc:
			rc.queue_free()
	var tween = get_tree().create_tween()
	for n in 3:
		tween.tween_property(sprite, "modulate", Color.DARK_SLATE_BLUE, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.chain().tween_property(sprite, "scale", Vector2(), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
	pass

func get_collison_directions() -> Dictionary:
	var active_raycast_directions = {}
	for dir in raycasts:
		var collider = raycasts[dir].get_collider()
		if collider:
			active_raycast_directions.set(dir, collider)
	return active_raycast_directions

func get_collison_direction(direction: Direction) -> Block:
	if raycasts[direction]:
		return raycasts[direction].get_collider()
	return null

func detect_and_clear_blocks() -> void:
	# gets the block detected by raycast
	var colliders = get_collison_directions()
	if colliders.size() == 0: # no block detected
		return
	
	# can't clear blocks until still
	if !velocity.is_equal_approx(Vector2.ZERO):
		return
	
	# check that the other block's color
	# is the same as my block's color
	for dir in colliders:
		var other: Block = colliders[dir]
		var other_same_dir_neighbor: Block = other.get_collison_direction(dir)
		if other.get_color() != color:
			# 1st neighbor doesnt share color
			continue
		if colliders.has(opposite_direction(dir)):
			# 1st neighbor has no opposing 2nd neighbor
			# 1st neighbor <-- my block --> (missing) 2nd neighbor
			var opposite_other: CharacterBody2D = colliders[opposite_direction(dir)]
			
			if opposite_other.get_color() != color:
				# opp dir neighbor color mismatch
				continue
				
			if other.velocity.is_equal_approx(Vector2.ZERO) \
				and opposite_other.velocity.is_equal_approx(Vector2.ZERO):
				
				other.destroy()
				opposite_other.destroy()
				destroy()
		elif other_same_dir_neighbor:
			var other_same_dir_neighbor_color = other_same_dir_neighbor.get_color()
			if other_same_dir_neighbor_color != color:
				# and same dir neighbor of 1st neighbor color mismatch
				continue
				
			elif other.velocity.is_equal_approx(Vector2.ZERO) \
				and other_same_dir_neighbor:
				if !other_same_dir_neighbor.velocity.is_equal_approx(Vector2.ZERO):
					continue
				other.destroy()
				other_same_dir_neighbor.destroy()
				destroy()
	return

func opposite_direction(direction: Direction) -> Direction:
	match direction:
		Direction.UP:
			return Direction.DOWN
		Direction.DOWN:
			return Direction.UP
		Direction.LEFT:
			return Direction.RIGHT
		Direction.RIGHT:
			return Direction.LEFT
	return Direction.NONE

func _physics_process(delta: float) -> void:
	if destroy_queued: return
	if freeze_block: return
	detect_and_clear_blocks()
	
	
	# Gravity
	target_velocity.y = target_velocity.y + (fall_acceleration * delta)
	velocity = target_velocity
	move_and_slide()
	pass
