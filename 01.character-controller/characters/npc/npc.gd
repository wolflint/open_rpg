extends "res://characters/character.gd"

enum States {IDLE, WALK}
enum Events {STOP, MOVE}

const STOP_THRESHOLD = 1e-2
const PATROL_DISTANCE = 200
const SPEED = 300

var _direction = Vector2(-1, 0)
var _target_position = Vector2()


func _init() -> void:
	_transitions ={
		[States.IDLE, Events.MOVE]: States.WALK,
		[States.WALK, Events.STOP]: States.IDLE,
	}



func _ready() -> void:
	$CollisionShape2D.disabled = true
	$Timer.connect("timeout", self, "change_state", [Events.MOVE])
	$Timer.wait_time = 0.5 + 1.5 * randf()
	$Timer.start()



func _physics_process(delta: float) -> void:
	match state:
		States.WALK:
			_walk()


func _walk():
	var velocity = _direction * SPEED
	move_and_slide(velocity)
	if (position - _target_position).length() < STOP_THRESHOLD:
		change_state(Events.STOP)


func enter_state():
	match state:
		States.IDLE:
			$Timer.start()
			$AnimationPlayer.play("BASE")
		
		States.WALK:
			_direction.x *= -1 # Invert the direction by multiplying it by -1
			_target_position = position + PATROL_DISTANCE * _direction
			$AnimationPlayer.play("move")












