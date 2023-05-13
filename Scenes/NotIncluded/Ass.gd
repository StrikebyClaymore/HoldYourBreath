extends Spatial

"""
onready var shit_tscn = preload("res://Scenes/Shit.tscn")
export var emiting : bool = false
export var particles_max_count : int = 8
var particles_count : int = 0

func _ready():
	pass

func _process(delta):
	if emiting && particles_count < particles_max_count:
		spawn_shit()
	pass

func spawn_shit():
	var shit :RigidBody = shit_tscn.instance()
	get_parent().add_child(shit)
	shit.transform.origin = transform.origin
	particles_count += 1
	shit.add_force(Vector3.BACK * 700, transform.origin)
"""
