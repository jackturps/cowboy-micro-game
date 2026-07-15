# Copyright (c) 2026 Jack Turpitt
# Licensed under MIT with AI Training Restriction — see LICENSE

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
	https://unsplash.com/photos/white-clouds-and-blue-sky-during-daytime-A9_IsUtjHm4
	https://pixabay.com/photos/hat-cowboy-white-brown-leather-316399/
	https://unsplash.com/photos/brown-and-black-revolver-pistol-LSu04HMpL7A
	https://unsplash.com/photos/gold-and-silver-heart-pendant-MGScaQTG8To
	https://pixabay.com/sound-effects/film-special-effects-sparkler-fuse-nmwav-14738/
	Charlie Turpitt

Shout Outs:
	Tropic of Dinosaur: https://www.gamepoems.com/issue01/
"""

class_name Game extends Node2D

static var started = false

const gravity = Vector2(0, 1000)

@onready var prev_gun_rotation = $BigIron.rotation


var blink_countdown = 3.0

const max_countdown = 10.0
var countdown = max_countdown

static func is_colonq_build():
	return OS.has_feature("colonq")


func end_game(did_win: bool):
	$BigIron.unlocked = false
	
	if is_colonq_build():
		var tween = create_tween()
		tween.tween_callback(func():
			Game.started = false
			var win_str = "true" if did_win else "false"
			JavaScriptBridge.eval("window.parent.postMessage({op: \"done\", win: %s});" % [win_str])
			get_tree().reload_current_scene()
		).set_delay(2.63)
	else:
		var tween = create_tween()
		tween.tween_callback(func():
			countdown = max_countdown
			$BigIron.unlocked = true
			$InstructionLabel.text = ""
		).set_delay(2.63)

func on_hit_ground():
	$LongYee.stop()
	$SadHaw.play()
	$InstructionLabel.text = "F U M B L E D"
	end_game(false)


func on_flip_caught(flip_progress):
	$LongYee.stop()
	
	var num_flips = int(max(0, floor(flip_progress / TAU)))
	match num_flips:
		0: 
			$InstructionLabel.text = "N O   F L I P S"
			$SadHaw.play()
			end_game(false)
		1:
			$InstructionLabel.text = "1   F L I P"
			$Haw.play()
			end_game(true)
		_:
			$InstructionLabel.text = "%s   F L I P S" % [num_flips]
			$Haw.play()
			end_game(true)
	$Whip3.play()

func on_countdown_expired():
	$InstructionLabel.text = "T I M E   U P"
	$SadHaw.play()
	end_game(false)

func on_released():
	$LongYee.play()
	$InstructionLabel.text = ""


func _ready() -> void:
	$BigIron.hit_ground.connect(on_hit_ground)
	$BigIron.flip_caught.connect(on_flip_caught)
	$BigIron.released.connect(on_released)
	$Fuse.volume_linear = 0.0
	
	JavaScriptBridge.eval("window.parent.postMessage({op: \"ready\"});")
	

func start_game():
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
	"""
	This is an entry in the COLONQ micro-game jam, which requires some custom
	signalling to an external harness. If built with the 'colonq' feature 
	we'll run inside the harness, otherwise we'll run independently.
	
	More details can be found here: https://api.colonq.computer/jam/2026
	"""
	var colonq_output = JavaScriptBridge.eval("window.lcolonqJamStart || -1.0")
	var colonq_started = colonq_output != null and colonq_output > 0.0
	if not Game.started and (colonq_started or not is_colonq_build()):
		Game.started = true
		JavaScriptBridge.eval("window.parent.postMessage({op: \"started\"});")
		start_game()
	
	var ebb = sin(1.2 * Time.get_ticks_msec() / 1000.0)
	
	var screen_size = get_viewport_rect().size
	
	var half_screen = screen_size / 2
	var mouse_pos = get_viewport().get_mouse_position() - half_screen
	
	$Hand.position = mouse_pos
	$Hand/AnimatedSprite2D.animation = "closed" if Input.is_action_pressed("grab") else "open"
	
	# Elbow crooks as hand gets closer.
	$Bicep.position = Vector2(-300, -100) + (mouse_pos / half_screen) * Vector2(250, 150)
	var elbow_bend = smoothstep(1000, 50, $Hand.position.distance_to($Bicep.position))
	elbow_bend *= (TAU / 3.0) + (TAU / 40.0) * ebb
	$Bicep.rotation = ($Hand.position - $Bicep.position).angle() + elbow_bend
	
	$Torso.position = $Bicep.position
	var torso_ebb = (1.0 + ebb * 0.02)
	$Torso.scale.x = 0.35 * (1 / torso_ebb)
	$Torso.scale.y = 0.35 * torso_ebb
		
	# Forearm points towards hand and squashes/stretches to make up distance.
	const forearm_len = 300
	
	var wrist_pos = $Hand.position + Vector2(-85, 30).rotated($Hand.rotation)
	
	var hand_diff = wrist_pos - $Forearm.position
	$Forearm.position = $Bicep.position + 210 * Vector2.RIGHT.rotated($Bicep.rotation)
	$Forearm.rotation = (hand_diff).angle()
	var stretch_factor = max(1, hand_diff.length()) / forearm_len
	$Forearm.scale.x = stretch_factor
	$Forearm.scale.y = min(1.0, 1.0 / stretch_factor)
	
	$Hand.rotation = $Forearm.rotation
	
	var gun_pos = $BigIron.position
	if $BigIron.state == $BigIron.State.falling:
		gun_pos += $BigIron.get_cog()

	var gun_margin = 0.1 * abs(gun_pos.y)
	var cam_top = gun_pos.y - gun_margin
	var cam_bot = half_screen.y # + 600 * smoothstep(-half_screen.y, -10000, cam_top)
	var cam_y_frame = abs(cam_bot - cam_top)
	
	$Camera2D.position.y = min(0, cam_bot - (cam_y_frame / 2))
	$Camera2D.zoom = Vector2.ONE * min(1, screen_size.y / max(cam_y_frame, 1))

	$Head.position = $Torso.position + Vector2(95, -30)
	var head_target = (gun_pos - $Head.position).angle() / 2 + (ebb * TAU / 80.0)
	var head_smooving = 1.0 - pow(0.0005, delta)
	$Head.rotation += angle_difference($Head.rotation, head_target) * head_smooving

	# Legs.
	$Pelvis.position = $Bicep.position + Vector2(60, 250) * Vector2(1, torso_ebb)
	
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
	
	$Sky.material.set_shader_parameter("texture_size", $Sky.size)
	
	var prev_countdown = countdown
	var fuse_volume_target = 0.0
	if $BigIron.unlocked and $BigIron.state != $BigIron.State.falling:
		countdown = max(0, countdown - delta)
		fuse_volume_target = 1.5
	$Fuse.volume_linear = move_toward($Fuse.volume_linear, fuse_volume_target, 2.0 * delta)
	var countdown_factor = countdown / max_countdown
	$UI/Wick.material.set_shader_parameter("countdown", countdown_factor)
	$UI/Path2D/PathFollow2D.progress_ratio = 1.0 - countdown_factor
	
	if prev_countdown > 0 and countdown <= 0:
		on_countdown_expired()
