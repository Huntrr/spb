extends Node

const _PAST_MEASUREMENT_WEIGHT := 0.3

var rtts := {}  # Round trip times by peer.
var room_to_rtt := {}  # Min RTT per room.

var peer_to_room := {}
var room_to_peers := {}

func get_room_peers(peer_id: int) -> Array:
	return room_to_peers[peer_to_room[peer_id]]

func get_latency(peer_id: int) -> float:
	if not peer_id in rtts:
		return -1.0
	return rtts[peer_id] / 2.0

func get_room_latency(peer_id: int) -> float:
	# Treat all peers in the same room as having the same latency...
	return room_to_rtt[peer_to_room[peer_id]] / 2.0

func get_server_latency() -> float:
	return get_latency(0)

func add_peer(peer_id: int, room_id: String) -> void:
	if peer_id in peer_to_room:
		remove_peer(peer_id)
	
	peer_to_room[peer_id] = room_id
	if not (room_id in room_to_peers):
		room_to_peers[room_id] = []
	
	room_to_peers[room_id].append(peer_id)

func remove_peer(peer_id: int) -> void:
	var room_id: String = peer_to_room[peer_id]
	peer_to_room.erase(peer_id)
	room_to_peers[room_id].erase(peer_id)

func add_rtt(peer_id: int, rtt: float) -> void:
	if not (peer_id in rtts):
		rtts[peer_id] = rtt
	
	# Moving average with the previous measurements.
	rtts[peer_id] = rtt + (rtts[peer_id] - rtt) * _PAST_MEASUREMENT_WEIGHT
	
	if peer_id == 0:
		# The server is in all rooms...
		return
	
	var room_id: String = peer_to_room[peer_id]
	if not (room_id in room_to_rtt):
		room_to_rtt[room_id] = rtts[peer_id]
	
	room_to_rtt[room_id] = min(room_to_rtt[room_id], rtts[peer_id])

func add_server_rtt(rtt: float) -> void:
	add_rtt(0, rtt)
