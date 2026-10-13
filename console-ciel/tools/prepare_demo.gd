extends SceneTree
## Outil de développement, exclu des exports. Aucun crédit arbitraire.
## Les données sont isolées dans <output>/data/console-ciel.

const MANIFEST_VERSION := 1
const MANIFEST_KIND := "console-ciel-development-demo"
const PROFILE_NAME := "CIEL Démo"

var runtime_root := ""
var data_root := ""
var manifest_path := ""
var reset_requested := false
var prefilled_requested := false
var saves
var profiles
var state
var shop
var rewards
var investigation

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	if not OS.is_debug_build():
		_fail("Cet outil est réservé au moteur de développement Godot ; il n'est pas disponible dans la version de livraison.")
		return
	if not _arguments():
		return
	if not _validate_root():
		return
	for service_name in ["SaveService", "ProfileService", "AppState", "ShopService", "RewardService", "InvestigationService"]:
		if not root.has_node(service_name):
			_fail("Service requis absent : " + service_name)
			return
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	state = root.get_node("AppState")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	saves.root_path = data_root
	state.clear_profile()
	if not _result(shop.load_catalog()) or not _result(rewards.load_rules()):
		return
	var manifest := _load_manifest()
	if manifest.is_empty() and FileAccess.file_exists(manifest_path):
		return
	if manifest.is_empty() and _contains_existing_data():
		_fail("Cette racine contient déjà des données sans manifeste de démonstration. Elles sont conservées ; choisissez un autre --output.")
		return
	if reset_requested and manifest.is_empty():
		_fail("Réinitialisation refusée : aucun manifeste valide ne désigne un profil de démonstration. Lancez sans --reset pour préparer une nouvelle racine.")
		return
	if not manifest.is_empty():
		if not _check_owned_files(manifest.profile_id):
			return
		var loaded: Dictionary = saves.read_profile(manifest.profile_id)
		if not loaded.ok:
			_fail("Le profil désigné est absent ou invalide. Aucune suppression automatique : " + loaded.error)
			return
		if reset_requested:
			# Le service ne reçoit que l'identifiant du manifeste. Il conserve les
			# autres documents et ne supprime jamais toute la racine de données.
			if not _result(profiles.delete_profile(manifest.profile_id)):
				return
			manifest = {}
		else:
			if not _result(profiles.select_profile(manifest.profile_id)):
				return
	if manifest.is_empty():
		var created: Dictionary = profiles.create_profile(PROFILE_NAME)
		if not _result(created):
			return
		manifest = {
			"schema_version": MANIFEST_VERSION,
			"kind": MANIFEST_KIND,
			"profile_id": created.data.id,
			"runtime_root": runtime_root,
			"data_root": data_root,
			"created_at": Time.get_datetime_string_from_system(false, true)
		}
		var recorded: Dictionary = saves.atomic_write_text(manifest_path, JSON.stringify(manifest, "\t"))
		if not recorded.ok:
			# Ce profil vient d'être généré dans cette racine ; aucun profil
			# préexistant n'est supprimé si l'écriture du manifeste échoue.
			profiles.delete_profile(created.data.id)
			_fail("Impossible d'enregistrer le manifeste de démonstration : " + recorded.error)
			return
	if prefilled_requested and "lighting" not in state.profile.progress.completed_missions:
		if not state.profile.progress.started and not _result(profiles.start_game()):
			return
		if not _result(investigation.begin_mission("lighting")):
			return
		var definition: Dictionary = investigation.mission("lighting")
		if not _result(investigation.submit_lighting(definition.solution.connections)):
			return
	if not _result(profiles.save_active()):
		return
	print("DÉMONSTRATION DE DÉVELOPPEMENT — données isolées")
	print("Profil : ", state.profile.display_name, " [", state.profile.id, "]")
	print("Points : ", state.profile.wallet.points, " ; missions : ", state.profile.progress.completed_missions)
	print("Racine : ", runtime_root)
	print("Sauvegardes : ", data_root)
	print("Manifeste : ", manifest_path)
	print("Relance : tools/run_demo.sh --output ", _shell_quote(runtime_root))
	print("Réinitialiser ce seul profil : tools/run_demo.sh --output ", _shell_quote(runtime_root), " --reset --prepare-only")
	quit(0)

func _arguments() -> bool:
	var arguments := OS.get_cmdline_user_args()
	runtime_root = ProjectSettings.globalize_path("res://builds/demo-runtime").simplify_path()
	var index := 0
	while index < arguments.size():
		match arguments[index]:
			"--output":
				index += 1
				if index >= arguments.size() or not arguments[index].is_absolute_path() or arguments[index].contains("://"):
					_fail("--output attend un chemin absolu local, distinct des sauvegardes normales.")
					return false
				runtime_root = arguments[index].simplify_path().trim_suffix("/")
			"--reset": reset_requested = true
			"--prefilled": prefilled_requested = true
			"--help", "-h":
				print("godot --headless --path . --script res://tools/prepare_demo.gd -- [--output /chemin/absolu] [--reset] [--prefilled]")
				print("Par défaut : builds/demo-runtime. --prefilled résout seulement l'éclairage avec les règles normales ; --reset supprime seulement le profil désigné par le manifeste.")
				quit(0)
				return false
			_:
				_fail("Option inconnue : " + arguments[index])
				return false
		index += 1
	data_root = runtime_root.path_join("data/console-ciel")
	manifest_path = runtime_root.path_join(".demo_manifest.json")
	return true

