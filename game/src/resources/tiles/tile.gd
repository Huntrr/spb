class_name Tile
extends Resource

export(int) var id
export(String) var pretty_name

export(Resource) var blueprint_placement
export(Resource) var ship_placement

# Default rotation is assumed to be UP.
export(bool) var rotatable = true
