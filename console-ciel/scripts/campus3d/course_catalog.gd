extends RefCounted
## Ordered, local teaching exercises. No connection to a real network is made.
const IDS := ["net_cable", "net_address", "net_gateway", "cyber_mail", "cyber_mfa", "cyber_incident"]
const LESSONS := {
	"net_cable": {"zone":"network", "title":"1 · Relier le poste", "prompt":"Le PC doit rejoindre le réseau local filaire. Le commutateur possède des ports Ethernet RJ45. Choisissez le câble adapté.", "choices":["HDMI : relier le PC à son écran", "Ethernet RJ45 : relier le PC au commutateur", "USB : relier le clavier au PC"], "answer":1, "hint":"Le câble HDMI transporte l’image et le son ; USB sert ici au clavier. Pour le réseau local filaire, utilisez Ethernet RJ45.", "success":"Le voyant de liaison est allumé. Le poste peut maintenant être configuré sur le réseau."},
	"net_address": {"zone":"network", "title":"2 · Configurer l’adresse IP", "prompt":"Réseau : 192.168.10.0/24. Passerelle : 192.168.10.1. L’adresse .20 est déjà occupée ; .21 est disponible. Quelle adresse attribuez-vous au nouveau poste ?", "choices":["192.168.10.20 / 24", "192.168.20.21 / 24", "192.168.10.21 / 24"], "answer":2, "hint":"Évitez l’adresse déjà utilisée. Avec /24, gardez les trois premiers nombres du réseau : 192.168.10.", "success":"Le poste possède une adresse disponible dans le bon sous-réseau : 192.168.10.21/24."},
	"net_gateway": {"zone":"network", "title":"3 · Joindre un autre réseau", "prompt":"Le poste 192.168.10.21/24 communique avec ses voisins mais pas avec les autres réseaux. Le routeur local utilise 192.168.10.1. Quelle passerelle configurez-vous ?", "choices":["192.168.10.1", "192.168.10.21 : l’adresse du poste", "192.168.20.1 : une adresse hors du sous-réseau"], "answer":0, "hint":"La passerelle est le routeur accessible sur le réseau local, pas l’adresse du poste ni une adresse d’un autre sous-réseau.", "success":"Le routeur peut transmettre les paquets vers les autres réseaux. Parcours réseau terminé ! La salle cybersécurité vous attend."},
	"cyber_mail": {"zone":"cyber", "title":"4 · Examiner un message", "prompt":"Un courriel prétend venir du lycée : « Votre compte expire aujourd’hui. Saisissez votre mot de passe sur compte-urgence.example. » Que faites-vous ?", "choices":["Saisir le mot de passe pour conserver l’accès", "Signaler le message et vérifier via le portail habituel", "Transférer le lien à toute la classe"], "answer":1, "hint":"L’urgence et la demande de mot de passe sur un domaine inhabituel sont des signaux d’alerte. Ouvrez vous-même le portail connu, sans suivre ce lien.", "success":"Message signalé. Aucun identifiant n’a été transmis au site suspect."},
	"cyber_mfa": {"zone":"cyber", "title":"5 · Protéger le compte", "prompt":"Vous avez déjà un mot de passe long et unique. Quelle mesure protège le mieux l’accès au compte ?", "choices":["Réutiliser ce mot de passe sur tous les sites", "Partager le code de connexion avec un camarade", "Activer un second facteur et garder les codes de secours en lieu sûr"], "answer":2, "hint":"Le second facteur ajoute une vérification indépendante. Les codes de connexion restent privés ; les codes de secours sont conservés en lieu sûr.", "success":"Le compte est protégé par un second facteur. Les codes ne sont ni partagés ni envoyés par courriel."},
	"cyber_incident": {"zone":"cyber", "title":"6 · Réagir à un incident", "prompt":"La console d’analyse signale un poste qui envoie soudainement un trafic inhabituel. Quelle première réaction choisissez-vous ?", "choices":["Isoler le poste du réseau, prévenir le responsable et préserver les journaux", "Effacer tous les journaux pour faire disparaître l’alerte", "Brancher le poste sur un autre réseau sans prévenir"], "answer":0, "hint":"Contenez l’incident, alertez le responsable et gardez les traces utiles à l’analyse. Évitez les actions qui détruisent les preuves ou déplacent le problème.", "success":"Le poste est isolé et les traces sont conservées. Les deux parcours sont terminés. Vous pouvez revoir les exercices et continuer l’exploration."}
}

static func empty_state() -> Dictionary:
	return {"version":1, "completed":[]}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=2 or not value.get("version") is float and not value.get("version") is int: return false
	if value.version!=1 or not value.get("completed") is Array or value.completed.size()>IDS.size(): return false
	for i in value.completed.size():
		if value.completed[i]!=IDS[i]: return false
	return true

static func current(profile: Dictionary) -> Dictionary:
	return profile.get("progress",{}).get("campus3d",empty_state()).duplicate(true)

static func objective(profile: Dictionary) -> String:
	var done: Array=current(profile).completed
	if done.size()==IDS.size(): return "Parcours réseau et cybersécurité terminés · 6/6"
	return "%d/6 · %s" % [done.size(),LESSONS[IDS[done.size()]].title]

static func answer(state: Node, saves: Node, id: String, choice: int) -> Dictionary:
	if state.profile.is_empty() or id not in IDS: return {"ok":false,"error":"Choisissez un profil et un exercice disponible."}
	var progress=current(state.profile)
	var index:=IDS.find(id)
	if index>progress.completed.size(): return {"ok":false,"error":"Commencez par « %s »." % LESSONS[IDS[progress.completed.size()]].title}
	if choice!=LESSONS[id].answer: return {"ok":false,"error":LESSONS[id].hint}
	if id in progress.completed: return {"ok":true,"repeated":true}
	progress.completed.append(id)
	var document=state.profile.duplicate(true)
	document.progress.campus3d=progress
	var result=saves.write_profile(document)
	if result.ok: state.commit_profile(result.data)
	return result
