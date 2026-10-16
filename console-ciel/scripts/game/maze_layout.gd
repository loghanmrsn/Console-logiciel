extends RefCounted
## Plan fixe : chemins, collisions et plaques emploient exactement la même grille.
const TILE := 96
const START := Vector2i(1, 21)
const CENTER := Vector2i(15, 11)
const GRID := [
	"###############################",
	"#.......#...............#.#...#",
	"#.###.#.#########.#####.#.#.#.#",
	"#.#.#.#...#...#...#...#.#...#.#",
	"#.#.#.###.#.#.#.###.#.#.#.###.#",
	"#.#.#.#...#.#.#.#...#.#.#...#.#",
	"#.#.#.###.#.#.#.#.#####.###.#.#",
	"#.#.#...#...#...#.......#...#.#",
	"#.#.###.#########.###########.#",
	"#.....#...#.#.....#...........#",
	"#####.###.#.#....######.#.#####",
	"#.......#.#.#.........#.#.....#",
	"#######.#.#.##....###.#######.#",
	"#...#...#.#.....#...#.#.......#",
	"#.#.#.###.#.#######.#.#.#####.#",
	"#.#.#.#...#.#.......#...#.#...#",
	"#.#.#.#.###.#####.#######.#.###",
	"#.#.#.#...#.#.....#.......#...#",
	"#.#.#####.#.#.#####.#####.###.#",
	"#.#.#...#.#...#...#.#...#...#.#",
	"#.#.#.#.#.#####.###.#.#.###.#.#",
	"#.#...#...#...........#...#...#",
	"###############################",
]
const NOTES := [
	{"cell": Vector2i(7, 5), "wall": Vector2i(7, 4), "title": "IDENTITÉ", "short": "user : admin", "text": "Fiche du serveur CIEL\n\nUtilisateur de connexion : admin. Ce compte ouvre une session utilisateur ; son nom seul ne garantit pas les droits complets."},
	{"cell": Vector2i(9, 1), "wall": Vector2i(9, 0), "title": "ACCÈS", "short": "mdp : admin", "text": "Accès au serveur CIEL\n\nMot de passe de connexion : admin. Les caractères sont en minuscules."},
	{"cell": Vector2i(23, 11), "wall": Vector2i(24, 11), "title": "LINUX", "short": "sudo -i", "text": "Mémo Linux\n\nsudo -i ouvre une session privilégiée pour un compte autorisé. Le mot de passe demandé est celui du compte connecté. Le terminal CIEL indique Linux dans son en-tête."},
	{"cell": Vector2i(3, 3), "wall": Vector2i(3, 2), "title": "WINDOWS", "short": "dir / cls", "text": "Mémo Windows\n\ndir liste les fichiers et cls efface l’affichage dans l’invite de commandes Windows. Ces commandes ne donnent pas de nouveaux droits."},
	{"cell": Vector2i(25, 1), "wall": Vector2i(25, 0), "title": "IDENTITÉS", "short": "su -", "text": "Mémo de maintenance\n\nsu - ouvre une session avec une autre identité. Dans ce serveur d’exercice, le mot de passe d’élévation est aussi admin. Une ancienne note abrège la commande en « s- ». Ce raccourci est propre à la simulation."},
	{"cell": Vector2i(1, 11), "wall": Vector2i(1, 10), "title": "WINDOWS", "short": "ipconfig", "text": "Mémo Windows\n\nipconfig affiche la configuration IP sous Windows. Lire une adresse réseau n’élève pas les permissions d’une session."},
	{"cell": Vector2i(21, 5), "wall": Vector2i(22, 5), "title": "SESSION", "short": "whoami", "text": "Mémo du terminal\n\nwhoami affiche l’identité actuelle. Sur ce serveur Linux simulé, admin est le compte connecté ; root désigne la session qui possède tous les droits."},
	{"cell": Vector2i(5, 17), "wall": Vector2i(6, 17), "title": "WINDOWS", "short": "runas", "text": "Mémo Windows\n\nrunas sert à lancer un programme avec un autre compte sous Windows. Ce n’est pas une commande sudo pour un terminal Linux."},
 ]

static func extent() -> Vector2:
	return Vector2(GRID[0].length(), GRID.size()) * TILE

static func at(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2.ONE * TILE * .5

static func is_floor(cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < GRID.size() and cell.x >= 0 and cell.x < GRID[0].length() and GRID[cell.y][cell.x] == "."

static func checkpoints() -> Dictionary:
	return {"entrance": at(START), "maze_entry": at(START), "maze_terminal": at(CENTER) + Vector2(0, 23), "maze": at(CENTER) + Vector2(0, 23), "exit": at(START)}
