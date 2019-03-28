extends KinematicBody2D

signal state_changed
signal direction_changed(new_direction)
var look_direction = Vector2(1,0) setget set_look_direction

# state stack/history array
var states_stack = []
var current_state = null

onready var states_map = {
	"idle": $States/Idle,
	"move": $States/Move,
	"jump": $States/Jump,
}

func _ready():
	for state_node in $States.get_children():
		state_node.connect("finished", self, "_change_state")
	
	# on ready, change state to idle
	states_stack.push_front($States/Idle)
	current_state = states_stack[0]
	_change_state("idle")

func _physics_process(delta):
	current_state.update(self, delta)

func _input(event):
#	if event.is_action_pressed("attack_ranged"):
#		$BulletSpawn.fire(look_direction)
#		return
#	elif event.is_action_pressed("attack_melee"):
#		if current_state == $States/Attack:
#			return
#		_change_state("attack")
#		return
	current_state.handle_input(self, event)

func _on_animation_finished(anim_name):
	# delegate animation signal to current state
	current_state._on_animation_finished(anim_name)

func _change_state(state_name):
	current_state.exit(self)
	
	if state_name == "previous":
		states_stack.pop_front()
	elif state_name in ["jump"]:
		states_stack.push_front(states_map[state_name])
	elif state_name == "dead":
		queue_free()
		return
	else:
		var new_state = states_map[state_name]
		states_stack[0] = new_state
	
	if state_name == "attack":
		$WeaponPivot/Offset/Sword.attack()
	if state_name == "jump":
		$States/Jump.initialize(current_state.speed, current_state.velocity)
	
	current_state = states_stack[0]
	if state_name != "previous":
		# do not reinitialize state if going back to the previous state
		current_state.enter(self)
	emit_signal("state_changed", states_stack)

func take_damage(attacker, amount, effect=null):
	if self.is_a_parent_of(attacker):
		return
	$States/Stagger.knockback_direction = (attacker.global_position - global_position).normalized()
	$Health.take_damage(amount, effect)

func set_dead(value):
	set_process_input(not value)
	set_physics_process(not value)
	$CollisionShape2D.disabled = value

func set_look_direction(value):
	look_direction = value
	emit_signal("direction_changed", value)