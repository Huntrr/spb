extends KinematicBody2D

onready var Log := Logger.new(self)
const PositionMarker: PackedScene = (
	preload("res://scenes/character/position_marker.tscn"))

# Controls prediction interpolation.
const _INTERPOLATE_AMOUNT := 0.1

var _physics := PlayerPhysics.new()
var _input_history := InputHistory.new()
var _latest_input := InputHistory.EMPTY_INPUT.duplicate(true)
var _latest_input_generation := 0

var _sitting := false
var _last_aim := Vector2.ZERO

var info: Dictionary

var peer_id: int
var _me: bool = false

onready var _character: Node = $Character
onready var _last_position: KinematicBody2D = PositionMarker.instance().init(
	$CollisionShape2D, Vector2(0.3, 0.3), Color.red)
onready var _predicted_position: KinematicBody2D = PositionMarker.instance().init(
	$CollisionShape2D, Vector2(0.1, 0.1), Color.blue)
var _predicted_physics := PlayerPhysics.new()
var _last_network_ts := 0

func init(peer_id_: int, player_info_: Dictionary):
	name = "%d" % peer_id_
	peer_id = peer_id_
	info = player_info_
	return self

func set_mask(mask: Texture, cell_size: float) -> void:
	# Updates the spaceship mask used to hide parts of this player.
	_character.set_mask(mask, cell_size)

func is_current_player() -> bool:
	# Returns true if this player is the current client's character.
	return _me

func sit() -> void:
	_sitting = true

func stand() -> void:
	_sitting = false

func _exit_tree():
	# Free the network position markers when this player is destroyed.
	_last_position.queue_free()
	_predicted_position.queue_free()

func _ready():
	_character.set_outfit(info.outfit)
	
	if peer_id == multiplayer.get_network_unique_id():
		_me = true
		$Camera2D.make_current()
		assert($Timer.connect("timeout", self, "_client_send_update") == OK)
	elif multiplayer.is_network_server():
		assert($Timer.connect("timeout", self, "_server_send_update") == OK)
	
	$"../../".add_node_to_group("players", self)
	
	$"../../".add_child(_last_position)
	_last_position.position = position
	$"../../".add_child(_predicted_position)
	_predicted_position.position = position

func _process(_delta: float) -> void:
	# Perform an animation processing update for this player.
	var aim: Vector2 = _get_input().aim
	var sitting: bool = _get_input().sitting
	_character.flip_h = aim.x > 0
	
	if _physics.velocity.y == 0 && _physics.velocity.x == 0:
		if sitting:
			_character.animate_sitting()
		else:
			_character.animate_idle()
	elif _physics.roll != Vector2.ZERO:
		_character.animate_roll()
		_character.flip_h = _physics.roll.x > 0
	else:
		if _character.flip_h and _physics.velocity.x < 0:
			_character.animate_walking(false)
		elif not _character.flip_h and _physics.velocity.x > 0:
			_character.animate_walking(false)
		else:
			_character.animate_walking(true)
	
	_character.set_mask_offset(position)

func _physics_process(delta: float) -> void:
	# Perform a physics processing update for this player.
	var input: Dictionary = _get_input()
	move_and_collide(_physics.get_movement(delta, input))
	_predicted_position.move_and_collide(
		_predicted_physics.get_movement(delta, input))
	
	if _predicted_physics.roll:
		_predicted_position.set_color(Color.fuchsia)
	else:
		_predicted_position.set_color(Color.blue)
	
	position = position.linear_interpolate(
		_predicted_position.position, _INTERPOLATE_AMOUNT)
	

func _unhandled_key_input(event: InputEventKey) -> void:
	# Preempt an input state update if the player presses a key.
	if not _me:
		return
	if event.echo:
		return
	_client_send_update()

func _get_input() -> Dictionary:
	# Returns the "current" effective input state for this player.
	if _me:
		var roll: bool = Input.is_action_pressed("game_roll")
		var roll_dir := _physics.velocity.normalized() if roll else Vector2.ZERO
		if not _sitting:
			_last_aim = get_local_mouse_position()
		return {
			"up": Input.is_action_pressed("game_up"),
			"down": Input.is_action_pressed("game_down"),
			"left": Input.is_action_pressed("game_left"),
			"right": Input.is_action_pressed("game_right"),
			"roll": roll,
			"roll_dir": roll_dir,
			"aim": _last_aim,
			"sitting": _sitting,
		}
	else:
		return _latest_input

func _client_send_update() -> void:
	# Issue an input update to the server.
	var now := OS.get_system_time_msecs()
	_input_history.add_input(now, _get_input())
	rpc_unreliable("_server_set_input", now, _get_input())

func _server_send_update() -> void:
	# Issue a state update to all clients in this room.
	_last_position.position = position
	for peer in InNetworkState.get_room_peers(peer_id):
		rpc_unreliable_id(peer, "_client_set_state",
			position, _physics.to_dict(), _latest_input)

master func _server_set_input(generation: int, input: Dictionary) -> void:
	# Updates the last known input for this player on the server.
	# |generation| is a monotonic increasing counter over inputs.
	if multiplayer.get_rpc_sender_id() != peer_id:
		Log.error(
			"%s tried to act as %s" % [multiplayer.get_rpc_sender_id(), peer_id])
		return
	if input == _latest_input:
		return
	if generation < _latest_input_generation:
		return
	_latest_input_generation = generation
	
	_latest_input = input
	_server_send_update()

puppet func _client_set_state(
		position_: Vector2, physics_: Dictionary, input_: Dictionary) -> void:
	# Update character position on client using the last known state from the
	# server.
	var now: int = OS.get_system_time_msecs()
	var timestamp: int = now - int(InNetworkState.get_server_latency()) * 2
	if timestamp < _last_network_ts:
		return
	_last_network_ts = timestamp
	
	_latest_input = input_
	
	_input_history.clear_before(timestamp)
	
	# Replay old inputs on top of new networked position...
	var new_physics = PlayerPhysics.new().from_dict(physics_)
	_last_position.position = position_
	var prev_position: Vector2 = _predicted_position.position
	_predicted_position.position = position_
	var delta: float = get_physics_process_delta_time()
	timestamp = max(timestamp, _input_history.get_min_timestamp())
	while timestamp < now:
		timestamp += int(delta * 1000.0)
		var input: Dictionary = _input_history.get_input(timestamp)
		var move_vector: Vector2 = new_physics.get_movement(delta, input)
		_predicted_position.move_and_collide(move_vector)
	_predicted_physics = new_physics
