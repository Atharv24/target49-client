extends VBoxContainer

func _ready():
	$Button.connect("pressed", _on_start_game_button_pressed)

func _on_start_game_button_pressed():
	var server_address = $serverAddressLineEdit.text
	var server_port = $portLineEdit.text.to_int()

	Serverinfo.server_address = server_address
	Serverinfo.server_port = server_port
	
	get_tree().change_scene_to_file("res://scene.tscn")
