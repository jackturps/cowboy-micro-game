extends Node2D

enum State {
	holstered,
	falling,
	grabbed,
}

var state: State = State.holstered
var grounded = false

const grab_dist_thresh = 250.0
var is_grabbed = false

var move_speed = Vector2.ZERO
var spin_speed = 0

# COG = center of gravity.
var cog_dist = 60

# In radians.
var flip_progress = 0.0

var unlocked = false

signal hit_ground
signal flip_caught
signal released

func _draw() -> void:
	#draw_circle(Vector2.ZERO, 10, Color.BLUE)
	#draw_circle(Vector2(cog_dist, 0), 10, Color.RED)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func get_cog() -> Vector2:
	return cog_dist * Vector2.from_angle(rotation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	queue_redraw()
	
	var prev_rotation = rotation
	
	var screen_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position() - (screen_size / 2)
	
	# No transitions unless we're unlocked.
	if unlocked:
		if Input.is_action_just_pressed("grab") and mouse_pos.distance_to(global_position) < grab_dist_thresh:
			if state == State.falling and not grounded:
				flip_caught.emit(flip_progress)
			flip_progress = 0.0
			state = State.grabbed
			grounded = false
			$Clatter.play()
			
		if state == State.grabbed and not Input.is_action_pressed("grab"):
			state = State.falling
			$Clatter.play()
			released.emit()
		
	
	
	if state in [State.grabbed, State.holstered]:
		spin_speed *= pow(0.2, delta)
		
		flip_progress = 0.0
		
		var target_pos = mouse_pos if state == State.grabbed else get_node("../Pelvis").position + Vector2(-85, 0)
		
		var prev_speed = move_speed
		var prev_pos = position
		position += (target_pos - position) * pow(0.2, delta)
		
		# Smooth out our speed over a few frames.
		var instant_speed = (position - prev_pos) / delta
		move_speed = move_speed.lerp(instant_speed, 0.4)
		
		var move_force = (move_speed - prev_speed) / delta
		
		var total_force = move_force - Game.gravity
		const spin_damping = 0.0015
		total_force *= spin_damping
		
		var force_theta = total_force.angle_to(get_cog())
		var swing_magnitude = total_force.length() * sin(force_theta)
		var spin_force = (TAU * swing_magnitude)
		
		# TODO: Spin friction.
		spin_speed += spin_force * delta
		rotation += spin_speed * delta

	elif state == State.falling:
		spin_speed *= pow(0.7, delta)
		
		# Slough speed.
		move_speed = move_speed * pow(0.9, delta)
		move_speed += Game.gravity * delta
		position += move_speed * delta
		
		var clamp_pos = position.clamp(Vector2(-screen_size.x / 2, -999999), Vector2(screen_size.x / 2, screen_size.y / 2))
		if clamp_pos.y != position.y:
			move_speed.y *= -0.5
			if position.y > 0 and not grounded:
				hit_ground.emit()
				flip_progress = 0.0
				grounded = true
		if clamp_pos.x != position.x:
			move_speed.x *= -0.8
		position = clamp_pos
		
		var center_of_gravity = get_cog()
		var world_pivot = position + center_of_gravity
		var rotate_offset = -center_of_gravity
		position = rotate_offset.rotated(spin_speed * delta) + world_pivot
		rotation += spin_speed * delta
		
		flip_progress += abs(spin_speed * delta)
		
	
	var volume_target = smoothstep(TAU, 20.0 * TAU, abs(spin_speed))
	var volume_speed = 50.0 if volume_target > $Whoosh.volume_linear else 0.5
	$Whoosh.volume_linear = move_toward($Whoosh.volume_linear, volume_target, volume_speed * delta)
	$Whoosh.pitch_scale = 1.0 + 0.05 * $Whoosh.volume_linear
	if round(rotation / TAU) != round(prev_rotation / TAU):
		$Whoosh.play()
		
	var wind_target = smoothstep(200.0, 20000.0, move_speed.length())
	volume_speed = 0.5 if volume_target > $Wind.volume_linear else 0.5
	$Wind.volume_linear = move_toward($Wind.volume_linear, wind_target, volume_speed)
	$Wind.pitch_scale = 1.0 + 0.1 * $Wind.volume_linear
