extends KinematicBody

onready var weapon_fire = [preload("res://Audio/Megaman/buster_shot_sfx.wav")]

var weapons = ["Buster", "Machine Arm"]
var current_weapon = 0

var iw_blend
var wr_blend

var direction = Vector3.BACK
var velocity = Vector3.ZERO

var aim_turn = 0

var vertical_velocity = 0
var gravity = 28
var jump_magnitude = 15
var weight_on_ground = 4

var movement_speed = 0
var walk_speed = 1.5
var run_speed = 7
var acceleration = 6
var roll_magnitude = 45
var angular_acceleration = 7

func _input(event):
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015
	
	if event.is_action_pressed("sprint"):
		if $roll_window.is_stopped():
			$roll_window.start()
		
	if event.is_action_released("sprint"):
		if !$roll_window.is_stopped():
			velocity = direction * roll_magnitude
			$roll_window.stop()
			$megaman/Buster/AnimationTree.set("parameters/roll/active", true)
	
	if event.is_action_pressed("fire"):
		if $megaman/Buster/AnimationTree.get("parameters/iwr_blend/blend_amount") < 0:
			$megaman/Buster/Armature/Skeleton/SkeletonIK.start()
			$megaman/Buster/AnimationTree.set("parameters/shoot/active", true)
		else:
			$megaman/Buster/Armature/Skeleton/SkeletonIK.start()
	
	if event.is_action_released("fire"):
		if !$aim_stay_delay.is_stopped():
			$megaman/Buster/Armature/Skeleton/SkeletonIK.stop()

func _physics_process(delta):
	if Input.is_action_pressed("fire"):
		$aim_stay_delay.start()
		if $shoot_timer.is_stopped():
			$shoot_timer.start()
			$shoot_sfx.stream.audio_stream = weapon_fire[0]
			$shoot_sfx.play()			
	
	_handle_move_input(delta)
	_apply_movement(delta)
	_apply_gravity(delta)

func _apply_gravity(delta):
	if !is_on_floor():
		vertical_velocity -= gravity * delta
	else:
		vertical_velocity = 0

func _apply_movement(delta):
	if !$roll_timer.is_stopped():
		acceleration = 3.5
	else:
		acceleration = 5
		
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)
	
	iw_blend = (velocity.length() - walk_speed) / walk_speed
	wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)
	
	if velocity.length() <= walk_speed:
		$megaman/Buster/AnimationTree.set("parameters/iwr_blend/blend_amount", iw_blend)
	else:
		$megaman/Buster/AnimationTree.set("parameters/iwr_blend/blend_amount", wr_blend)
	
	move_and_slide(velocity + Vector3.UP * vertical_velocity - get_floor_normal() * weight_on_ground, Vector3.UP)

func _handle_move_input(delta):
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("move_forward") || Input.is_action_pressed("move_backwards") || Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):

		direction = Vector3(Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
					0,
					Input.get_action_strength("move_forward") - Input.get_action_strength("move_backwards"))
		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
		
		if Input.is_action_pressed("sprint"):
			movement_speed = run_speed
		else:
			movement_speed = walk_speed
	else:
		# Idle, not moving
		$megaman/Buster/AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($megaman/Buster/AnimationTree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		movement_speed = 0
			
	$megaman.rotation.y = lerp_angle($megaman.rotation.y, $Camroot/h.rotation.y, delta * angular_acceleration)

	aim_turn = 0
