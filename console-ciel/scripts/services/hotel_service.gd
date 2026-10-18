extends Node
## Séjour local : réservation, réparation et matinée avant le CTF.
## Chaque étape et son éventuelle récompense sont écrites dans une transaction.

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
	"hotel_room_206>hotel_floor_2": "floor2_room206",
	"building_02>hotel_breakfast": "breakfast_entry",
	"hotel_breakfast>building_02": "hall_breakfast",
	"building_02>courtyard": "from_second",
	"courtyard>building_02": "new_entrance",
	"ctf_bus_stop>ctf_lobby": "ctf_entry",
	"ctf_lobby>ctf_bus_stop": "ctf_door"
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

func _save_progress(progress: Dictionary, reward_id: String = "") -> Dictionary:
	var document: Dictionary = AppState.profile.duplicate(true)
	document.progress = progress.duplicate(true)
	var reward := 0
	if not reward_id.is_empty() and reward_id not in document.rewarded_missions:
		if reward_id not in SaveService.HOTEL_REWARD_IDS:
			return SaveService._fail("Cette étape de l’hôtel ne possède pas de récompense.")
		reward = 50
		if int(document.wallet.points) > SaveService.MAX_POINTS - reward:
			return SaveService._fail("Le portefeuille a atteint sa limite.")
		document.wallet.points = int(document.wallet.points) + reward
		document.rewarded_missions.append(reward_id)
	var saved := SaveService.write_profile(document)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	var hotel: Dictionary = saved.data.progress.hotel.duplicate(true)
	state_changed.emit(hotel.duplicate(true))
	var result := SaveService._ok(hotel)
	result["reward"] = reward
	return result

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
	var ready := _ready_for(SaveService.HOTEL_ROOMS + ["courtyard"])
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
	if destination == "hotel_breakfast" and int(hotel.morning_stage) < 2:
		return SaveService._fail("Reposez-vous dans votre chambre, puis rejoignez le rez-de-chaussée.")
	if source == "building_02" and destination == "courtyard" and int(hotel.morning_stage) > 0 and int(hotel.morning_stage) < 6:
		return SaveService._fail("Prenez votre café puis récupérez votre sac dans la chambre 206 avant de partir au CTF.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.room_id = destination
	progress.checkpoint_id = ROUTES[route]
	progress.active_mission = ""
	var reward_id := ""
	if destination == "building_02" and int(hotel.morning_stage) == 1:
		progress.hotel.morning_stage = 2
		reward_id = "hotel_ground_floor"
	if destination == "ctf_lobby" and int(hotel.morning_stage) == 7:
		progress.hotel.morning_stage = 8
	var saved := _save_progress(progress, reward_id)
	if not saved.ok:
		return saved
	var result := SaveService._ok({"room_id": destination, "checkpoint_id": progress.checkpoint_id, "reward": saved.reward})
	result["reward"] = saved.reward
	return result

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
		return SaveService._fail("La nuit est déjà passée. Rejoignez le rez-de-chaussée pour poursuivre votre matinée.")
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
	progress.hotel.morning_stage = 1
	progress.checkpoint_id = "room206_bed"
	return _save_progress(progress)

## Les profils 0.11.0 peuvent reprendre une nuit déjà passée directement au hall.
## La simple lecture du profil ne distribue jamais de points.
func arrive_ground_floor() -> Dictionary:
	var ready := _ready_for(["building_02"])
	if not ready.ok:
		return ready
	var hotel := state()
	if int(hotel.morning_stage) < 1:
		return SaveService._fail("Passez d’abord la nuit dans la chambre 206.")
	if int(hotel.morning_stage) >= 2:
		var result := SaveService._ok(hotel)
		result["reward"] = 0
		return result
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.morning_stage = 2
	return _save_progress(progress, "hotel_ground_floor")

func sit_for_breakfast() -> Dictionary:
	var ready := _ready_for(["hotel_breakfast"])
	if not ready.ok:
		return ready
	var hotel := state()
	if int(hotel.morning_stage) < 2:
		return SaveService._fail("Rejoignez le rez-de-chaussée avant de prendre le petit déjeuner.")
	if int(hotel.morning_stage) >= 3:
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.morning_stage = 3
	progress.checkpoint_id = "breakfast_table"
	return _save_progress(progress)

func connect_coffee_wire(top: String, bottom: String) -> Dictionary:
	var ready := _ready_for(["hotel_breakfast"])
	if not ready.ok:
		return ready
	var hotel := state()
	if int(hotel.morning_stage) < 3:
		return SaveService._fail("Installez-vous à votre table pour commencer le petit déjeuner.")
	if not SaveService.COFFEE_WIRES.has(top) or SaveService.COFFEE_WIRES[top] != bottom:
		return SaveService._fail("Les deux fils doivent avoir la même couleur : choisissez une autre borne.")
	if hotel.coffee_connections.has(top):
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.coffee_connections[top] = bottom
	if progress.hotel.coffee_connections.size() == SaveService.COFFEE_WIRES.size():
		progress.hotel.morning_stage = 4
	return _save_progress(progress)

func take_coffee() -> Dictionary:
	var ready := _ready_for(["hotel_breakfast"])
	if not ready.ok:
		return ready
	var hotel := state()
	if int(hotel.morning_stage) < 4:
		return SaveService._fail("Raccordez les trois fils de la machine avant de prendre votre café.")
	if int(hotel.morning_stage) >= 5:
		return SaveService._ok(hotel)
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.morning_stage = 5
	return _save_progress(progress)

func collect_backpack() -> Dictionary:
	var ready := _ready_for(["hotel_room_206"])
	if not ready.ok:
		return ready
	var hotel := state()
	if int(hotel.morning_stage) < 5:
		return SaveService._fail("Prenez d’abord votre café au petit déjeuner.")
	if int(hotel.morning_stage) >= 6:
		var result := SaveService._ok(hotel)
		result["reward"] = 0
		return result
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.morning_stage = 6
	return _save_progress(progress, "hotel_backpack")

func board_bus() -> Dictionary:
	var ready := _ready_for(["courtyard"])
	if not ready.ok:
		return ready
	var hotel := state()
	if int(hotel.morning_stage) != 6:
		return SaveService._fail("Récupérez votre sac avec l’ordinateur avant de prendre le bus pour Sudo Hack.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.hotel.morning_stage = 7
	progress.room_id = "ctf_bus_stop"
	progress.checkpoint_id = "ctf_arrival"
	progress.active_mission = ""
	var saved := _save_progress(progress)
	if not saved.ok:
		return saved
	return SaveService._ok({"room_id": progress.room_id, "checkpoint_id": progress.checkpoint_id})
