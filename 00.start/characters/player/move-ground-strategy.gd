static func go(direction, speed, max_speed=0, velocity=Vector2(), delta=0):
	return {
		velocity = direction * speed,
		speed = speed
	}