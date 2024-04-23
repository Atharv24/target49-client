extends Node3D
var interpolation_alpha = 1

var health = 0
var player_id

# Label for displaying delay
var delay_label: Label3D
var last_updated_at = Time.get_unix_time_from_system()

var timer = 0.0
var interval = 0.5

@onready var healthbar = $Sprite3D/SubViewport/HealthBar

func _ready():
	# Create a label for displaying delay
	delay_label = $Label3D
	delay_label.set_text("Delay: 0 ms")
func set_player_id(id: int):
	player_id = id
# Called when the player position signal is received from the UDP client script
func update_state(data: Array):
	var pos_data = data[0]
	var coors = pos_data.split(",")
	
	var x = float(coors[0])
	var y = float(coors[1])
	var z = float(coors[2])
	
	var vec = Vector3(x,y,z)
	
	global_transform.origin = global_transform.origin.move_toward(vec, interpolation_alpha)
	
	global_rotation.y = float(data[1])
	var health_data = int(data[2])
	if health != health_data:
		health = health_data
		update_healthbar()
	last_updated_at = int(data[3])
	
func _process(_delta):
	timer += _delta
	if timer > interval:
		timer = 0.0
		update_delay_label()

func update_healthbar():
	healthbar.value = health

func get_id():
	return player_id

# Update delay label
func update_delay_label():
	var current_time = Time.get_unix_time_from_system()*1000
	var delay = (current_time - last_updated_at)
	delay_label.set_text("Delay: " + str(delay).pad_decimals(2) + " ms")
	
