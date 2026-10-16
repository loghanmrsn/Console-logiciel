extends Node
## Séjour local : la réservation déclenche la panne, sans toucher à l’économie.
## Les changements sont validés et écrits avant tout changement de décor ou d’UI.

signal state_changed(hotel: Dictionary)

const REPAIR_OBSERVATIONS := {
	"power": {
		"title": "Alimentation électrique",
		"text": "Le serveur et l’onduleur sont alimentés. Aucun voyant d’alarme électrique."
	},
	"network": {
		"title": "Connexion réseau",
		"text": "Le câble est branché et le réseau répond. La connexion avec la réception fonctionne."
	},
	"storage": {
		"title": "Espace disque",
		"text": "Le disque est rempli à 100 %. Les anciens journaux occupent tout l’espace disponible."
	},
	"service": {
		"title": "Service de réservation",
		"text": "Le service est arrêté : impossible d’écrire de nouvelles données sur le disque plein."
	}
}
const ROUTES := {
	"building_02>hotel_it": "it_entrance",
	"hotel_it>building_02": "hall_it",
	"building_02>hotel_stairs_1": "stairs_from_hall",
	"hotel_stairs_1>building_02": "hall_stairs",
	"hotel_stairs_1>hotel_floor_2": "floor2_stairs",
	"hotel_floor_2>hotel_stairs_1": "stairs_from_floor2",
	"hotel_floor_2>hotel_room_206": "room206_entry",
	"hotel_room_206>hotel_floor_2": "floor2_room206"
}

func state() -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService.empty_hotel_progress()
	var hotel: Variant = AppState.profile.get("progress", {}).get("hotel")
	return hotel.duplicate(true) if hotel is Dictionary else SaveService.empty_hotel_progress()

func is_hotel_zone(room_id: String = "") -> bool:
	var selected := room_id
	if selected.is_empty() and not AppState.profile.is_empty():
		selected = str(AppState.profile.get("progress", {}).get("room_id", ""))
	return selected in SaveService.HOTEL_ROOMS

func _ready_for(rooms: Array) -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var valid := SaveService.validate_profile(AppState.profile)
	if not valid.ok:
		return valid
	if valid.get("migration_required", false):
		return SaveService._fail("Sélectionnez ce profil pour enregistrer sa migration avant de poursuivre le séjour.")
	var progress: Dictionary = AppState.profile.progress
	if not progress.started or "maze" not in progress.completed_missions:
		return SaveService._fail("Terminez le chapitre 5 puis rejoignez l’hôtel d’en face.")
	if progress.room_id not in rooms:
		return SaveService._fail("Rejoignez la salle concernée pour effectuer cette action.")
	return SaveService._ok()

func _save_progress(progress: Dictionary) -> Dictionary:
	var document: Dictionary = AppState.profile.duplicate(true)
	document.progress = progress.duplicate(true)
	var saved := SaveService.write_profile(document)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	var hotel: Dictionary = saved.data.progress.hotel.duplicate(true)
	state_changed.emit(hotel.duplicate(true))
	return SaveService._ok(hotel)

func reserve_room() -> Dictionary:
	var ready := _ready_for(["building_02"])
	if not ready.ok:
		return ready
	var hotel := state()
	if hotel.reserved:
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.reserved = true
	return _save_progress(progress)

func observe_repair(observation_id: String) -> Dictionary:
	var ready := _ready_for(["hotel_it"])
	if not ready.ok:
		return ready
	if not REPAIR_OBSERVATIONS.has(observation_id):
		return SaveService._fail("Cette observation ne fait pas partie du diagnostic.")
	var hotel := state()
	if observation_id in hotel.repair_observations:
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.repair_observations.append(observation_id)
	return _save_progress(progress)

func submit_repair(diagnosis: String = "storage_full", repair: String = "archive_logs_restart") -> Dictionary:
	var ready := _ready_for(["hotel_it"])
	if not ready.ok:
		return ready
	var hotel := state()
	if hotel.repair_observations.size() != REPAIR_OBSERVATIONS.size():
		return SaveService._fail("Consultez les quatre observations avant de choisir un diagnostic et une réparation.")
	if diagnosis != "storage_full":
		return SaveService._fail("L’alimentation et le réseau fonctionnent. Cherchez ce qui empêche le service d’enregistrer ses données.")
	if repair != "archive_logs_restart":
		return SaveService._fail("Archivez les anciens journaux pour libérer le disque, puis redémarrez le service de réservation.")
	if hotel.repaired:
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.repaired = true
	return _save_progress(progress)

func travel(destination: String) -> Dictionary:
	var ready := _ready_for(SaveService.HOTEL_ROOMS)
	if not ready.ok:
		return ready
	var source := str(AppState.profile.progress.room_id)
	var route := source + ">" + destination
	if not ROUTES.has(route):
		return SaveService._fail("Empruntez la porte ou la volée d’escalier de ce passage.")
	var hotel := state()
	if hotel.bed_state == "sitting":
		return SaveService._fail("Vous êtes installé sur le lit. Choisissez de dormir ou de continuer à attendre.")
	if destination == "hotel_it" and not hotel.reserved:
		return SaveService._fail("Réservez d’abord votre chambre à la réception.")
	if destination in ["hotel_stairs_1", "hotel_floor_2", "hotel_room_206"] and not hotel.repaired:
		return SaveService._fail("Réparez la panne du local informatique avant de rejoindre la chambre 206.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.room_id = destination
	progress.checkpoint_id = ROUTES[route]
	progress.active_mission = ""
	var saved := _save_progress(progress)
	if not saved.ok:
		return saved
	return SaveService._ok({"room_id": destination, "checkpoint_id": progress.checkpoint_id})

func place_luggage() -> Dictionary:
	var ready := _ready_for(["hotel_room_206"])
	if not ready.ok:
		return ready
	var hotel := state()
	if hotel.luggage_placed:
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.luggage_placed = true
	return _save_progress(progress)

func sit_on_bed() -> Dictionary:
	var ready := _ready_for(["hotel_room_206"])
	if not ready.ok:
		return ready
	var hotel := state()
	if not hotel.luggage_placed:
		return SaveService._fail("Posez vos affaires dans la chambre avant de vous installer.")
	if hotel.bed_state == "rested":
		return SaveService._fail("La nuit est déjà passée. Le séjour pourra continuer lors d’une prochaine mise à jour.")
	if hotel.bed_state == "sitting":
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.bed_state = "sitting"
	progress.checkpoint_id = "room206_bed"
	return _save_progress(progress)

func sleep_in_bed() -> Dictionary:
	var ready := _ready_for(["hotel_room_206"])
	if not ready.ok:
		return ready
	var hotel := state()
	if not hotel.luggage_placed:
		return SaveService._fail("Posez vos affaires dans la chambre avant de dormir.")
	if hotel.bed_state == "rested":
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.bed_state = "rested"
	progress.checkpoint_id = "room206_bed"
	return _save_progress(progress)
