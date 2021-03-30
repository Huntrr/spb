extends Node
# Useful wrapper to make a separate branch in the scene tree with its own
# custom multiplayer object.
# Modified from https://github.com/LudiDorici/gd-custom-multiplayer

func _init():
	custom_multiplayer = MultiplayerAPI.new()
	# All path references will be relative to this wrapper
	custom_multiplayer.set_root_node(self)

# We want to listen to NOTIFICATION_ENTER_TREE to change the custom_multiplayer
# variable in all children as soon as we enter the tree.
# We don't this in the _ready() function because it will be called AFTER the
# _ready() function of the children is called, and they might register
# multiplayer related signals in it (more on this in _customize_children
# function)
func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		# We also want to customize all nodes that will be added dynamically
		# later on.
		assert(get_tree().connect("node_added", self, "_on_add_node") == OK)
		_customize_children()
	elif what == NOTIFICATION_EXIT_TREE:
		# Don't forget to disconnect
		get_tree().disconnect("node_added", self, "_on_add_node")

# When the MultiplayerAPI is not managed directly by the SceneTree
# we MUST poll it
func _process(_delta):
	if not custom_multiplayer.has_network_peer():
		return # No network peer, nothing to poll
	# Poll the MultiplayerAPI so it fetches packets, emit signals, process RPCs.
	custom_multiplayer.poll()

# Called every time a new node is added to the tree (dynamically added nodes).
func _on_add_node(node):
	# We want to make sure that the node is in our branch.
	var path = str(node.get_path())
	var mypath = str(get_path())
	if path.substr(0, mypath.length()) != mypath:
		return
	var rel = path.substr(mypath.length(), path.length())
	if rel.length() > 0 and not rel.begins_with("/"):
		# The added node is not in our branch (child or subchild).
		# Leave it alone
		return

	# The added node is our child, or child of our child,
	# or child of our child's child, and so on.
	# Let's apply to it our own custom multiplayer
	node.custom_multiplayer = custom_multiplayer

# This function customize all the child nodes added when the scene is instanced.
func _customize_children():
	# Remember to mind the stack ;-)
	# We use a frontier to avoid recursion.
	var frontier = []
	for c in get_children():
		frontier.append(c)
	while not frontier.empty():
		var node = frontier.pop_front()
		frontier += node.get_children()
		# Same as in _on_add_node we customize the MultiplayerAPI of our child.
		node.custom_multiplayer = custom_multiplayer

master func request_join_room(room_id: String) -> void:
	for child in get_children():
		if child.name == room_id:
			return
	
	var peer_id := multiplayer.get_rpc_sender_id()
	rpc_id(peer_id, "kick")
	multiplayer.network_peer.disconnect_peer(peer_id)

puppet func kick() -> void:
	push_error("Got kicked!")
	custom_multiplayer.network_peer = null
