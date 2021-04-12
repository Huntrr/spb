extends Node

onready var Log := Logger.new(self)

const _PING_INTERVAL = 1.0

export(bool) var inside = true
var network_state: Node = InNetworkState if inside else OutNetworkState

var room_id := ""
var current_pings := {}
var ping_history := {0: 0}

func _ready() -> void:
	if multiplayer.is_network_server():
		var timer: Timer = Timer.new()
		timer.connect("timeout", self, "_send_ping")
		add_child(timer)
		timer.start(_PING_INTERVAL)

func _send_ping() -> void:
	if room_id.empty() or not (room_id in network_state.room_to_peers):
		Log.warning("Ping timeout before room_id is set.")
		return
	for peer_id in network_state.room_to_peers[room_id]:
		var ping_id: int = randi()
		if not (peer_id in current_pings):
			current_pings[peer_id] = {}
			ping_history[peer_id] = 0
		current_pings[peer_id][ping_id] = OS.get_system_time_msecs()
		rpc_unreliable_id(peer_id, "ping", ping_id)

puppet func ping(ping_id: int) -> void:
	current_pings[ping_id] = OS.get_system_time_msecs()
	rpc_unreliable("pong", ping_id)

master func pong(ping_id: int) -> void:
	var peer_id: int = multiplayer.get_rpc_sender_id()
	if not (peer_id in current_pings) or not (ping_id in current_pings[peer_id]):
		return
	var now: int = OS.get_system_time_msecs()
	var then: int = current_pings[peer_id][ping_id]
	if then < ping_history[peer_id]:
		Log.info("Got back old ping, ignoring")
	else:
		network_state.add_rtt(peer_id, now - then)
		ping_history[peer_id] = then
	current_pings[peer_id].erase(ping_id)
	rpc_unreliable_id(peer_id, "pingpong", ping_id)

puppet func pingpong(ping_id: int) -> void:
	var now: int = OS.get_system_time_msecs()
	var then: int = current_pings[ping_id]
	if then < ping_history[0]:
		Log.info("Got back old pingpong, ignoring")
	else:
		network_state.add_server_rtt(now - then)
		ping_history[0] = then
	current_pings.erase(ping_id)
