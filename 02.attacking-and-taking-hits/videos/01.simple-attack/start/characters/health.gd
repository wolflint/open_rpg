extends Node

signal health_changed

var health = 0
export (int) var max_health = 5

var status = null
enum Statuses { NONE, INVINCIBLE}

func _ready():
	health = max_health
	_change_status(Statuses.NONE)

func _change_status(new_status):
	status = new_status

func take_damage(amount):
	if status == Statuses.INVINCIBLE:
		return
	health -= amount
	if health < 0:
		health = 0
	emit_signal("health_changed", health)
	print("%s took %s damage. Health: %s/%s" % [get_path(), amount, health, max_health])

func recover_health(amount):
	health += amount
	if health > max_health:
		health = max_health
	emit_signal("health_changed", health)
	print("%s recovered %s health. Health: %s/%s" % [get_path(), amount, health, max_health])