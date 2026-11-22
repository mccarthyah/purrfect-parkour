extends Node

func _ready() -> void:
	_run_checks()

func _run_checks() -> void:
	var packed: PackedScene = load("res://scenes/game.tscn")
	if packed == null:
		_fail("Could not load the main game scene.")
		return
	var game: Variant = packed.instantiate()
	add_child(game)

	if game.state != "title":
		_fail("Game should begin on the title screen.")
		return
	if game.platforms.size() != 13:
		_fail("Expected 13 rooftop platforms, got %d." % game.platforms.size())
		return
	if game.medals.size() != 18 or game.total_medals != 18:
		_fail("All 18 fish medals should be present.")
		return

	game.start_game()
	if game.state != "playing":
		_fail("Start action did not begin the run.")
		return
	game.bounce_cat(game.cat)
	if game.cat.velocity.y >= 0:
		_fail("Spring pads should launch the cat upward.")
		return
	game.collect_medal(game.medals[0])
	if game.score != 1:
		_fail("Collecting a medal should increase the score.")
		return

	game.medals[0].taken = true
	game.medals[0].monitoring = false
	game.restart_game()
	if game.score != 0 or game.medals[0].taken or not game.medals[0].monitoring:
		_fail("Restart should reset the medal collection.")
		return
	print("Purrfect Parkour smoke test passed: 13 platforms, 18 medals, spring bounce, scoring, restart.")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("Purrfect Parkour smoke test failed: " + message)
	get_tree().quit(1)
