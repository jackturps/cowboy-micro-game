"""
Credits:
	https://unsplash.com/photos/a-man-sitting-on-a-chair-outside-qon55SxMVCw
	https://pixabay.com/photos/hat-cowboy-white-brown-leather-316399/
"""

class_name Game extends Node2D

const gravity = Vector2(0, 800)

@onready var screen_size = get_viewport_rect().size

func solve_leg(thigh: Node2D, foot: Node2D, bend_sign := 1.0) -> void:
	const thigh_len = 280
	const foot_len = 250
	
	var leg_diff = foot.position - thigh.position
	var total_dist = leg_diff.length()
	total_dist = clamp(total_dist, abs(thigh_len - foot_len) + 0.01, thigh_len + foot_len - 0.01)

	var cos_hip_angle = (thigh_len*thigh_len + total_dist*total_dist - foot_len*foot_len) / (2 * thigh_len * total_dist)
	var hip_angle = acos(clamp(cos_hip_angle, -1.0, 1.0))

	var knee_dir = leg_diff.normalized().rotated(-hip_angle * bend_sign)
	var knee_pos = thigh.position + knee_dir * thigh_len

	thigh.rotation = thigh.position.angle_to_point(knee_pos)
	foot.rotation = foot.position.angle_to_point(knee_pos)


func _physics_process(delta: float) -> void:
	var half_screen = screen_size / 2
	var mouse_pos = get_viewport().get_mouse_position() - half_screen
	
	$Hand.position = mouse_pos
	$Hand/AnimatedSprite2D.animation = "closed" if Input.is_action_pressed("grab") else "open"
	
	# Bicep crooks as hand gets closer.
	$Bicep.position = Vector2(0, -100) + (mouse_pos / half_screen) * Vector2(100, 50)
	var elbow_bend = smoothstep(1000, 50, $Hand.position.distance_to($Bicep.position))
	elbow_bend *= TAU / 3
	$Bicep.rotation = ($Hand.position - $Bicep.position).angle() + elbow_bend
	
	$Torso.position = $Bicep.position
		
	# Forearm points towards hand and squashes/stretches to make up distance.
	const forearm_len = 350
	var hand_diff = $Hand.position - $Forearm.position
	$Forearm.position = $Bicep.position + 210 * Vector2.RIGHT.rotated($Bicep.rotation)
	$Forearm.rotation = (hand_diff).angle()
	var stretch_factor = max(1, hand_diff.length()) / forearm_len
	$Forearm.scale.x = stretch_factor
	$Forearm.scale.y = 1.0 / stretch_factor
	
	$Hand.rotation = $Forearm.rotation
	
	
	var gun_height = max(0, -1 * $BigIron.position.y)
	var gun_excess = max(0, gun_height - half_screen.y)
	$Camera2D.position = Vector2(0.0, -gun_excess / 2)
	$Camera2D.zoom = Vector2.ONE * min(1, abs(1.5 * half_screen.y / max(1, gun_height)))


	$Head.position = $Torso.position + Vector2(140, -80)
	$Head.rotation = ($BigIron.position - $Head.position).angle() * smoothstep(0, half_screen.y, gun_height)


	# Legs.
	$Pelvis.position = $Bicep.position + Vector2(80, 310)
	
	$RightThigh.position = $Pelvis.position + Vector2(80, 60)
	$RightFoot.position = Vector2(350, half_screen.y - 50)
	solve_leg($RightThigh, $RightFoot, +1.0)

	$LeftThigh.position = $Pelvis.position + Vector2(-60, 50)
	$LeftFoot.position = Vector2(-300, half_screen.y - 50)
	solve_leg($LeftThigh, $LeftFoot, -1.0)
