extends "res://characters/character.gd"

signal speed_changed(speed, max_speed)


#### YOU ARE HERE - VIDEO 10 13:30 ####
const MoveGroundStrategy = 0

enum States {
	IDLE,
	WALK,
	RUN,
	BUMP,
	JUMP,
	FALL,
	RESPAWN
	}

enum Events {
	INVALID=-1,
	STOP,
	IDLE,
	WALK,
	RUN,
	BUMP,
	JUMP,
	FALL,
	RESPAWN
	}

const SPEED = {
	States.WALK: 450,
	States.RUN: 700,
	}

const MOVE_STRATEGY = {
	States.WALK: MoveGroundStrategy,
	States.RUN: MoveGroundStrategy
}

var _speed = 0 setget _set_speed
var _max_speed = 0
var _velocity = Vector2()
var _collision_normal = Vector2()
var _last_input_direction = Vector2()

func _init() -> void:
	_transitions = {
		[States.IDLE, Events.WALK]: States.WALK,
		[States.IDLE, Events.RUN]: States.RUN,
		[States.WALK, Events.STOP]: States.IDLE,
		[States.WALK, Events.RUN]: States.RUN,
		[States.RUN, Events.STOP]: States.IDLE,
		[States.RUN, Events.WALK]: States.WALK,
	}

func _ready() -> void:
	$DirectionVisualizer.setup(self)

func _physics_process(delta):
	var input = get_raw_input()
	var event = decode_raw_iput(input)
	change_state(event)

	match state:
		States.WALK, States.RUN:
			var params = MOVE_STRATEGY[state]

func enter_state():
	match state:
		States.IDLE:
			$AnimationPlayer.play("BASE")
			_velocity = Vector2()
			_max_speed = SPEED[States.WALK]
			self._speed = 0

		States.WALK, States.RUN:
			_max_speed = SPEED[state]
			self._speed = _max_speed
			$AnimationPlayer.play("move")

static func get_raw_input():
	return {
		direction = Utils.get_input_direction(),
		is_running = Input.is_action_pressed("run")
	}

static func decode_raw_iput(input):
	var event = Events.INVALID

	if input.direction == Vector2():
		event = Events.STOP
	elif input.is_running:
		event = Events.RUN
	else:
		event = Events.WALK

	return event

func _set_speed(value):
	if _speed == value:
		return
	_speed = value
	emit_signal("speed_changed", _speed, SPEED[States.RUN])
