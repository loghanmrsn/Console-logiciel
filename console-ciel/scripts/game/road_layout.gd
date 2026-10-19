extends RefCounted
## One plan for asphalt, zebra markings, stop lines and pedestrian barriers.
const ROAD := Rect2(64, 580, 1672, 240)
const CROSSING := Rect2(800, 580, 200, 240)
const NORTH := Vector2(900, 480)
const SOUTH := Vector2(900, 910)
const SPEED := 85.0
const CAR_SIZE := Vector2(104, 54)
const LOOP_START := -120.0
const LOOP_END := 1920.0
const STOP_EAST := 728.0
const STOP_WEST := 1072.0

static func side(point: Vector2) -> int:
	if point.y < ROAD.position.y - 12: return -1
	if point.y > ROAD.end.y + 12: return 1
	return 0

static func start_for(side_id: int) -> Vector2:
	return NORTH if side_id < 0 else SOUTH

static func barriers() -> Array[Rect2]:
	return [Rect2(64, 552, 736, 14), Rect2(1000, 552, 736, 14), Rect2(64, 834, 736, 14), Rect2(1000, 834, 736, 14)]

static func gardens() -> Array[Rect2]:
	return [Rect2(190, 400, 330, 120), Rect2(1280, 400, 330, 120), Rect2(190, 880, 330, 120), Rect2(1280, 880, 330, 120)]

static func furniture() -> Array[Rect2]:
	# Signal bases, the bus sign and benches are solid; paint/shadows are not.
	var result: Array[Rect2] = []
	for spec in furniture_specs(): result.append(spec.rect)
	return result

static func furniture_specs() -> Array[Dictionary]:
	return [
		{"kind": "signal", "rect": Rect2(1058, 549, 24, 20)},
		{"kind": "signal", "rect": Rect2(726, 910, 24, 20)},
		{"kind": "bus", "rect": Rect2(1172, 883, 16, 21)},
		{"kind": "bench", "rect": Rect2(570, 447, 140, 38)},
		{"kind": "bench", "rect": Rect2(1080, 955, 140, 38)}]
