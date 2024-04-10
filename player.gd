extends CharacterBody3D

signal player_position_changed(position: Vector3)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var interval = 0.1 # Time interval in seconds
var timer = 0.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Mouselook variables
#var look_sensitivity = 0.05
#@onready var camera:Camera3D = $Node3D/Camera3D
#
#func _input(event):
#	if event is InputEventMouseMotion:
#		rotate_y(-event.relative.x * look_sensitivity)
#		camera.rotate_x(-event.relative.y * look_sensitivity)
#		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	timer+=delta
	if (timer>interval):
		timer = 0.0
		player_position_changed.emit(get_player_position())
	
# Function to retrieve the player's position
func get_player_position() -> Vector3:
	return global_position
	
func set_player_position(vec: Vector3):
	global_transform.origin = vec
