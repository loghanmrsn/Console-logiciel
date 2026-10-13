extends VBoxContainer
## Each status describes an actual load stage. No timer or synthetic percentage.

func set_status(message: String) -> void:
	$Status.text=message
