extends RefCounted
## Épreuves locales : aucune commande saisie n'est exécutée sur l'ordinateur.
const IDS := ["phishing", "logs", "base64", "permissions", "flag"]
const REWARD_IDS := ["ctf_phishing", "ctf_logs", "ctf_base64", "ctf_permissions", "ctf_flag"]
const REWARD := 50
const CHALLENGES := {
	"phishing": {
		"title": "01 · Le faux message", "skill": "PHISHING",
		"evidence": "Adresse officielle : inscription@sudo-hack.example\nMessage reçu de : assistance@sudo-hack-support.example\n« Urgent ! Votre accès expire. Saisissez votre mot de passe sur notre nouveau portail. »\n\nUn nom ressemblant au site officiel ne prouve pas son authenticité. Vérifiez le domaine exact, sans ouvrir le lien.",
		"prompt": "Quel est le domaine de l'expéditeur suspect ?", "answer": "sudo-hack-support.example",
		"hint": "Recopiez uniquement la partie située après @ dans l'adresse du message reçu.",
		"explanation": "sudo-hack-support.example diffère de sudo-hack.example. L'urgence et la demande de mot de passe renforcent le soupçon : contactez l'organisateur par son canal officiel."
	},
	"logs": {
		"title": "02 · La piste des journaux", "skill": "JOURNAUX",
		"evidence": "09:01 | 192.0.2.18 | admin | SUCCESS\n09:02 | 192.0.2.42 | admin | FAILED\n09:03 | 192.0.2.42 | admin | FAILED\n09:04 | 192.0.2.42 | admin | FAILED\n09:05 | 192.0.2.18 | participant | SUCCESS\n\nCes adresses sont fictives. Un échec isolé peut être une erreur ; plusieurs échecs rapprochés méritent une vérification.",
		"prompt": "Quelle adresse IPv4 cumule les trois échecs ?", "answer": "192.0.2.42",
		"hint": "Repérez les lignes FAILED, puis comparez leur adresse source.",
		"explanation": "192.0.2.42 apparaît sur les trois échecs. Un journal donne des indices ; cela ne suffit pas, à lui seul, à prouver une attaque."
	},
	"base64": {
		"title": "03 · Le message encodé", "skill": "BASE64",
		"evidence": "Message : Q0lFTF8yMDI2\n\nLa table de décodage de ce poste fournit :\nQ0lF → CIE\nTF8y → L_2\nMDI2 → 026\n\nAssemblez les trois fragments dans cet ordre. Base64 est un encodage réversible, pas un chiffrement : il ne protège pas un secret.",
		"prompt": "Quel est le message décodé ? Respectez les majuscules.", "answer": "CIEL_2026",
		"hint": "Concaténez CIE, L_2 et 026, sans espace.",
		"explanation": "Q0lFTF8yMDI2 donne CIEL_2026. Gardez ce message : il servira à composer le flag final."
	},
	"permissions": {
		"title": "04 · Le fichier privé", "skill": "PERMISSIONS",
		"evidence": "Fichier du participant : secret.txt\nPermission actuelle : 644 (lecture possible pour le groupe et les autres).\nObjectif : seul le propriétaire doit pouvoir lire et écrire.\n\nMémo Linux : lecture = 4, écriture = 2, exécution = 1.\nLes trois chiffres correspondent à propriétaire / groupe / autres.\nSyntaxe : chmod NNN secret.txt\n\nCe terminal est une simulation ; il ne modifie aucun vrai fichier.",
		"prompt": "Quelle commande applique la permission demandée ?", "answer": "chmod 600 secret.txt",
		"hint": "Le propriétaire a 4 + 2 = 6 ; le groupe et les autres ont 0.",
		"explanation": "chmod 600 secret.txt donne lecture et écriture au propriétaire, aucun droit au groupe et aux autres. Aucun droit d'exécution n'est nécessaire ici."
	},
	"flag": {
		"title": "05 · Le coffre final", "skill": "FLAG FINAL",
		"evidence": "Le coffre attend le message décodé à l'épreuve 03.\n\nFormat du flag : SUDO{message}\nExemple de format uniquement : SUDO{EXEMPLE}\n\nRespectez la casse, les accolades et l'absence d'espace. Vous pouvez relire les postes déjà validés.",
		"prompt": "Saisissez le flag final.", "answer": "SUDO{CIEL_2026}",
		"hint": "Placez CIEL_2026 entre les accolades, après SUDO.",
		"explanation": "SUDO{CIEL_2026} ouvre le coffre. Les cinq épreuves Sudo Hack sont terminées : le bus de retour vers la ville et l'hôtel vous attend dehors."
	}
}

static func empty_state() -> Dictionary:
	return {"version": 1, "completed": []}

static func accepts(id: String, answer: String) -> bool:
	if not CHALLENGES.has(id) or answer.length() > 128: return false
	var value := answer.strip_edges()
	if id == "permissions": value = " ".join(value.split(" ", false))
	return value == str(CHALLENGES[id].answer)
