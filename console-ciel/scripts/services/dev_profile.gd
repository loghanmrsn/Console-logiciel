extends RefCounted
## Explicit local preset, constructed from the shipped rules and fully validated.
## It never writes profiles, selects a player or changes the reward services.

static func build() -> Dictionary:
	var loaded := RewardService.load_rules()
	if not loaded.ok: return loaded
	var progress := SaveService.empty_investigation_progress()
	progress.started = true
	var points := 0
	for mission in RewardService.missions:
		progress.completed_missions.append(str(mission.id))
		progress.clues.append(str(mission.clue.id))
		for observation in mission.observations:
			progress.observations[mission.id].append(str(observation.id))
		if str(mission.id) == "computer":
			progress.checks.computer = mission.solution.checks.duplicate()
		points += int(mission.reward)
	progress.run_reward_points = points
	progress.hotel = {
		"version": SaveService.HOTEL_VERSION, "reserved": true,
		"repair_observations": SaveService.HOTEL_REPAIR_IDS.duplicate(),
		"repaired": true, "luggage_placed": true, "bed_state": "rested",
		"morning_stage": 6, "coffee_connections": SaveService.COFFEE_WIRES.duplicate()
	}
	progress["ctf"] = {"version": 1, "completed": SaveService.CtfCatalog.IDS.duplicate()}
	# Stage 6 keeps every earlier zone visitable; the CTF bus remains available.
	var document := {
		"schema_version": SaveService.SCHEMA_VERSION,
		"id": SaveService.DEV_PROFILE_ID, "display_name": SaveService.DEV_PROFILE_NAME,
		"role": "super_admin", "wallet": {"points": points + 50 * SaveService.HOTEL_REWARD_IDS.size() + 50 * SaveService.CtfCatalog.IDS.size()},
		"owned_items": SaveService.DEFAULT_ITEMS.duplicate(),
		"equipped": {"avatar": "avatar_default", "theme": "theme_brume", "frame": "frame_default"},
		"rewarded_missions": progress.completed_missions.duplicate() + SaveService.HOTEL_REWARD_IDS + SaveService.CtfCatalog.REWARD_IDS,
		"progress": progress
	}
	return SaveService.validate_profile(document)

static func restore_progress(document: Dictionary) -> Dictionary:
	var preset := build()
	if not preset.ok: return preset
	var restored := document.duplicate(true)
	restored.progress = preset.data.progress.duplicate(true)
	# Existing points, purchases, personal images and penalties stay untouched.
	for id in preset.data.rewarded_missions:
		if id not in restored.rewarded_missions: restored.rewarded_missions.append(id)
	return SaveService.validate_profile(restored)
