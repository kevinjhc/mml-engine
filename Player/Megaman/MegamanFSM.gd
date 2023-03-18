extends "res://Player/Megaman/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("falling")
	call_deferred("set_state", states.idle)

func _input(event):
	if [states.idle, states.run].has(state):
		get_node("../megaman/Buster/AnimationTree").set("parameters/ag_transition/current", 1)
		
		if Input.is_action_just_pressed("jump"):
			get_node("../megaman/Buster/AnimationTree").set("parameters/ag_transition/current", 0)
			parent.vertical_velocity = parent.jump_magnitude

func _state_logic(delta):
	parent._handle_move_input(delta)
	parent._apply_gravity(delta)
	parent._apply_movement(delta)
	
func _get_transition(delta):
	match state:
		states.idle:
			if !parent.is_on_floor():
				if parent.vertical_velocity > 0:
					return states.jump
				elif parent.vertical_velocity < 0:
					return states.falling
			elif parent.movement_speed != 0:
				return states.run
		states.run:
			if !parent.is_on_floor():
				if parent.velocity.z < 0:
					return states.jump
				elif parent.velocity.z > 0:
					return states.falling
			elif parent.movement_speed == 0:
				return states.idle
		states.jump:
			if parent.is_on_floor():
				return states.idle
			elif parent.vertical_velocity < 0:
				return states.falling
		states.falling:
			if parent.is_on_floor():
				return states.idle
			elif parent.vertical_velocity > 0:
				return states.jump
	
	return null
	
func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			get_node("../Status/Label").text = "idle"
		states.run:
			get_node("../Status/Label").text = "run"
		states.jump:
			get_node("../Status/Label").text = "jump"
		states.falling:
			get_node("../Status/Label").text = "falling"

func _exit_state(old_state, new_state):
	pass
