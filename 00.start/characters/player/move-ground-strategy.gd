static func go(direction, speed, velocity=Vector2()):
	return {
		velocity = direction * speed,
		speed = speed
	}