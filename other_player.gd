extends Node3D

var client_id

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the signal emitted by the TCP client script
	get_node("/root/Node3D/TCPClient").connect("player_position_changed", _on_player_position_changed)

# Called when the player position signal is received from the TCP client script
func _on_player_position_changed(data: String):
	print("received " + data + " for client " + str(client_id))
	var chunks = data.split(":")
	var vec
	for chunk in chunks:
		if chunk.left(1) == str(client_id):
			var coors = chunk.split("#")[1].split(",")
			var x = float(coors[0])
			var y = float(coors[1])
			var z = float(coors[2])
			vec = Vector3(x,y,z)
	if vec:
		# Update the position of the other player node
		global_transform.origin = vec

func init_player(player_id: int, vec: Vector3):
	client_id = player_id
	global_transform.origin = vec
