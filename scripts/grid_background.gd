extends Node2D

const TILE_SIZE := 64
const COLS := 60
const ROWS := 40
const COLOR_A := Color(0.20, 0.20, 0.20)
const COLOR_B := Color(0.26, 0.26, 0.26)

func _draw() -> void:
	for r in ROWS:
		for c in COLS:
			var color := COLOR_A if (r + c) % 2 == 0 else COLOR_B
			draw_rect(Rect2(c * TILE_SIZE, r * TILE_SIZE, TILE_SIZE, TILE_SIZE), color)
