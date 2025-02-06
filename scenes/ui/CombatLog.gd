extends Panel

@onready var log_container = $ScrollContainer/VBoxContainer

func add_message(text: String, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.modulate = color
	log_container.add_child(label)
	
	# Keep only last 10 messages
	if log_container.get_child_count() > 10:
		log_container.get_child(0).queue_free()
	
	# Scroll to bottom
	await get_tree().process_frame
	$ScrollContainer.scroll_vertical = $ScrollContainer.get_v_scroll_bar().max_value 