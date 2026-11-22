extends RefCounted

func run_checks(game) -> bool:
	if game.state != "title":
		return _fail("Game should begin on the title screen.")
	if game.platforms.size() != 13:
		return _fail("Expected 13 rooftop platforms, got %d." % game.platforms.size())
	if game.medals.size() != 18 or game.total_medals != 18:
		return _fail("All 18 fish medals should be present.")

	game.start_game()
	if game.state != "playing":
		return _fail("Start action did not begin the run.")
	game.bounce_cat(game.cat)
	if game.cat.velocity.y >= 0:
		return _fail("Spring pads should launch the cat upward.")
	game.collect_medal(game.medals[0])
	if game.score != 1:
		return _fail("Collecting a medal should increase the score.")

	game.medals[0].taken = true
	game.medals[0].monitoring = false
	game.restart_game()
	if game.score != 0 or game.medals[0].taken or not game.medals[0].monitoring:
		return _fail("Restart should reset the medal collection.")
	print("Purrfect Parkour smoke test passed: 13 platforms, 18 medals, spring bounce, scoring, restart.")
	return true

func _fail(message: String) -> bool:
	push_error("Purrfect Parkour smoke test failed: " + message)
	return false
