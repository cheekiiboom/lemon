extends Node2D

enum BlockType {STAR,MOUNTAIN,MOON}

var shift_play_enabled = false

# Testing Block Swapping
var block_1: Node = null
var block_2: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func reset_select() -> void:
	for block in [block_1, block_2]:
		block.sprite.modulate = Color.WHITE
		block.set_freeze_block(false)
	block_1 = null
	block_2 = null
	pass

func select_block(block_number):
	var block = get_block_at_cursor()
	if !block:
		return
	if block==block_1 or block==block_2:
		return
	# Select block
	block.sprite.modulate = Color.DARK_GRAY
	block.set_freeze_block(true)
	
	if block_number == 1:
		if block_1:
			# De-select old block_1
			block_1.sprite.modulate = Color.WHITE
			block_1.set_freeze_block(false)
		# Confirm selection
		block_1 = block
	elif block_number == 2:
		if block_2:
			# De-select old block_2
			block_2.sprite.modulate = Color.WHITE
			block_2.set_freeze_block(false)
		# Confirm selection
		block_2 = block
	pass
	
func _input(event):
	
	if shift_play_enabled and event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				var block = select_block(1)
				if block:
					block_1 = block
			MOUSE_BUTTON_RIGHT:
				var block = select_block(2)
				if block:
					block_2 = block
			MOUSE_BUTTON_MIDDLE:
				if !block_1 or !block_2:
					return
				# Swap if adjacent
				var block_distance = block_1.global_position.distance_to(block_2.global_position)
				if block_distance > block_1.block_width()*1.5:
					# blocks are next to each other (close)
					reset_select()
					return
				var swap_position = block_1.global_position
				block_1.global_position = block_2.global_position
				block_2.global_position = swap_position
				reset_select()
	
	# Mouse in viewport coordinates.
	if !shift_play_enabled and event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				spawn_block(BlockType.STAR, event.position)
			MOUSE_BUTTON_MIDDLE:
				spawn_block(BlockType.MOUNTAIN, event.position)
			MOUSE_BUTTON_RIGHT:
				spawn_block(BlockType.MOON, event.position)
	if event is InputEventKey and event.pressed and event.keycode == KEY_X:
		var cursor_block = get_block_at_cursor()
		if cursor_block:
			cursor_block.queue_free()
	if event is InputEventKey and event.pressed and event.keycode == KEY_SHIFT:
		shift_play_enabled = !shift_play_enabled

func get_block_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_mouse_position()
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 0b100
	
	var result = space_state.intersect_point(query)
	
	if result:
		var collider_node = result[0].collider
		return collider_node
	return null

func get_nearest_column_x_pos(x_pos):
	var remainder = int(x_pos) % 52
	if remainder < 52*0.5:
		return x_pos - remainder
	return x_pos - remainder + 52

func get_nearest_row_y_pos(y_pos):
	var remainder = int(y_pos) % 52
	if remainder < 52*0.5:
		return y_pos + remainder
	return y_pos - remainder - 52
	
func spawn_block(block_type, spawn_position) -> void:
	var adjusted_spawn_pos = Vector2(get_nearest_column_x_pos(spawn_position.x), get_nearest_column_x_pos(spawn_position.y))
	var colliding_block = get_block_at_cursor()
	if(colliding_block):
		adjusted_spawn_pos = colliding_block.global_position + Vector2(0, -104)
	
	var new_block = Node.new()
	match block_type:
		BlockType.STAR:
			new_block = preload("res://scenes/star_block.tscn").instantiate()
		BlockType.MOUNTAIN:
			new_block = preload("res://scenes/mountain_block.tscn").instantiate()
		BlockType.MOON:
			new_block = preload("res://scenes/moon_block.tscn").instantiate()
	new_block.global_position = adjusted_spawn_pos
	
	add_child(new_block)
	pass
