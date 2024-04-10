extends Node3D

# Called when the player position signal is received fro9m the TCP client script
func update_position(data: String):
	var coors = data.split(",")
	
	var x = float(coors[0])
	var y = float(coors[1])
	var z = float(coors[2])
	
	var vec = Vector3(x,y,z)
	global_transform.origin = vec
