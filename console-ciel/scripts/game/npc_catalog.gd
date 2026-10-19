extends RefCounted
## Shared NPC placements and read-only dialogue. Talking never advances a quest.
const CHARACTERS := [
	{
		"id": "npc_workshop", "zone": "room_01", "name": "Nora",
		"role": "Technicienne CIEL",
		"at": Vector2(202, 300), "approach": Vector2(202, 340),
		"coat": "749b90", "skin": "dfbca0", "hair": "665248", "accessory": "badge", "hairstyle": "bob"
	},
	{
		"id": "npc_top_floor", "zone": "room_05", "name": "Idris",
		"role": "Responsable de l’atelier",
		"at": Vector2(700, 275), "approach": Vector2(700, 315),
		"coat": "728ca2", "skin": "bd8b6c", "hair": "4f4643", "accessory": "glasses", "hairstyle": "curls"
	},
	{
		"id": "npc_buffet", "zone": "hotel_breakfast", "name": "Lucie",
		"role": "Équipe du petit déjeuner",
		"at": Vector2(885, 330), "approach": Vector2(885, 375),
		"coat": "aa9675", "skin": "ebcbb1", "hair": "8b6c51", "accessory": "apron", "hairstyle": "bun"
	},
	{
		"id": "npc_hotel_door", "zone": "courtyard", "name": "Camille",
		"role": "Accueil de l’Hôtel CIEL",
		"at": Vector2(1130, 412), "approach": Vector2(1130, 458),
		"coat": "798d83", "skin": "c89e82", "hair": "554b43", "accessory": "tie", "hairstyle": "side_part"
	},
	{
		"id": "npc_crossing", "zone": "courtyard", "name": "Sam",
		"role": "Agent de circulation",
		"at": Vector2(654, 963), "approach": Vector2(654, 1008),
		"coat": "b7ab77", "skin": "d3ae8c", "hair": "645447", "accessory": "vest", "hairstyle": "cap"
	},
	{
		"id": "npc_closed_floor", "zone": "hotel_stairs_1", "name": "Alex",
		"role": "Agent d’étage",
		"at": Vector2(775, 780), "approach": Vector2(775, 825),
		"coat": "92839d", "skin": "d6b296", "hair": "5b4b42", "accessory": "badge", "hairstyle": "short"
	}
]

static func for_zone(zone: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for character in CHARACTERS:
		if character.zone == zone: result.append(character.duplicate(true))
	return result

static func find(id: String) -> Dictionary:
	for character in CHARACTERS:
		if character.id == id: return character.duplicate(true)
	return {}

static func pages(id: String, progress: Dictionary) -> Array[String]:
	var completed: Array = progress.get("completed_missions", [])
	var hotel: Dictionary = progress.get("hotel", {})
	var morning := int(hotel.get("morning_stage", 0))
	match id:
		"npc_workshop":
			if "computer" in completed:
				return ["Bravo, l’atelier fonctionne à nouveau ! L’ascenseur du bureau permet de poursuivre l’enquête aux étages supérieurs.", "Chaque défi vous apprend à observer, comprendre puis résoudre une panne. Vous pouvez revenir me parler à tout moment. Votre carnet de missions s’affiche avec T ou la touche haute de la manette."]
			return ["Bienvenue dans Console CIEL ! Vous incarnez une personne venue remettre ce bâtiment en service. Une panne perturbe l’atelier : la lumière, la porte du bureau et son ordinateur ont besoin de vous.", "Commencez par le tableau électrique, puis examinez la commande de la porte et l’ordinateur. Approchez-vous d’un objet et utilisez Espace ou la touche basse de la manette. T ou la touche haute affiche les missions. Les défis rapportent des points utilisables dans la boutique."]
		"npc_top_floor":
			if "maze" in completed:
				return ["Vous avez terminé l’épreuve du dernier étage. Pour quitter le bâtiment, retournez à l’ascenseur et descendez jusqu’au rez-de-chaussée.", "La porte de sortie se trouve dans la première salle. Traversez ensuite la cour par le passage piéton pour rejoindre l’Hôtel CIEL, le bâtiment d’en face."]
			return ["Vous voici au dernier étage du premier bâtiment. Le portable, au centre de la pièce, propose un parcours où l’observation compte autant que les connaissances.", "Interagissez avec le portable puis choisissez « Y aller ». Explorez les lieux et lisez les inscriptions : certains indices sont utiles, d’autres sont des fausses pistes. Prenez votre temps ; je vous laisse découvrir le reste."]
		"npc_buffet":
			if morning >= 5:
				return ["Votre café est servi. J’espère que ce petit déjeuner vous a fait du bien !", "Retournez à la chambre 206 récupérer le sac contenant votre ordinateur." if morning == 5 else "Le bus pour Sudo Hack vous attend dans la cour, devant l’hôtel. Bonne route !"]
			if morning == 4:
				return ["Merci, la machine à café fonctionne à nouveau ! Il reste à prendre votre café en interagissant avec elle.", "Vous pourrez ensuite retourner chercher vos affaires dans la chambre 206 avant de partir pour Sudo Hack."]
			if morning == 3:
				return ["La machine à café a besoin d’une réparation. Vous pouvez examiner son panneau électrique : les fils vont par paires de même couleur.", "Choisissez un contact du haut, puis son correspondant en bas. Le contact choisi brille ; appuyez à nouveau dessus pour le désélectionner. Les trois bonnes connexions remettront la machine en service."]
			return ["Bonjour et bienvenue au buffet ! Installez-vous à la table centrale pour commencer votre petit déjeuner.", "La machine à café se trouve au fond, sur la droite. Si vous avez besoin d’aide, vous pouvez revenir me parler."]
		"npc_hotel_door":
			if morning >= 6:
				return ["Vous avez votre sac et votre ordinateur : tout est prêt pour votre départ à Sudo Hack.", "L’arrêt de bus se trouve de l’autre côté de la cour. Empruntez le passage piéton et attendez le vert avant de traverser."]
			if not bool(hotel.get("reserved", false)):
				return ["Bienvenue à l’Hôtel CIEL, le deuxième bâtiment de votre aventure. Entrez par la porte à ma gauche : la réception vous attend dans le grand hall.", "Adressez-vous à la réception pour réserver la chambre 206. La réservation fait partie de l’histoire et ne vous coûte aucun point."]
			return ["La réception reste votre point de repère dans l’hôtel. Le local informatique est tout près et les escaliers desservent la chambre 206.", "Seul le palier du premier étage est ouvert ; les chambres de cet étage sont fermées au public. Votre chambre se trouve au deuxième étage."]
		"npc_crossing":
			return ["Pour traverser, utilisez les bandes blanches et attendez le feu piéton vert. Quand le feu est rouge, les voitures passent. Elles roulent doucement, mais regardez avant de vous engager.", "Une traversée complète commencée au rouge entraîne une pénalité de 200 points, même sans collision. Si une voiture vous touche, vous revenez sur votre trottoir de départ. Une traversée commencée au vert reste protégée jusqu’à votre arrivée."]
		"npc_closed_floor":
			return ["Le premier étage de l’hôtel est fermé au public. Le passage vers les chambres de cet étage est bloqué : seul ce palier d’escalier reste accessible.", "Vous pouvez monter au deuxième étage pour rejoindre la chambre 206, ou redescendre au rez-de-chaussée par l’escalier voisin. Les deux escaliers se trouvent du même côté du palier."]
	return []
