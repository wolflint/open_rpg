extends Area2D

signal body_fell(body, pit_position, pit_distance)

const Player = preload("res://characters/player/player.gd")

var _overlapping_characters = {}

func _ready():
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
	if not body.is_in_group("character"):
		return

	set_process(true)
	_overlapping_characters[body.name] = body

func _process(delta):
	for character_name in _overlapping_characters:
		var character = _overlapping_characters[character_name]
		if character.state != Player.States.JUMP:
			_overlapping_characters.erase(character_name)

		emit_signal("body_fell", character, position, 2 * $CollisionShape2D.shape.extents)


func _on_body_exited(body):
	set_process(false)
	if body.name in _overlapping_characters:
		_overlapping_characters.erase(body.name)
