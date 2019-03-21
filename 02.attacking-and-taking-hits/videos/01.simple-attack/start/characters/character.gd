extends KinematicBody2D

signal state_changed
signal direction_changed

var input_direction = Vector2()
var look_direction = Vector2(1, 0)
var last_move_direction = Vector2(1, 0)

enum States { IDLE, ATTACK }
var state = null

#export(PackedScene) var weapon_scene
export(String) var weapon_path = ""
var weapon = null

func _ready():
	_change_state(States.IDLE)

	if not weapon_path:
		return
	var weapon_node = load(weapon_path).instance()

	$WeaponPivot/WeaponSpawn.add_child(weapon_node)
	weapon = $WeaponPivot/WeaponSpawn.get_child(0)
	weapon.connect("attack_finished", self, "on_Weapon_attack_finished")


func _change_state(new_state):
	match state:
		States.ATTACK:
			set_physics_process(true)

	# Initialize the new state
	match new_state:
		States.IDLE:
			$AnimationPlayer.play('idle')
		States.ATTACK:
			if not weapon:
				_change_state(States.IDLE)
				return

			weapon.attack()
			$AnimationPlayer.play("idle")
			set_physics_process(false)

	state = new_state
	emit_signal('state_changed', new_state)


func _physics_process(delta):
	if not input_direction:
		return

	last_move_direction = input_direction
	if input_direction.x in [-1, 1]:
		look_direction.x = input_direction.x
		$BodyPivot.set_scale(Vector2(look_direction.x, 1))


func on_Weapon_attack_finished():
	_change_state(States.IDLE)