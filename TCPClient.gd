extends Node

var tcp_client : StreamPeerTCP
var server_address = ""
var server_port = 0
var other_player = preload("res://other_player.tscn")

var other_players_dict = {}

@onready
var ping_label = $/root/Node3D/PingLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a TCP client
	tcp_client = StreamPeerTCP.new()
	
	var result = tcp_client.connect_to_host(Serverinfo.server_address, Serverinfo.server_port)
	if result == OK:
		print("Connected to server.")
	else:
		print("Failed to connect to server:", result)
	# Connect to the player's position changed signal
	var player = get_node("/root/Node3D/Player")
	player.player_position_changed.connect(send_coordinates)


func send_coordinates(coordinates: Vector3):
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		# Convert coordinates to byte array
		var coor_str: String = "P:" + str(coordinates.x).pad_decimals(4) + "," +str(coordinates.y).pad_decimals(4) + "," + str(coordinates.z).pad_decimals(4)
		# Send the data
		var _result = tcp_client.put_data(coor_str.to_utf8_buffer())
		if _result != OK:
			print("Error sending data:", _result)
	else:
		tcp_client.poll()

func _process(_delta):
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		if tcp_client.get_available_bytes() > 0:
			var data = tcp_client.get_partial_data(1024)
			var message = ""
			for byte in data[1]:
				message += char(byte)
			var chunks = message.split(":")
			if chunks[0] == "P":
				update_pos(int(chunks[1]), chunks[2])
			elif chunks[0] == "N":
				create_new_players(chunks[1])
			elif chunks[0] == "D":
				remove_player(chunks[1])
			else:
				print("Received unknown message: ", message)
					
func create_new_players(data: String):
	var new_players = data.split(",")
	for new_player in new_players:
		var client_id = int(new_player)
		var other_player_node = other_player.instantiate()
		get_node(".").add_sibling(other_player_node)
		other_players_dict[client_id] = other_player_node

func remove_player(data: String):
	var client_id = int(data)
	var other_player_node: Node = other_players_dict[client_id]
	get_node("/root/Node3D").remove_child(other_player_node)
	other_players_dict.erase(client_id)
	
func update_pos(client_id: int, data: String):
	if other_players_dict.has(client_id):
		var player_node = other_players_dict[client_id]
		player_node.update_position(data)
	
