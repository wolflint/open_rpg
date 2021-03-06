extends Area2D

signal attack_finished

enum STATES { IDLE, ATTACK }
var state = null

var power = 2
var hit_objects = []


func _ready():
	self.connect("body_entered", self, "_on_body_entered")
	$AnimationPlayer.connect('animation_finished', self, "_on_animation_finished")
	_change_state(IDLE)


func _change_state(new_state):
	match state:
		ATTACK:
			hit_objects = []

	match new_state:
		IDLE:
			$AnimationPlayer.play('idle')
			monitoring = false
		ATTACK:
			$AnimationPlayer.play('attack_straight')
			monitoring = true
	state = new_state


func attack():
	_change_state(ATTACK)


func _on_body_entered(body):
	if body.get_rid().get_id() in hit_objects or body.is_a_parent_of(self):
		return
	hit_objects.append(body.get_rid().get_id())
	body.take_damage(power)


func _on_animation_finished(name):
	if name == 'idle':
		return
	_change_state(IDLE)
	emit_signal("attack_finished")
