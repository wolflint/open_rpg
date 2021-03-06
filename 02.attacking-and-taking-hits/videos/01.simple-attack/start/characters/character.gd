extends KinematicBody2D

signal state_changed
signal direction_changed

var input_direction = Vector2()
var look_direction = Vector2(1, 0)
var last_move_direction = Vector2(1, 0)

var knockback_direction = Vector2()
export (float) var knockback_force = 10.0
const KNOCKBACK_DURATION = 0.3

enum States { IDLE, ATTACK, STAGGER, DIE, DEATH }
var state = null

#export(PackedScene) var weapon_scene
export(String) var weapon_path = ""
var weapon = null

func _ready():
	_change_state(States.IDLE)
	$Health.connect("health_changed", self, "on_Health_health_changed")
	$AnimationPlayer.connect("animation_finished", self, "_on_AnimationPlayer_animation_finished")

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
		States.DIE:
			queue_free()

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
		States.STAGGER:
			$AnimationPlayer.play('stagger')

			$Tween.interpolate_property(self, 'position', position, position + knockback_force * knockback_direction, KNOCKBACK_DURATION, Tween.TRANS_QUART, Tween.EASE_OUT)
			$Tween.start()

		States.DIE:
			set_process_input(false)
			$CollisionShape2D.set_deferred("disabled", true)
			$AnimationPlayer.play("die")

	state = new_state
	emit_signal('state_changed', new_state)


func _physics_process(delta):
	if not input_direction:
		return

	last_move_direction = input_direction
	if input_direction.x in [-1, 1]:
		look_direction.x = input_direction.x
		$BodyPivot.set_scale(Vector2(look_direction.x, 1))

func take_damage(source, amount):
	if self.is_a_parent_of(source):
		return
	knockback_direction = (global_position - source.global_position).normalized()
	$Health.take_damage(amount)

func on_Weapon_attack_finished():
	_change_state(States.IDLE)

func on_Health_health_changed(new_health):
	if new_health == 0:
		_change_state(States.DIE)
	else:
		_change_state(States.STAGGER)

func _on_AnimationPlayer_animation_finished(name):
	if name == "die":
		_change_state(States.DEATH)