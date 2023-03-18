extends KinematicBody

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

onready var animator = get_node("AnimationPlayer")

func _input(event):
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015
		
	if event.is_action_pressed("aim"):
		$megaman/Skeleton/SkeletonIK.start()
	
	if event.is_action_released("aim"):
		$megaman/Skeleton/SkeletonIK.stop()

func _physics_process(delta):
	
	if Input.is_action_pressed("aim"):
		$AnimationTree.set("parameters/aim_transition/current", 0)
		#$megaman/Skeleton/SkeletonIK.start(false)
	else:
		$AnimationTree.set("parameters/aim_transition/current", 1)
		#$megaman/Skeleton/SkeletonIK.start(true)
	
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("move_forward") || Input.is_action_pressed("move_backwards") || Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):

		direction = Vector3(Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
					0,
					Input.get_action_strength("move_forward") - Input.get_action_strength("move_backwards"))
		
		strafe_dir =  direction
		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
		
		if Input.is_action_pressed("sprint") && $AnimationTree.get("parameters/aim_transition/current") == 1:
			movement_speed = run_speed
			#$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), 1, delta * acceleration))
		else:
			movement_speed = walk_speed
			#$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), 0, delta * acceleration))
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		movement_speed = 0
		strafe_dir = Vector3.ZERO
		
		if $AnimationTree.get("parameters/aim_transition/current") == 1:
			direction = $Camroot/h.global_transform.basis.z

	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)

	move_and_slide(velocity + Vector3.DOWN * vertical_velocity, Vector3.UP)
	
	if !is_on_floor():
		vertical_velocity += gravity * delta
	else:
		vertical_velocity = 0

	if $AnimationTree.get("parameters/aim_transition/current") == 1:
		$megaman.rotation.y = lerp_angle($megaman.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
		# Sometimes in the level design you might need to rotate the Player object itself
		# - rotation.y in case you need to rotate the Player object
	else:
		$megaman.rotation.y = lerp_angle($megaman.rotation.y, $Camroot/h.rotation.y, delta * angular_acceleration)
		# lerping towards $Camroot/h.rotation.y while aiming, h_rot(as in the video) doesn't work if you rotate Player object

	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
	
	$AnimationTree.set("parameters/strafe/blend_position", Vector2(-strafe.x, strafe.z))
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)
	
	if velocity.length() <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount", iw_blend)
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount", wr_blend)
	
	aim_turn = 0

	$Status/Label.text = "direction : " + String(direction)
	$Status/Label2.text = "direction.length() : " + String(direction.length())
	$Status/Label3.text = "velocity : " + String(velocity)
	$Status/Label4.text = "velocity.length() : " + String(velocity.length())
