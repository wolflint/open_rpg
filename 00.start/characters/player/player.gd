extends "res://characters/character.gd"

signal speed_changed(speed, max_speed)

const MoveGroundStrategy = preload("res://characters/player/move-ground-strategy.gd")
const MoveAirStrategy = preload("res://characters/player/move-air-strategy.gd")

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

const FALL_DURATION = 0.4
const BUMP_DISTANCE = 50
const JUMP_DURATION = {
	States.BUMP: 0.2,
	States.JUMP: 0.6,
}

const JUMP_HEIGHT = {
	States.IDLE: 50,
	States.WALK: 50,
	States.RUN: 80,
}

const MOVE_STRATEGY = {
	States.WALK: MoveGroundStrategy,
	States.RUN: MoveGroundStrategy,
	States.JUMP: MoveAirStrategy,
}

var _speed = 0 setget _set_speed
var _max_speed = 0
var _velocity = Vector2()

var _jump_duration = JUMP_DURATION[States.JUMP]
var _jump_height = JUMP_HEIGHT[States.IDLE]

var _collision_normal = Vector2()

var _pit_position = Vector2()
var _pit_distance = Vector2()

var _last_input_direction = Vector2()

func _init() -> void:
	_transitions = {
		[States.IDLE, Events.WALK]: States.WALK,
		[States.IDLE, Events.RUN]: States.RUN,
		[States.IDLE, Events.JUMP]: States.JUMP,
		[States.IDLE, Events.FALL]: States.FALL,
		[States.WALK, Events.STOP]: States.IDLE,
		[States.WALK, Events.RUN]: States.RUN,
		[States.WALK, Events.JUMP]: States.JUMP,
		[States.WALK, Events.FALL]: States.FALL,
		[States.RUN, Events.STOP]: States.IDLE,
		[States.RUN, Events.WALK]: States.WALK,
		[States.RUN, Events.JUMP]: States.JUMP,
		[States.RUN, Events.FALL]: States.FALL,
		[States.RUN, Events.BUMP]: States.BUMP,
		[States.BUMP, Events.IDLE]: States.IDLE,
		[States.JUMP, Events.IDLE]: States.IDLE,
		[States.FALL, Events.RESPAWN]: States.RESPAWN,
		[States.RESPAWN, Events.IDLE]: States.IDLE,
	}

func _ready() -> void:
	connect("speed_changed", $DirectionVisualizer, "_on_Move_speed_changed")
	$Tween.connect("tween_completed", self, "_on_Tween_tween_completed")
	#$DirectionVisualizer.setup(self)

func _physics_process(delta):
	var slide_count = get_slide_count()
	_collision_normal = get_slide_collision(slide_count - 1).normal if slide_count > 0 else _collision_normal
	
	var input = get_raw_input(state, slide_count)
	var event = decode_raw_iput(input)
	change_state(event)

	match state:
		States.WALK, States.RUN, States.JUMP:
			_last_input_direction = input.direction if input.direction != Vector2() else _last_input_direction
			var params = MOVE_STRATEGY[state].go(input.direction, _speed, _max_speed, _velocity, delta)
			self._speed = params.speed
			_velocity = params.velocity
			_move()

func _set_speed(value):
	if _speed == value:
		return
	_speed = value
	emit_signal("speed_changed", _speed, SPEED[States.RUN])

func _move():
	move_and_slide(_velocity)
	
	var viewport_size = get_viewport().size
	for i in range(2):
		if position[i] < 0:
			position[i] = viewport_size[i]
		if position[i] > viewport_size[i]:
			position[i] = 0

func _animate_jump(progress):
	var pivot_height = _jump_height * pow(sin(progress * PI), 0.7) # Calculating the sine of jump animation
	var shadow_scale = 1.0 - pivot_height / _jump_height * 0.5 # Calculating the shadow scale
	$Pivot.position.y = -pivot_height
	$Shadow.scale = Vector2(shadow_scale, shadow_scale)

func enter_state():
	match state:
		States.IDLE, States.JUMP, States.BUMP:
			$AnimationPlayer.play("BASE")
			continue
		
		States.IDLE:
			_velocity = Vector2()
			_max_speed = SPEED[States.WALK]
			_jump_height = JUMP_HEIGHT[state]
			self._speed = 0

		States.WALK, States.RUN:
			_max_speed = SPEED[state]
			_jump_height = JUMP_HEIGHT[state]
			self._speed = _max_speed
			
			$AnimationPlayer.play("move")
		
		States.JUMP, States.BUMP:
			_jump_duration = JUMP_DURATION[state]
		
			if state == States.BUMP:
				$Tween.interpolate_property(
				self,
				"position", 
				position, 
				position + BUMP_DISTANCE * _collision_normal, 
				_jump_duration, 
				Tween.TRANS_LINEAR, 
				Tween.EASE_IN)
			$Tween.interpolate_method(
			self, 
			"_animate_jump", 
			0,
			1, 
			_jump_duration, 
			Tween.TRANS_LINEAR, 
			Tween.EASE_IN)
			$Tween.start()
		
		States.FALL:
			$Tween.interpolate_property(
				self, 
				"scale", 
				scale, 
				Vector2(), 
				FALL_DURATION/2.0,
				Tween.TRANS_QUAD,
				Tween.EASE_IN)
			$Tween.start()
		
		States.RESPAWN:
			position = _pit_position + _last_input_direction.rotated(PI) * _pit_distance #Change position and rotate 180 degrees
			$Tween.interpolate_property(
				self, 
				"scale", 
				scale, 
				Vector2(1, 1), 
				FALL_DURATION/2.0,
				Tween.TRANS_LINEAR,
				Tween.EASE_IN)
			$Tween.start()

static func get_raw_input(state, slide_count):
	return {
		direction = utils.get_input_direction(),
		is_running = Input.is_action_pressed("run"),
		is_jumping = Input.is_action_pressed("jump"),
		is_bumping = state == States.RUN and slide_count > 0 # Detects walls by checking the slide_count from move_and_slide
	}

static func decode_raw_iput(input):
	var event = Events.INVALID

	if input.direction == Vector2():
		event = Events.STOP
	elif input.is_running:
		event = Events.RUN
	else:
		event = Events.WALK
	
	if input.is_jumping:
		event = Events.JUMP
	if input.is_bumping:
		event = Events.BUMP

	return event

func _on_Tween_tween_completed(object, key):
	if key == ":_animate_jump":
		change_state(Events.IDLE)
	if key == ":scale" and scale.round() == Vector2():
		change_state(Events.RESPAWN)
	if key == ":scale" and scale.round() == Vector2(1, 1):
		change_state(Events.IDLE)

func _on_Pit_body_fell(body, pit_position, pit_distance):
	if body != self: 
		return
	
	_pit_position = pit_position
	_pit_distance = pit_distance
	change_state(Events.FALL)