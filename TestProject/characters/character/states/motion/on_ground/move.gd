extends "on_ground.gd"

export(float) var MAX_WALK_SPEED = 450
export(float) var MAX_RUN_SPEED = 700

func enter(host):
	speed = 0.0
	velocity = Vector2()

	var input_direction = get_input_direction()
	update_look_direction(host, input_direction)
#	host.get_node("AnimationPlayer").play("walk")


func handle_input(host, event):
	return .handle_input(host, event)


func update(host, delta):
	var input_direction = get_input_direction()
	if not input_direction:
		emit_signal("finished", "idle")
	update_look_direction(host, input_direction)

	speed = MAX_RUN_SPEED if Input.is_action_pressed("run") else MAX_WALK_SPEED
	var collision_info = move(host, speed, input_direction)
	if not collision_info:
		return
	if speed == MAX_RUN_SPEED and collision_info.collider.is_in_group("environment"):
		return null


func move(host, speed, direction):
	velocity = direction.normalized() * speed
	host.move_and_slide(velocity)
#	host.move_and_slide(velocity, Vector2(), 5, 2)
	if host.get_slide_count() == 0:
		return
	return host.get_slide_collision(0)
