extends Node


func init(collider: CollisionShape2D, scale: Vector2, color: Color):
	$CollisionShape2D.position = collider.position
	$CollisionShape2D.shape = collider.shape
	$Sprite.scale = scale
	$Sprite.modulate = color
	return self
