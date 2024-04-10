extends Node

signal player_position_changed(position: String)

var tcp_client : StreamPeerTCP
var server_address = ""
var server_port = 0
var other_player = preload("res://other_player.tscn")
var player

@onready
var ping_label = $/root/Node3D/PingLabel

var self_id

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a TCP client
	tcp_client = StreamPeerTCP.new()
#	tcp_client.set_no_delay(true)

	# Attempt to connect to the server
	print("Connecting to server")
	
	var result = tcp_client.connect_to_host(Serverinfo.server_address, Serverinfo.server_port)
	if result == OK:
		print("Connected to server.")
	else:
		print("Failed to connect to server:", result)
	# Connect to the player's position changed signal
	player = get_node("/root/Node3D/Player")
	player.player_position_changed.connect(send_coordinates)


func send_coordinates(coordinates: Vector3):
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		# Convert coordinates to byte array
		var coor_str: String = str(self.self_id) + ":P:" + str(coordinates.x).pad_decimals(4) + "," +str(coordinates.y).pad_decimals(4) + "," + str(coordinates.z).pad_decimals(4)
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
				player_position_changed.emit(chunks[1])
			elif chunks[0] == "I":
				handleClientInit(chunks[1])
			elif chunks[0] == "N":
				create_new_player(chunks[1])
					
func create_new_player(data: String):
	var chunks = data.split("#")
	var client_id = int(chunks[0])
	
	var coors = chunks[1].split(",")
	var x = float(coors[0])
	var y = float(coors[1])
	var z = float(coors[2])
	
	var initPos = Vector3(x, y, z)
	
	var other_player_node = other_player.instantiate()
	get_node(".").add_sibling(other_player_node)
	other_player_node.init_player(client_id, initPos)

func handleClientInit(data: String):
	var chunks = data.split("#")
	self_id = int(chunks[0])
	print("Assigned Self ID:", self_id)
	
	var coors = chunks[1].split(",")
	var x = float(coors[0])
	var y = float(coors[1])
	var z = float(coors[2])
	
	var initPos = Vector3(x, y, z)
	setInitPos(initPos)
	
func setInitPos(pos: Vector3):
	player.set_player_position(pos)
