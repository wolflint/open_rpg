extends Position2D

func _ready():
	$'..'.connect("direction_changed", self, "on_Parent_direction_changed")

func on_Parent_direction_changed(direction):
	rotation = direction.angle()