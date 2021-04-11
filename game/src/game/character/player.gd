extends KinematicBody2D

onready var Log := Logger.new(self)

const PositionMarker: PackedScene = (
	preload("res://scenes/character/position_marker.tscn"))

var _physics := PlayerPhysics.new()
var _input_history := InputHistory.new()

var _info: Dictionary
var _latest_input := {
	"up": false,
	"down": false,
	"left": false,
	"right": false,
	"roll": false,
	"aim": Vector2(0, 0)
}

var _peer_id: int
var _me: bool = false

onready var _character: Node = $Character
onready var _last_position: KinematicBody2D = PositionMarker.instance().init(
	$CollisionShape2D, Vector2(0.3, 0.3), Color.red)
onready var _predicted_position: KinematicBody2D = PositionMarker.instance().init(
	$CollisionShape2D, Vector2(0.1, 0.1), Color.blue)

func init(peer_id_: int, player_info_: Dictionary):
	name = "%d" % peer_id_
	_peer_id = peer_id_
	_info = player_info_
	return self

func set_mask(mask: Texture, cell_size: float) -> void:
	# Updates the spaceship mask used to hide parts of this player.
	_character.set_mask(mask, cell_size)

func _exit_tree():
	# Free the network position markers when this player is destroyed.
	_last_position.queue_free()
	_predicted_position.queue_free()

func _ready():
	_character.set_outfit(_info.outfit)
	
	if _peer_id == multiplayer.get_network_unique_id():
		_me = true
		$Camera2D.make_current()
		assert($Timer.connect("timeout", self, "_client_send_update") == OK)
	elif multiplayer.is_network_server():
		assert($Timer.connect("timeout", self, "_server_send_update") == OK)
	
	$"../../".add_node_to_group("players", self)
	
	$"../".add_child(_last_position)
	_last_position.position = position
	$"../".add_child(_predicted_position)
	_predicted_position.position = position

func _process(delta: float) -> void:
	# Perform an animation processing update for this player.
	var aim: Vector2 = _get_input().aim
	if aim.x < 0:
		_character.flip_h = false
	else:
		_character.flip_h = true
	
	if _physics.velocity.y == 0 && _physics.velocity.x == 0:
		_character.animate_idle()
	else:
		var forward := true
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

func _unhandled_key_input(event: InputEventKey) -> void:
	# Preempt an input state update if the player presses a key.
	if not _me:
		return
	if event.echo:
		return
	_client_send_update()
	_input_history.add_input(OS.get_system_time_msecs(), _get_input())

func _get_input() -> Dictionary:
	# Returns the "current" effective input state for this player.
	if _me:
		return {
			"up": Input.is_action_pressed("game_up"),
			"down": Input.is_action_pressed("game_down"),
			"left": Input.is_action_pressed("game_left"),
			"right": Input.is_action_pressed("game_right"),
			"roll": Input.is_action_pressed("game_roll"),
			"aim": get_local_mouse_position(),
		}
	else:
		return _latest_input

func _client_send_update() -> void:
	# Issue an input update to the server.
	rpc_unreliable("_server_set_input", _get_input())

func _server_send_update() -> void:
	# Issue a state update to all clients in this room.
	_last_position.position = position
	for peer in InNetworkState.get_room_peers(_peer_id):
		rpc_unreliable_id(peer, "_client_set_state",
			position, _physics.to_dict(), _latest_input)

master func _server_set_input(input: Dictionary) -> void:
	# Updates the last known input for this player on the server.
	if multiplayer.get_rpc_sender_id() != _peer_id:
		Log.error(
			"%s tried to act as %s" % [multiplayer.get_rpc_sender_id(), _peer_id])
		return
	if input == _latest_input:
		return
	
	_latest_input = input
	_server_send_update()

puppet func _client_set_state(
		position_: Vector2, physics_: Dictionary, input_: Dictionary) -> void:
	# Update character position on client using the last known state from the
	# server.
	var timestamp: float = (
		OS.get_system_time_msecs() - InNetworkState.get_server_latency())
	_latest_input = input_
	_input_history.add_input(timestamp, input_)
	_input_history.clear_before(timestamp)
	
	_last_position.position = position_
