extends Area2D

signal attack_finished

var state = null

enum States {IDLE, ATTACK}

enum Attack_Input_States { IDLE, LISTENING, REGISTERED}
var attack_input_state = Attack_Input_States.IDLE
var ready_for_next_attack = false

const MAX_COMBO_COUNT = 3

var combo_count = 0
var attack_current = {}
var combo = [
	{
		'damage': 1,
		'animation': 'attack_fast'
	},
	{
		'damage': 1,
		'animation': 'attack_fast'
	},
	{
		'damage': 3,
		'animation': 'attack_medium'
	},
]


var hit_bodies = []

func _ready():
	self.connect("body_entered", self, "_on_body_entered")
	$AnimationPlayer.connect("animation_finished", self, "_on_AnimationPlayer_animation_finished")
	_change_state(States.IDLE)

func _change_state(new_state):
	match state:
		States.ATTACK:
			hit_bodies = []
			attack_input_state = Attack_Input_States.IDLE
			ready_for_next_attack = false
	match new_state:
		States.IDLE:
			combo_count = 0
			$AnimationPlayer.play("idle")
			monitoring = false
		States.ATTACK:
			attack_current = combo[combo_count - 1]
			print("attack_current " + attack_current)
			$AnimationPlayer.play(attack_current['animation'])
			monitoring = true
	state = new_state


func _input(event):
	if not state == States.ATTACK:
		return
	if attack_input_state != Attack_Input_States.LISTENING:
		return
	if event.is_action_pressed('attack'):
		attack_input_state = Attack_Input_States.REGISTERED


func _physics_process(delta):
	if attack_input_state == Attack_Input_States.REGISTERED and ready_for_next_attack:
		attack()

func attack():
	if combo_count >= MAX_COMBO_COUNT:
		return
	combo_count += 1
	_change_state(States.ATTACK)

func _on_body_entered(body):
	var body_id = body.get_rid().get_id()
	if body_id in hit_bodies or body.is_a_parent_of(self):
		return
	body.take_damage(self, attack_current['damage'])

func _on_AnimationPlayer_animation_finished(name):
	if name == "idle":
		return

	if attack_input_state == Attack_Input_States.REGISTERED:
#	if combo_count < MAX_COMBO_COUNT and attack_input_state == Attack_Input_States.REGISTERED:
		attack()
	else:
		_change_state(States.IDLE)
		emit_signal("attack_finished")


# Animation player function calls
func set_attack_input_listening():
	attack_input_state = Attack_Input_States.LISTENING
#	print("Listening")

func set_ready_for_next_attack():
	ready_for_next_attack = true
#	print("Ready")
