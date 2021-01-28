class_name Tile
extends Resource

export(int) var id
export(String) var pretty_name

export(Resource) var blueprint_placement
export(Resource) var ship_placement

# Default rotation is assumed to be UP.
export(bool) var rotatable = true
export(String, "BACKGROUND", "INSIDE", "OUTSIDE", "FLEX") var type = "BACKGROUND"
export(Array, int, "UP", "RIGHT", "DOWN", "LEFT") var prohibited_rots = []
export(String, "ANY", "BEHIND") var mount_type = "ANY"
