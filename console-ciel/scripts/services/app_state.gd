extends Node
## Session active : les documents sont copiés pour isoler les transactions.

signal profile_changed(profile: Dictionary)
signal wallet_changed(points: int)
signal equipment_changed(equipped: Dictionary)
signal objectives_changed(progress: Dictionary)

var profile: Dictionary = {}

func set_profile(value: Dictionary) -> void:
	profile = value.duplicate(true)
	_emit_changes()

func commit_profile(value: Dictionary) -> void:
	set_profile(value)

func clear_profile() -> void:
	set_profile({})

func _emit_changes() -> void:
	profile_changed.emit(profile.duplicate(true))
	wallet_changed.emit(int(profile.get("wallet", {}).get("points", 0)))
	equipment_changed.emit(profile.get("equipped", {}).duplicate(true))
	objectives_changed.emit(profile.get("progress", {}).duplicate(true))