func _validate_root() -> bool:
	var project_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if runtime_root in ["", "/", "/tmp", "/workspace", project_root] or runtime_root.length() < 8:
		_fail("Choisissez une sous-racine dédiée à la démonstration, pas un répertoire système ou la racine du projet.")
		return false
	# Même avec XDG_DATA_HOME changé par run_demo.sh, la destination usuelle
	# de l'utilisateur reste protégée. Aucun lien ne peut contourner ce test.
	var normal_data := OS.get_environment("HOME").path_join(".local/share/console-ciel").simplify_path()
	if _inside(runtime_root, normal_data) or _inside(normal_data, runtime_root):
		_fail("La racine de démonstration ne doit pas contenir les sauvegardes normales de l'utilisateur.")
		return false
	var current_data := OS.get_user_data_dir().simplify_path()
	if current_data != data_root and (_inside(runtime_root, current_data) or _inside(current_data, runtime_root)):
		_fail("La racine choisie recouvre user://. Utilisez une racine de démonstration séparée.")
		return false
	for path in [runtime_root, data_root.path_join("profiles"), manifest_path, data_root.path_join("session.json"), data_root.path_join("settings.cfg")]:
		if not _no_symlink_path(path):
			return false
	if DirAccess.make_dir_recursive_absolute(runtime_root) != OK:
		_fail("Impossible de créer la racine de démonstration.")
		return false
	return true

func _inside(path: String, directory: String) -> bool:
	return path == directory or path.begins_with(directory.trim_suffix("/") + "/")

func _no_symlink_path(path: String) -> bool:
	var directory := DirAccess.open("/")
	if directory == null:
		_fail("Vérification de chemin indisponible. L'outil nécessite un environnement PC/Linux avec chemins absolus.")
		return false
	var examined := ""
	for part in path.split("/", false):
		examined += "/" + part
		if directory.is_link(examined):
			_fail("Lien symbolique refusé dans la racine de démonstration : " + examined)
			return false
	return true

func _contains_existing_data() -> bool:
	var directory := DirAccess.open(data_root)
	if directory == null:
		return false
	# Godot peut déjà avoir créé logs/godot.log avant _initialize(). Ce
	# journal ne constitue pas un profil préexistant. Tout autre contenu est
	# conservé et fait refuser une racine dépourvue de manifeste.
	if not directory.get_files().is_empty():
		return true
	for child in directory.get_directories():
		if child == "logs":
			continue
		var child_directory := DirAccess.open(data_root.path_join(child))
		if child != "profiles" or child_directory == null or not child_directory.get_files().is_empty() or not child_directory.get_directories().is_empty():
			return true
	return false

func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(manifest_path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(manifest_path)) != OK:
		_fail("Manifeste de démonstration illisible. Aucun profil n'a été modifié.")
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("schema_version") != MANIFEST_VERSION or parsed.get("kind") != MANIFEST_KIND or not parsed.get("profile_id") is String or not saves.is_safe_id(parsed.profile_id) or parsed.get("runtime_root") != runtime_root or parsed.get("data_root") != data_root:
		_fail("Manifeste de démonstration invalide ou déplacé. Aucun profil n'a été modifié.")
		return {}
	return parsed

func _check_owned_files(profile_id: String) -> bool:
	var directory := DirAccess.open(data_root.path_join("profiles"))
	if directory == null:
		return true
	# Les services listent tous les profils ; aucune lecture ne doit suivre un
	# document symbolique pointant vers les sauvegardes d'une autre exécution.
	for filename in directory.get_files():
		if not _no_symlink_path(data_root.path_join("profiles").path_join(filename)):
			return false
	for filename in DirAccess.get_files_at(runtime_root):
		if filename.begins_with(".demo_manifest.json") and not _no_symlink_path(runtime_root.path_join(filename)):
			return false
	return _no_symlink_path(data_root.path_join("profiles").path_join(profile_id + ".json"))

func _result(result: Dictionary) -> bool:
	if result.get("ok", false):
		return true
	_fail(str(result.get("error", "Erreur inconnue pendant la préparation.")))
	return false

func _shell_quote(value: String) -> String:
	return "'" + value.replace("'", "'\"'\"'") + "'"

func _fail(message: String) -> void:
	printerr("Préparation de démonstration refusée : ", message)
	quit(1)
