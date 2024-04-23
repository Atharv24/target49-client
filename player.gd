extends CharacterBody3D

signal player_state_changed(state: Array)
signal player_shot(hit_player_id: int)

const SPEED = 6.0
const JUMP_VELOCITY = 6
const MOUSE_SENSITIVITY = 0.005
const RAY_LENGTH = 1000

const interval = 0.01 # Time interval in seconds
var timer = 0.0

var paused = false
var health = 5
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var pistol = $Camera3D/Pistol
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var health_bar = $"../UI/HealthBar"


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not paused:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if Input.is_action_just_pressed("pause"):
		if paused:
			paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects()
		shoot()
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Vector2.ZERO
		if not paused:
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
			input_dir = Input.get_vector("left", "right", "forward", "back")
			
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		if anim_player.current_animation == "shoot":
			pass
		elif input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("move")
		else:
			anim_player.play("idle")
	move_and_slide()
	
	timer+=delta
	if (timer>interval):
		timer = 0.0
		player_state_changed.emit(get_player_position())
	
func shoot():
	var space_state = get_world_3d().direct_space_state

	var origin = camera.global_transform.origin
	var end = origin + camera.global_transform.basis.z * -1 * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		var other_player = result.collider
		if other_player.has_method("get_id"):
			var other_player_id = other_player.get_id()
			player_shot.emit(int(other_player_id))

# Function to retrieve the player's position
func get_player_position() -> Array:
	return [global_position, rotation.y]
	
func update_position(data: String):
	var coors = data.split(",")
	
	var x = float(coors[0])
	var y = float(coors[1])
	var z = float(coors[2])
	
	var vec = Vector3(x,y,z)
	global_transform.origin = vec

func reset(data: String):
	var chunks = data.split(":")
	update_position(chunks[0])
	global_rotation.y = float(chunks[1])
	update_health(int(chunks[2]))
	timer = -2.0

func update_health(new_health: int):
	if health != new_health:
		health_bar.value = new_health
		health = new_health
		
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
