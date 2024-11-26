extends Control

var game_scene = preload("res://main.tscn")


func _on_startbutton_pressed():
	if (game_scene):
		var game_instance = game_scene.instantiate()

		# Let the game be on a tree branch of its own
		get_tree().get_root().add_child(game_instance)

		print("Game started")
	else:
		print("Game failed to load")

	var game_node = get_tree().get_root().get_node("Game")
	game_node.game_exited.connect(_on_game_game_exited)

	self.visible = false

func _on_exitbutton_pressed():
	print("Game exited")

	get_tree().quit()

func _on_game_game_exited():
	self.visible = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var start_button = $StartButton
	start_button.pressed.connect(_on_startbutton_pressed)
	
	var exit_button = $ExitButton
	exit_button.pressed.connect(_on_exitbutton_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	var _delta = delta # Squash unused variable warning
