extends Spatial

var current_weapon_model
onready var current_model_animation_player
onready var current_model_animation_tree
onready var current_armature
onready var current_ik

var direction = Vector3.BACK
var velocity = Vector3.ZERO
var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var aim_turn = 0

var vertical_velocity = 0
var gravity = 30

var movement_speed = 0
var walk_speed = 1.5
var run_speed = 7
var acceleration = 6
var angular_acceleration = 7

func _ready():
	for N in get_node("Models").get_children():
		if N.is_visible() && (N.get_name() != "Camroot"):
			current_weapon_model = N
			current_model_animation_player = current_weapon_model.get_node("AnimationPlayer")
			current_model_animation_tree = current_weapon_model.get_node("AnimationTree")
			current_armature = current_weapon_model.get_node("Armature")
			current_ik = current_armature.get_node("Skeleton/SkeletonIK")

func _input(event):
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015

	if event.is_action_pressed("aim"):
		current_ik.start()
	
	if event.is_action_released("aim"):
		current_ik.stop()

func _physics_process(delta):
	
	if Input.is_action_just_pressed("switch_weapon"):
		if get_node("Models/Buster").is_visible():
			get_node("Models/Buster").hide()
			current_ik.stop()
			get_node("Models/Machine Arm").show()
			current_weapon_model = get_node("Models/Machine Arm")
		elif get_node("Models/Machine Arm").is_visible():
			get_node("Models/Machine Arm").hide()
			current_ik.stop()
			get_node("Models/Buster").show()
			current_weapon_model = get_node("Models/Buster")
			
	current_model_animation_player = current_weapon_model.get_node("AnimationPlayer")
	current_model_animation_tree = current_weapon_model.get_node("AnimationTree")
	current_armature = current_weapon_model.get_node("Armature")
	current_ik = current_armature.get_node("Skeleton/SkeletonIK")

	if Input.is_action_pressed("aim"):
		current_model_animation_tree.set("parameters/aim_transition/current", 0)
	else:
		current_model_animation_tree.set("parameters/aim_transition/current", 1)

	var h_rot = $Models/Camroot/h.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("move_forward") || Input.is_action_pressed("move_backwards") || Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
		direction = Vector3(Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
					0,
					Input.get_action_strength("move_forward") - Input.get_action_strength("move_backwards"))
		
		strafe_dir =  direction
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
		
		if Input.is_action_pressed("sprint") && current_model_animation_tree.get("parameters/aim_transition/current") == 1:
			movement_speed = run_speed
		else:
			movement_speed = walk_speed
	else:
		current_model_animation_tree.set("parameters/iwr_blend/blend_amount", lerp(current_model_animation_tree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		movement_speed = 0
		strafe_dir = Vector3.ZERO
		
		if current_model_animation_tree.get("parameters/aim_transition/current") == 1:
			direction = $Models/Camroot/h.global_transform.basis.z

	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)

	get_node("Models").move_and_slide(velocity + Vector3.DOWN * vertical_velocity, Vector3.UP)
	#current_weapon_model.move_and_slide(velocity + Vector3.DOWN * vertical_velocity, Vector3.UP)

	#if !current_weapon_model.is_on_floor():
	#	vertical_velocity += gravity * delta
	#else:
	#	vertical_velocity = 0

	if current_model_animation_tree.get("parameters/aim_transition/current") == 1:
		current_armature.rotation.y = lerp_angle(current_armature.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
	else:
		current_armature.rotation.y = lerp_angle(current_armature.rotation.y, $Models/Camroot/h.rotation.y, delta * angular_acceleration)

	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
	
	current_model_animation_tree.set("parameters/strafe/blend_position", Vector2(-strafe.x, strafe.z))
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)
	
	if velocity.length() <= walk_speed:
		current_model_animation_tree.set("parameters/iwr_blend/blend_amount", iw_blend)
	else:
		current_model_animation_tree.set("parameters/iwr_blend/blend_amount", wr_blend)
	
	aim_turn = 0
