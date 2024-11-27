extends Node2D

const CELL_SIZE := 16
var cells_to_draw = []
var is_game_paused = false
var living_cells = 0
var glider_pattern = [[true, false, false], [false, true, true], [true, true, false]]

signal game_exited

func _generate_blank_cells(num_x: int, num_y: int) -> Array:
	var cells = []

	for x in range(num_x):
		cells.append([])
		cells[x].resize(num_y)
		
		for y in range(num_y):
			cells[x][y] = false

	return cells


func generate_cells(num_x: int, num_y: int) -> Array:
	var cells = []

	for x in range(num_x):
		cells.append([])
		cells[x].resize(num_y)

		for y in range(num_y):
			# Randomly set cells to either alive or dead
			cells[x][y] = (randi() % 2) as bool

	return cells


func count_neighbour_cells(cell: Vector2i, cells: Array) -> int:
	var num_alive_neighbour_cells = 0

	# Check the cell's neighbours to determine its new state		
	for i in range(-1, 2):
		for j in range(-1, 2):
			# Don't check neighbour [0, 0] as that's the current cell
			if i == 0 and j == 0:
				continue

			var neighbour :Vector2i = Vector2i(cell.x + i, cell.y + j)
			# Efficient Bounds checking
			if 0 < neighbour.x and neighbour.x < cells.size() and \
				0 < neighbour.y and neighbour.y < cells[neighbour.x].size():
	
				# Finally, count neighbour cell if it's alive
				if cells[neighbour.x][neighbour.y] == true:
					num_alive_neighbour_cells += 1
	
	return num_alive_neighbour_cells


func next_iteration(current_cells: Array) -> Array:
	# Must reset living cell count
	living_cells = 0

	var new_cells = []
	new_cells.resize(current_cells.size())

	for x in current_cells.size():
		new_cells[x] = []
		new_cells[x].resize(current_cells[x].size())

		for y in current_cells[x].size():
			var num_alive_neighbours = count_neighbour_cells(Vector2i(x,y),
				current_cells)
			
			# Game of Life
			if current_cells[x][y]: # Cell is alive
				if num_alive_neighbours < 2 or 3 < num_alive_neighbours:
					# Cell dies
					new_cells[x][y] = false
				elif num_alive_neighbours == 2 or num_alive_neighbours == 3:
					# Cell is happy and remains alive
					living_cells += 1
					new_cells[x][y] = true
			else: # Cell is dead
				if num_alive_neighbours == 3:
					# Cells reproduce to create a living cell
					living_cells += 1
					new_cells[x][y] = true

	return new_cells


func rotateGridRight(grid: Array) -> Array:
	# Only attempt to rotate NxN matrices
	for x in grid.size():
		var N = grid.size()
		if grid[x].size() != N:
			return grid
	
	var size = grid.size()

	# Number of rotatable layers
	@warning_ignore("integer_division")
	var layer_count = size / 2

	# Deep copy so we don't affect the original array
	var rotatedGrid = grid.duplicate(true)

	# Layer loop i.e. i = 0, i = 1
	for layer in range(0, layer_count):
		var first = layer
		var last = size - first - 1

		# Movemement within a single layer, i.e. element loop
		for element in range(first, last):
			var offset = element - first

			# element increments column
			var top = rotatedGrid[first][element]
			# element increments row
			var right_side = rotatedGrid[element][last]
			# last - offset decrements column
			var bottom = rotatedGrid[last][last - offset]
			# last - offset decrements row
			var left_side = rotatedGrid[last - offset][first]

			rotatedGrid[first][element] = left_side
			rotatedGrid[element][last] = top
			rotatedGrid[last][last - offset] = right_side
			rotatedGrid[last - offset][first] = bottom

	return rotatedGrid


func insert_cells(cells_to_insert: Array, current_cells: Array, coords: Vector2i) -> bool:
	if coords.x > current_cells.size() or coords.y > current_cells[coords.x].size():
		return false

	for i in range(cells_to_insert.size()):
		for j in range(cells_to_insert[i].size()):
			# Bounds checking
			if coords.x + i > current_cells.size() or coords.y + j > current_cells[i].size():
				continue
			current_cells[coords.x + i][coords.y + j] = cells_to_insert[i][j]
		
	return true


func insert_pattern(pattern: Array, current_cells: Array, coords: Vector2i) -> void:
	insert_cells(pattern, current_cells, coords)


func draw_cells(cells: Array) -> void:
	const WHITE_TILE = Vector2i(7, 7)
	const BLACK_TILE = Vector2i(3, 3)
	const TILE_SOURCE = 1

	for x in range(cells.size()):
		for y in range(cells[x].size()):
			$TileMapLayer.set_cell(Vector2i(x,y), TILE_SOURCE, WHITE_TILE if cells[x][y] else BLACK_TILE)


func click_cell(click_position: Vector2) -> Vector2i:
	var coords = $TileMapLayer.local_to_map(click_position)
	return coords


# Called when there is an input event
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_cell_coords = click_cell(event.position)
			insert_pattern(glider_pattern, cells_to_draw, clicked_cell_coords)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			glider_pattern = rotateGridRight(glider_pattern)

	if event is InputEventKey:
		if event.is_action_pressed("pause_game"):
			if not is_game_paused:
				is_game_paused = true
			elif is_game_paused:
				is_game_paused = false
		elif event.is_action_pressed("hide_window"):
			if $InfoRect.visible:
				$InfoRect.visible = false
			else:
				$InfoRect.visible = true
		elif event.is_action_pressed("restart_game"):
			var dimensions = get_viewport_rect()
			var num_x = dimensions.size.x / CELL_SIZE
			var num_y = dimensions.size.y / CELL_SIZE
			cells_to_draw = generate_cells(num_x, num_y)
		elif event.is_action_pressed("ui_cancel"):
			game_exited.emit()
			queue_free()

# Called when the node enters the scene tree for the first time.
func _ready():
	var dimensions = get_viewport_rect()
	var num_x = dimensions.size.x / CELL_SIZE
	var num_y = dimensions.size.y / CELL_SIZE

	cells_to_draw = generate_cells(num_x, num_y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var new_cells = []

	if not is_game_paused:
		new_cells = next_iteration(cells_to_draw)
		cells_to_draw = new_cells

	# The label used to show data to the player
	var info_text = """FPS = %d
	Living Cells = %d

	Spacebar to pause
	R to restart
	H to hide this window
	Esc to return to menu
	Click to add glider
	Right click to rotate glider
	"""
	$InfoRect/GameInfo.text = info_text % [Performance.get_monitor((Performance.TIME_FPS)),
		living_cells]

	# Get rid of annoying warning about unused variable
	var _delta = delta

	draw_cells(cells_to_draw)
