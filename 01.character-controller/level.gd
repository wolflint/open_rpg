extends Node2D

func _ready():
	$Pit.connect("body_fell", $YSort/Player, "_on_Pit_body_fell")