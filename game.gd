"""
Credits:
	- https://unsplash.com/photos/a-man-sitting-on-a-chair-outside-qon55SxMVCw
"""

class_name Game extends Node2D

const gravity = Vector2(0, 800)

@onready var screen_size = get_viewport_rect().size

func _physics_process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position() - (screen_size / 2)
	
	$Hand.position = mouse_pos
	$Hand/AnimatedSprite2D.animation = "closed" if Input.is_action_pressed("grab") else "open"
	
	# Bicep crooks as hand gets closer.
	$Bicep.position = Vector2(0, -300)
	var elbow_bend = smoothstep(1000, 50, $Hand.position.distance_to($Bicep.position))
	elbow_bend *= TAU / 3
	$Bicep.rotation = ($Hand.position - $Bicep.position).angle() + elbow_bend
	
	# Forearm points towards hand and squashes/stretches to make up distance.
	const forearm_len = 350
	var hand_diff = $Hand.position - $Forearm.position
	$Forearm.position = $Bicep.position + 210 * Vector2.RIGHT.rotated($Bicep.rotation)
	$Forearm.rotation = (hand_diff).angle()
	var stretch_factor = max(1, hand_diff.length()) / forearm_len
	$Forearm.scale.x = stretch_factor
	$Forearm.scale.y = 1.0 / stretch_factor
	
	$Hand.rotation = $Forearm.rotation
	
	
	var half_screen = screen_size / 2.0
	var margin = 100.0  # buffer in pixels, tune to taste
	
	var gun_height = max(0, -1 * $BigIron.position.y)
	var gun_excess = max(0, gun_height - half_screen.y)
	$Camera2D.position = Vector2(0.0, -gun_excess / 2)
	$Camera2D.zoom = Vector2.ONE * min(1, abs(1.5 * half_screen.y / max(1, gun_height)))
	pass
