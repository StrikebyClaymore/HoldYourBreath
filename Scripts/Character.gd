extends KinematicBody

onready var spot_tscn := preload("res://Scenes/Spot.tscn")

const MOVE_SPEED := 150.0
const MIN_DIST := 0.3
const MIN_TOILET_DIST := 0.1
const GRAVITY_SCALE := 100
const GRAVITY := 9.8 * GRAVITY_SCALE
const RAY_LENGTH := 100
const WAIT_TIME := Vector2(2, 4)
const WANT_TO_TOILET_TIME := Vector2(5, 10)
const SPOT_SIZE := Vector2(64, 160)
const MIN_SPOT_COUNT := 256
const MAX_SPOT_COUNT := 20000
const MAX_SPOT_SPAWN_TIME := 0.03
const SPOT_MODIFIER := 0.1
const MAX_ENDURANCE := 100
const MIN_EMPTY_OUT_TIME := 3
const IDLE := "idle"
const WALK := "walk"

export var spot_color_gradient : Gradient 

var camera :Camera
var animation :AnimationPlayer
var wait_timer :Timer
var want_to_toilet :Timer
var main_ui :Control
var spot_container :Control
var spot_spawn_area :Control
var shit_effect :CPUParticles
var spot_spawn_timer :Timer
var empty_out_timer :Timer
var game_level_menu :Control
var score :Label
var salute_1 :CPUParticles2D
var salute_2 :CPUParticles2D
var window :Control

var map_top_left_position :Vector3
var map_top_right_position :Vector3
var map_bottom_left_position :Vector3
var map_bottom_right_position :Vector3

var player_position := Vector3()
var toilet_position :Vector3
var destination := Vector3()
var move_translation := Vector3()
var endurance := 1
var multiplier := 0.0
var spots_count := 0
var spot_spawned_count := 0
var is_moving := false
var wait := false
var final :bool = false
var on_toilet :bool = false

func _ready():
	randomize()
	camera = get_parent().get_node("Camera")
	animation = get_node("AnimationPlayer")
	wait_timer = get_node("WaitTimer")
	want_to_toilet = get_node("WantToToilet")
	main_ui = get_parent().get_node("UI/Main")
	game_level_menu = get_parent().get_node("UI/GameLevel")
	spot_container = get_parent().get_node("UI/SpotContainer")
	spot_spawn_area = get_parent().get_node("UI/SpotSpwanArea")
	shit_effect = get_node("ShitEffect")
	spot_spawn_timer = get_node("SpotSpawnTimer")
	empty_out_timer = get_node("EmptyOutTimer")
	score = get_parent().get_node("UI/GameLevel/Score")
	salute_1 = get_parent().get_node("UI/GameLevel/Salute")
	salute_2 = get_parent().get_node("UI/GameLevel/Salute2")
	window = get_parent().get_node("UI/GameLevel/Window")
	toilet_position = get_parent().get_node("ToiletPosition").transform.origin
	set_map_positions()
	player_position = self.get_global_transform().origin
	destination = player_position
	wait_timer.start()
	want_to_toilet.start()
	pass

func _unhandled_input(event):
	if wait:
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		destination = cast_mouse_to_world(event)
		rotate_to_destination()
	pass

func _physics_process(delta):
	move_to_destination(destination, delta)
	pass

func move_to_destination(destination, delta) -> void:
	if on_toilet:
		return
		
	player_position = self.get_global_transform().origin
	
	if final and player_position.distance_to(toilet_position) <= MIN_TOILET_DIST:
		on_toilet_area_entered()
	
	var direction :Vector3 = (destination - player_position).normalized()
	move_translation = Vector3(direction.x * MOVE_SPEED, -GRAVITY, direction.z * MOVE_SPEED) * delta
	if not final and player_position.distance_to(destination) <= MIN_DIST:
		move_translation = Vector3(0, -GRAVITY * delta, 0)
	move_and_slide(move_translation, Vector3.UP)
	play_anim()

func rotate_to_destination() -> void:
	player_position = self.get_global_transform().origin
	if player_position.distance_to(destination) < MIN_DIST:
		return
	look_at(Vector3(destination.x, player_position.y, destination.z), Vector3.UP)

func cast_mouse_to_world(event) -> Vector3:
	var from := camera.project_ray_origin(event.position)
	var to := from + camera.project_ray_normal(event.position) * RAY_LENGTH
	var space_state := get_world().direct_space_state
	var result := space_state.intersect_ray(from, to, [self], collision_mask)
	return result.position

