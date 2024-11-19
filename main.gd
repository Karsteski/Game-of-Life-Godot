extends Node2D

const CELL_SIZE := 10
var cells_to_draw = []
var is_game_paused = false
var living_cells = 0

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
					new_cells[x][y] = true
			else: # Cell is dead
				if num_alive_neighbours == 3:
					# Cells reproduce to create a living cell
					living_cells += 1
					new_cells[x][y] = true

	return new_cells

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
		queue_redraw()

	# Toggle the pausing of the game
	if Input.is_action_just_pressed("pause_game") and not is_game_paused:
		is_game_paused = true
	elif Input.is_action_just_pressed("pause_game") and is_game_paused:
		is_game_paused = false

	if Input.is_action_just_pressed("hide_window") and $InfoRect.visible == true:
		$InfoRect.visible = false
	elif Input.is_action_just_pressed("hide_window") and $InfoRect.visible == false:
		$InfoRect.visible = true

	if Input.is_action_just_pressed("restart_game"):
		var dimensions = get_viewport_rect()
		var num_x = dimensions.size.x / CELL_SIZE
		var num_y = dimensions.size.y / CELL_SIZE
		cells_to_draw = generate_cells(num_x, num_y)

	# The label used to show data to the player
	var info_text = """FPS = %d
	Living Cells = %d

	Spacebar to pause
	R to restart
	H to hide this window
	"""
	$InfoRect/GameInfo.text = info_text % [Performance.get_monitor((Performance.TIME_FPS)),
		living_cells]

	# Get rid of annoying warning about unused variable
	var _delta = delta

func _draw():
	for x in range(cells_to_draw.size()):
		for y in range(cells_to_draw[x].size()):
			draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE,
				CELL_SIZE, CELL_SIZE),
				Color.WHITE if cells_to_draw[x][y] else Color.BLACK)
