"""
Credits:
	https://unsplash.com/photos/a-man-sitting-on-a-chair-outside-qon55SxMVCw
	https://pixabay.com/photos/hat-cowboy-white-brown-leather-316399/
	https://www.dafont.com/vanilla-whale.font?l[]=10
	https://pixabay.com/sound-effects/film-special-effects-whip-crack-123738/
	https://pixabay.com/sound-effects/film-special-effects-whip-06-487886/
	https://pixabay.com/sound-effects/film-special-effects-whip-snap-242215/
	https://pixabay.com/photos/full-moon-night-sky-luna-moon-1869760/
	https://pixabay.com/sound-effects/household-short-whoosh-13x-14526/
	https://pixabay.com/sound-effects/nature-harsh-wind-515272/
	https://pixabay.com/sound-effects/nature-cow-moo-122255/
	Charlie Turpitt

Shout Outs:
	Tropic of Dinosaur: https://www.gamepoems.com/issue01/
"""

class_name Game extends Node2D

const gravity = Vector2(0, 1000)
 
@onready var screen_size = get_viewport_rect().size
@onready var prev_gun_rotation = $BigIron.rotation

var blink_countdown = 3.0

func on_hit_ground():
	$LongYee.stop()
	$SadHaw.play()
	$InstructionLabel.text = "F U M B L E D"
	$Whip3.play()

func on_flip_caught(flip_progress):
	$LongYee.stop()
	
	var num_flips = int(max(0, floor(flip_progress / TAU)))
	match num_flips:
		0: 
			$InstructionLabel.text = "N O   F L I P S"
			$SadHaw.play()
		1:
			$InstructionLabel.text = "1   F L I P"
			$Haw.play()
		_:
			$InstructionLabel.text = "%s   F L I P S" % [num_flips]
			$Haw.play()
	$Whip3.play()

func on_released():
	$LongYee.play()
	$InstructionLabel.text = ""

func _ready() -> void:
	$Wind.play()
	
	$BigIron.hit_ground.connect(on_hit_ground)
	$BigIron.flip_caught.connect(on_flip_caught)
	$BigIron.released.connect(on_released)
		
	var tween = create_tween()
	tween.tween_callback(func():
		$Whip1.play() 
		$InstructionLabel.text = "F L I P"
	)
	tween.tween_interval(1.23)
	tween.tween_callback(func(): 
		$Whip2.play()
		$InstructionLabel.text = "Y E R"
	)
	tween.tween_interval(1.23)
	tween.tween_callback(func(): 
		$Whip3.play()
		$InstructionLabel.text = "B I G   I R O N"
	)
	tween.tween_interval(1.23)
	tween.tween_callback(func(): 
		$InstructionLabel.text = ""
		$BigIron.unlocked = true
	)
	

func solve_leg(thigh: Node2D, foot: Node2D, bend_sign := 1.0) -> void:
	const thigh_len = 225
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
	
	# TODO: Shrink sprite.
	var foot_scale = max(1, foot.position.distance_to(knee_pos) / foot_len)
	foot.scale.x = 0.75 * foot_scale
	foot.scale.y = 0.75 * (1.0 / foot_scale)


func _physics_process(delta: float) -> void:
	var half_screen = screen_size / 2
	var mouse_pos = get_viewport().get_mouse_position() - half_screen
	
	$Hand.position = mouse_pos
	$Hand/AnimatedSprite2D.animation = "closed" if Input.is_action_pressed("grab") else "open"
	
	# Bicep crooks as hand gets closer.
	$Bicep.position = Vector2(-300, -100) + (mouse_pos / half_screen) * Vector2(250, 150)
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
	$Forearm.scale.y = min(1.0, 1.0 / stretch_factor)
	
	$Hand.rotation = $Forearm.rotation
	
	
	#var gun_height = max(0, -1 * $BigIron.position.y)
	#var gun_excess = max(0, gun_height - half_screen.y)
	#$Camera2D.position = Vector2(0.0, -gun_excess / 2)
	#$Camera2D.zoom = Vector2.ONE * min(1, abs(1.5 * half_screen.y / max(1, gun_height)))

	var gun_pos = $BigIron.position + $BigIron.get_cog()
	var gun_margin = 0.1 * abs(gun_pos.y)
	var cam_top = gun_pos.y - gun_margin
	var cam_bot = half_screen.y # + 600 * smoothstep(-half_screen.y, -10000, cam_top)
	var cam_y_frame = abs(cam_bot - cam_top)
	
	$Camera2D.position.y = min(0, cam_bot - (cam_y_frame / 2))
	$Camera2D.zoom = Vector2.ONE * min(1, screen_size.y / max(cam_y_frame, 1))


	$Head.position = $Torso.position + Vector2(130, -40)
	#$Head.rotation = ($BigIron.position - $Head.position).angle() * smoothstep(0, half_screen.y, gun_height)

	# Legs.
	$Pelvis.position = $Bicep.position + Vector2(80, 270)
	
	$RightThigh.position = $Pelvis.position + Vector2(80, 60)
	$RightFoot.position = Vector2(50, half_screen.y - 50)
	solve_leg($RightThigh, $RightFoot, +1.0)

	$LeftThigh.position = $Pelvis.position + Vector2(-60, 50)
	$LeftFoot.position = Vector2(-550, half_screen.y - 50)
	solve_leg($LeftThigh, $LeftFoot, -1.0)
	
	blink_countdown -= delta
	if blink_countdown <= 0:
		if $Head.animation == "blink":
			$Head.animation = "default"
			blink_countdown = randf_range(0.3, 3.0)
		else:
			$Head.animation = "blink"
			blink_countdown = randf_range(0.1, 0.2)

	var spin_speed = abs($BigIron.spin_speed)
	var volume_target = smoothstep(TAU, 20.0 * TAU, spin_speed)
	var volume_speed = 50.0 if volume_target > $Whoosh.volume_linear else 0.5
	$Whoosh.volume_linear = move_toward($Whoosh.volume_linear, volume_target, volume_speed * delta)
	$Whoosh.pitch_scale = 1.0 + 0.05 * smoothstep(TAU, 3.0 * TAU, spin_speed)
	if round($BigIron.rotation / TAU) != round(prev_gun_rotation / TAU):
		$Whoosh.play()
	prev_gun_rotation = $BigIron.rotation
	
	var wind_target = smoothstep(200.0, 20000.0, $BigIron.move_speed.length())
	volume_speed = 0.5 if volume_target > $Wind.volume_linear else 0.5
	$Wind.volume_linear = move_toward($Wind.volume_linear, wind_target, volume_speed)
	$Wind.pitch_scale = 1.0 + 0.1 * $Wind.volume_linear

	
	$Sky.material.set_shader_parameter("texture_size", $Sky.size)
