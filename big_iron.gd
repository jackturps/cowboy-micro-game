extends Node2D

const grab_dist_thresh = 150.0
var is_grabbed = false

var move_speed = Vector2.ZERO
var spin_speed = 0

# COG = center of gravity.
var cog_dist = 40

@onready var screen_size = get_viewport_rect().size

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10, Color.BLUE)
	draw_circle(Vector2(cog_dist, 0), 10, Color.RED)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func get_cog() -> Vector2:
	return cog_dist * Vector2.from_angle(rotation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	queue_redraw()
	
	var mouse_pos = get_viewport().get_mouse_position() - (screen_size / 2)
	if Input.is_action_just_pressed("grab") and mouse_pos.distance_to(global_position) < grab_dist_thresh:
		is_grabbed = true
	if not Input.is_action_pressed("grab"):
		is_grabbed = false
	
	spin_speed *= pow(0.3, delta)
	
	if is_grabbed:
		z_index = -1
		
		var prev_speed = move_speed
		var prev_pos = position
		position += (mouse_pos - position) * pow(0.2, delta)
		
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

	else:
		z_index = 0
		
		# Slough speed.
		move_speed = move_speed * pow(0.9, delta)
		move_speed += Game.gravity * delta
		position += move_speed * delta
		
		var clamp_pos = position.clamp(Vector2(-500, -9999), Vector2(500, 300))
		if clamp_pos.y != position.y:
			move_speed.y *= -0.5
		if clamp_pos.x != position.x:
			move_speed.x *= -0.8
		position = clamp_pos
		
		var center_of_gravity = get_cog()
		var world_pivot = position + center_of_gravity
		var rotate_offset = -center_of_gravity
		position = rotate_offset.rotated(spin_speed * delta) + world_pivot
		rotation += spin_speed * delta
			
	"""
	How do apply force along the pendulum? You take the gravity component, and then
	limit that to whatever component is moving along the normal vector? But how do
	we calculate just that component... is it the dot product? Lets try that out.
	It might actually be the cross product.
	
	Hm, this doesn't account for movement of the pendulum. How do we handle that?
	When we move to the right that is translated into rotation for the pendulum...
	because... because it can only exert force along the pendulum axis?
	
	Does the pendulum point need to just be a point that we constrain to the correct
	length each frame?
	
	So lets start by ignoring gravity and getting a zero-g pendulum working.
	"""
	#pendulum_speed *= pow(0.5, delta)
	#var pendulum_normal = -1 * pendulum_pos().normalized().orthogonal()
	#var angular_force = pendulum_normal.dot(gravity_acc.normalized())
	#var pendulum_acc = angular_force * gravity_acc.length()
	#pendulum_speed += pendulum_acc * delta
	#pendulum_angle += pendulum_speed * delta
	
