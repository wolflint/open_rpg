extends Area2D

signal attack_finished

var state = null

enum States {IDLE, ATTACK}

var power = 2

var hit_bodies = []

func _ready():
	self.connect("body_entered", self, "_on_body_entered")
	$AnimationPlayer.connect("animation_finished", self, "_on_AnimationPlayer_animation_finished")
	_change_state(States.IDLE)

func _change_state(new_state):
	match state:
		States.ATTACK:
			hit_bodies = []
	match new_state:
		States.IDLE:
			monitoring = false
			$AnimationPlayer.play("idle")
		States.ATTACK:
			monitoring = true
			$AnimationPlayer.play("attack_straight")
	state = new_state


func attack():
	_change_state(States.ATTACK)

func _on_body_entered(body):
	var body_id = body.get_rid().get_id()
	if body_id in hit_bodies:
		return
	body.take_damage(self, power)

func _on_AnimationPlayer_animation_finished(name):
	if name == "idle":
		return
	_change_state(States.IDLE)
	emit_signal("attack_finished")