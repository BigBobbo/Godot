extends Node

func _ready():
	var tests = GameTests.new()
	add_child(tests)
	
	# Wait a frame to ensure everything is set up
	await get_tree().process_frame
	
	# Run all tests
	tests.run_all_tests() 