func play_anim() -> void:
	if player_position.distance_to(destination) > MIN_DIST:
		animation.play(WALK)
	else:
		animation.play(IDLE)

func generate_random_destination():
	var x := rand_range(map_top_left_position.x, map_top_right_position.x)
	var z := rand_range(map_top_left_position.z, map_bottom_right_position.z)
	destination = Vector3(x, player_position.y, z)
	rotate_to_destination()

func set_map_positions():
	map_top_left_position = get_parent().get_node("MapBorders/TopLeft").transform.origin
	map_top_right_position = get_parent().get_node("MapBorders/TopRight").transform.origin
	map_bottom_left_position = get_parent().get_node("MapBorders/BottomLeft").transform.origin
	map_bottom_right_position = get_parent().get_node("MapBorders/BottomRight").transform.origin

func go_to_toilet():
	final = true
	destination = toilet_position
	rotate_to_destination()
	pass

func on_toilet_area_entered():
	on_toilet = true
	look_at(Vector3(camera.transform.origin.x, player_position.y, camera.transform.origin.z), Vector3.UP)
	animation.play(IDLE)
	empty_out()
	pass

func empty_out():
	if endurance == 100:
		_on_EmptyOutTimer_timeout()
		return
	multiplier = (MAX_ENDURANCE - endurance) * SPOT_MODIFIER + 1
	spots_count = max(MIN_SPOT_COUNT, MIN_SPOT_COUNT * multiplier)
	spot_spawned_count = 0
	var spot_spawn_time = min(MAX_SPOT_SPAWN_TIME, MAX_SPOT_SPAWN_TIME / multiplier)
	empty_out_timer.wait_time = max(MIN_EMPTY_OUT_TIME, multiplier)
	shit_effect.amount = spots_count
	empty_out_timer.start()
	shit_effect.set_emitting(true)
	spot_spawn_timer.wait_time = spot_spawn_time
	spot_spawn_timer.start()

func _on_WaitTimer_timeout():
	wait_timer.wait_time = rand_range(WAIT_TIME.x, WAIT_TIME.y)
	generate_random_destination()
	wait_timer.start()
	pass

func _on_WantToToilet_timeout():
	wait = true
	wait_timer.stop()
	destination = player_position
	play_anim()
	main_ui.visible = true;
	pass

func _on_EmptyOut_pressed():
	main_ui.visible = false;
	go_to_toilet()
	wait = false
	pass

func _on_Endure_pressed():
	endurance -= 1
	
	if endurance == 0:
		_on_EmptyOut_pressed()
		return
	
	main_ui.visible = false;
	wait_timer.start()
	want_to_toilet.wait_time = rand_range(WANT_TO_TOILET_TIME.x, WANT_TO_TOILET_TIME.y)
	want_to_toilet.start()
	wait = false
	generate_random_destination()
	pass

func _on_SpotSpawnTimer_timeout():
	for i in int(multiplier):
		var spot = spot_tscn.instance()
		var positon := Vector2(
			rand_range(spot_spawn_area.rect_position.x, spot_spawn_area.rect_size.x), 
			rand_range(spot_spawn_area.rect_position.y, spot_spawn_area.rect_size.y)) 
		var size :Vector2 = Vector2(
			rand_range(SPOT_SIZE.x, SPOT_SIZE.y),
			rand_range(SPOT_SIZE.x, SPOT_SIZE.y))
			
		#bad practice, because theoretically the random can be infinite
		if window.get_rect().has_point(positon + size / 2):
			return
			
		var index :int = rand_range(0, spot_color_gradient.colors.size() - 1)
		var color = spot_color_gradient.get_color(index)
		spot_container.add_child(spot)
		spot.rect_position = positon
		spot.rect_size = size
		spot.rect_pivot_offset = size / 2
		spot.rect_rotation = rand_range(0, 360)
		spot.modulate = color
		spot_spawned_count += 1
	if spot_spawned_count >= spots_count:
		spot_spawn_timer.stop()
		empty_out_timer.stop()
		shit_effect.set_emitting(false)
		_on_EmptyOutTimer_timeout()
	pass

func _on_EmptyOutTimer_timeout():
	game_level_menu.visible = true
	score.text = score.text.replace("{}", str(endurance))
	if endurance == 0:
		score.text = score.text.insert(0, "Congratulations!!! ")
		salute_1.set_emitting(true)
		salute_2.set_emitting(true)
	pass

func _on_Restart_pressed():
	get_tree().reload_current_scene()
	pass 


