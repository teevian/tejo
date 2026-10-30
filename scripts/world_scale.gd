extends RefCounted
## Shared visual measurements: characters, furniture, foliage and pose anchors.
const PERSON_HEIGHTS: Array[float] = [156.0,153.0]
const PROP_HEIGHTS: Array[float] = [600.0,640.0,108.0,112.0,112.0,0.0]
const BENCH_WIDTH := 240.0
const BENCH_SEATS: Array[Vector2] = [Vector2(-52,22),Vector2(52,22)]
const BENCH_FOOTPRINT := Rect2(-106,-28,212,24)
const SHOULDER_OFFSET := Vector2(139,4)*(156.0/186.0)
const PICKUP_SIZES: Array[float] = [15.0,22.0,30.0]
const NEAR_BRANCH_SCALES: Array[float] = [0.52,0.64]
