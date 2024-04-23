extends Node

var udp_peer : PacketPeerUDP
var other_player = preload("res://other_player.tscn")

var other_players_dict = {}
var player
var self_id

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a UDP client
	udp_peer = PacketPeerUDP.new()

	var result = udp_peer.connect_to_host(Serverinfo.server_address, Serverinfo.server_port)
	if result == OK:
		print("Connected to server.")
	else:
		print("Failed to connect to server:", result)
		return
	player = get_node("/root/Node3D/Player")
	player.player_state_changed.connect(send_state)
	player.player_shot.connect(send_player_hit)
	udp_peer.put_packet("L;Atharv".to_utf8_buffer())

func send_state(data: Array):
	var coordinates = data[0]
	var rotation = data[1]
	# Convert coordinates to byte array
	var state_str: String = "S;" + str(coordinates.x).pad_decimals(3) + "," +str(coordinates.y).pad_decimals(3) + "," + str(coordinates.z).pad_decimals(3)
	state_str = state_str + ":" + str(rotation).pad_decimals(3)
	state_str = state_str + ":" + str(Time.get_unix_time_from_system()*1000).pad_decimals(0)
	# Send the data
	var _result = udp_peer.put_packet(state_str.to_utf8_buffer())
	if _result != OK:
		print("Error sending data:", _result)
		
func send_player_hit(hit_player_id: int):
	var hit_str = "H;" + str(hit_player_id) +":"+ str(self_id) + ":" + str(Time.get_unix_time_from_system()*1000).pad_decimals(0)
	var _result = udp_peer.put_packet(hit_str.to_utf8_buffer())
	if _result != OK:
		print("Error sending data:", _result)

func _process(_delta):
	while udp_peer.get_available_packet_count() > 0:
		var data = udp_peer.get_packet()
		var message = data.get_string_from_utf8()
		var chunks = message.split(";")
		if chunks[0] == "S":
			update_pos(chunks.slice(1))
		elif chunks[0] == "N":
			create_new_player(chunks[1])
		elif chunks[0] == "I":
			initialize_player(chunks.slice(1))
		elif chunks[0] == "D":
			remove_player(chunks[1])
		elif chunks[0] == "R":
			player.reset(chunks[1])
		else:
			print("Received unknown message: ", message)
					
					
func initialize_player(data: Array):
	var self_state = data[0].split(":")
	self_id = int(self_state[0])
	player.update_position(self_state[1])
	
	for i in range(1, len(data)):
		create_new_player(data[i])

func create_new_player(data: String):
	var other_player_state = data.split(":")
	var client_id = int(other_player_state[0])
	var other_player_node = other_player.instantiate()
	get_node(".").add_sibling(other_player_node)
	other_players_dict[client_id] = other_player_node
	other_player_node.set_player_id(client_id)
	other_player_node.update_state(other_player_state.slice(1))


func remove_player(data: String):
	var client_id = int(data)
	var other_player_node: Node = other_players_dict[client_id]
	get_node("/root/Node3D").remove_child(other_player_node)
	other_players_dict.erase(client_id)

func update_pos(data: Array):
	for chunk in data:
		var player_state = chunk.split(":")
		var client_id = int(player_state[0])
			
		if other_players_dict.has(client_id):
			var player_node = other_players_dict[client_id]
			player_node.update_state(player_state.slice(1))
		elif client_id == self_id:
			player.update_health(int(player_state[3]))	
	
