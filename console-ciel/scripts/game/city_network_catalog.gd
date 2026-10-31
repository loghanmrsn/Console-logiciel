extends RefCounted
## Fixed teaching scenarios, using documentation-only addresses; no host commands.
const IDS := ["ipv4", "ipv6", "routing"]
const REWARD_IDS := ["city_ipv4", "city_ipv6", "city_routing"]
const REWARD := 50
const LESSON := "IPv4 : une adresse contient 32 bits. /24 réserve 24 bits au réseau et 8 aux hôtes : masque 255.255.255.0, 256 adresses dont généralement 254 attribuables aux hôtes. Pour 192.168.50.42/24, le réseau est 192.168.50.0 ; .255 est la diffusion et .254 le dernier hôte.\n\nIPv6 : une adresse contient 128 bits, écrits en hexadécimal. Un LAN utilise généralement /64 : 64 bits de préfixe réseau, puis 64 bits pour l’interface. 2001:db8:50:1::42/64 appartient à 2001:db8:50:1::/64. IPv6 n’a pas de diffusion broadcast : il utilise notamment le multicast. /32 n’est donc pas le masque habituel d’un LAN IPv6.\n\nLes préfixes IPv4 vont de /0 à /32, ceux d’IPv6 de /0 à /128. /24 et /64 sont des choix de ces exercices, pas des règles universelles. Le bloc 2001:db8::/32 est réservé à la documentation.\n\nUn switch relie les équipements d’un même réseau local. Un routeur relie des réseaux IP distincts. Pour joindre 192.168.60.10 depuis 192.168.50.42/24, le poste envoie les paquets à sa passerelle locale 192.168.50.1. Le routeur doit disposer d’une route vers 192.168.60.0/24 et le chemin retour doit aussi exister."
const CHALLENGES := {
 "ipv4": {"title":"1 · Préparer le poste IPv4", "evidence":"Le poste PC-01 utilise 192.168.50.42/24. La passerelle est 192.168.50.1. Configurez le plan d’adressage du LAN sans utiliser l’adresse réseau ni celle de diffusion.", "fields":[["mask","Masque décimal"],["network","Adresse du réseau (sans /24)"],["last","Dernière adresse hôte attribuable"]], "answers":{"mask":"255.255.255.0","network":"192.168.50.0","last":"192.168.50.254"}, "explanation":"/24 laisse 8 bits pour les hôtes : 2^8 = 256 adresses. Le réseau .0 et la diffusion .255 sont réservés ; les hôtes vont de .1 à .254. La passerelle .1 occupe déjà l’une de ces adresses."},
 "ipv6": {"title":"2 · Ajouter un LAN IPv6", "evidence":"Le second poste reçoit 2001:db8:50:1::42/64. Trouvez la taille d’une adresse IPv6, la longueur du préfixe de ce LAN et son réseau. :: remplace une suite de groupes de zéros.", "fields":[["bits","Nombre de bits d’une adresse IPv6"],["prefix","Longueur du préfixe de ce LAN (nombre)"],["network","Préfixe réseau complet, avec /64"]], "answers":{"bits":"128","prefix":"64","network":"2001:db8:50:1::/64"}, "explanation":"IPv6 contient 128 bits. Dans ce LAN, /64 sépare le préfixe réseau (2001:db8:50:1::/64) de la partie interface. /32 peut être un bloc d’allocation, mais ne remplace pas /64 dans cet exercice."},
 "routing": {"title":"3 · Relier les deux réseaux IPv4", "evidence":"PC-01 : 192.168.50.42/24. Serveur : 192.168.60.10/24. Un switch local est déjà branché ; l’interface LAN de l’équipement de routage est 192.168.50.1. Identifiez l’équipement à utiliser, la passerelle du PC et la route de destination.", "fields":[["device","Équipement : switch ou routeur ?"],["gateway","Passerelle IPv4 du PC"],["destination","Réseau du serveur, avec son préfixe"]], "answers":{"device":"routeur","gateway":"192.168.50.1","destination":"192.168.60.0/24"}, "explanation":"Les préfixes /24 sont distincts. Le switch relie le LAN ; le routeur transporte les paquets entre réseaux. La passerelle du PC est 192.168.50.1, située sur son propre LAN. Le routage vers 192.168.60.0/24 doit aussi prévoir un chemin retour."}
}
static func empty_state() -> Dictionary: return {"version":1,"completed":[]}
static func accepts(id: String, answer: Variant) -> bool:
	if id not in IDS or not answer is Dictionary: return false
	var expected: Dictionary = CHALLENGES[id].answers
	if answer.size() != expected.size(): return false
	for key in expected:
		if not answer.get(key) is String or answer[key].length() > 96: return false
		var value: String = answer[key].strip_edges().to_lower()
		if id == "ipv6" and key == "network":
			if value not in ["2001:db8:50:1::/64", "2001:0db8:0050:0001:0000:0000:0000:0000/64", "2001:db8:50:1:0:0:0:0/64"]: return false
		elif value != expected[key]: return false
	return true
