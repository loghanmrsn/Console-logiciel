extends RefCounted
## Original playable interpretation of the five photographed workshops.
## Measurements/connections are adapted; reference photographs are not shipped.
const IDS := ["school_workshop", "school_tne", "school_meeting", "school_cyber", "school_fed"]
const NEW_IDS := ["school_tne", "school_meeting", "school_fed"]
const TITLES := {
	"school_workshop": "Atelier 1 · BAC PRO CIEL",
	"school_tne": "Atelier 2 · 2TNE · câblage et systèmes",
	"school_meeting": "Atelier 3 · salle de réunion",
	"school_cyber": "Atelier 4 · CIEL · informatique",
	"school_fed": "Atelier 5 · BTS FED DBC"
}
const NOTES := {
	"school_tne_panel": ["Panneau de câblage · 2TNE", "Les platines verticales permettent de repérer les composants, préparer les connexions et lire un schéma. Les postes sont séparés par des cloisons techniques, comme dans l’atelier du lycée."],
	"school_tne_bench": ["Établi de préparation", "Le grand plan de travail accueille les outils, les composants et les appareils de mesure. Les tiroirs voisins servent à classer les petites pièces avant une manipulation."],
	"school_meeting_board": ["Salle de réunion · tableau", "Un espace pour expliquer un montage, préparer un projet ou présenter les résultats d’une équipe. Les tables regroupées et les fenêtres hautes reprennent l’organisation de la salle observée."],
	"school_meeting_table": ["Table de projet", "Installez vos documents, échangez vos idées et préparez le travail en atelier. Cette salle complète les espaces pratiques du lycée."],
	"school_fed_panel": ["BTS FED DBC · régulation", "Les armoires et bancs pédagogiques servent à observer la commande des équipements du bâtiment. Repérez les voyants, les organes de commande et les instruments avant d’étudier une installation."],
	"school_fed_hydraulic": ["Banc thermique et hydraulique", "Réservoir, canalisations, circulateur et instruments de mesure : un ensemble pédagogique pour comprendre la circulation d’un fluide et la régulation. La zone de travail reste dégagée autour du banc."],
	"school_industrial": ["Atelier CIEL · systèmes", "Le grand atelier regroupe les boxes techniques, les établis et les équipements pédagogiques sous une charpente métallique. L’allée bleue permet de circuler entre les différents postes."],
	"school_cyber_bench": ["CIEL · banc de mesure", "La salle informatique communique avec une petite zone de manipulation : appareils de mesure, platine technique et rangements. Les postes informatiques restent accessibles pour les activités du lycée."]
}
static func extent(zone: String) -> Vector2:
	return {"school_workshop":Vector2(2600,1800),"school_tne":Vector2(2400,1600),"school_meeting":Vector2(1800,1300),"school_fed":Vector2(2400,1700)}.get(zone,Vector2(2000,1400))
static func entry(zone: String) -> Vector2:
	var size := extent(zone)
	return Vector2(size.x/2,size.y-200)
static func prop(kind: String, x: float, y: float, width: float, depth: float) -> Dictionary:
	return {"kind":kind,"rect":Rect2(x,y,width,depth)}
static func furniture(zone: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	match zone:
		"school_tne":
			for x in [260,980,1700]:
				items.append(prop("training_panel",x,290,420,90))
				items.append(prop("tools_bench",x,650,440,150))
				items.append(prop("stool",x+40,850,48,42))
			items.append(prop("parts_cabinet",1740,1120,360,100))
			items.append(prop("electronics",260,1120,420,150))
		"school_meeting":
			items.append(prop("meeting_board",570,150,650,30))
			items.append(prop("cyber_desk",170,380,320,110))
			items.append(prop("chair",210,525,70,40))
			items.append(prop("bookcase",160,850,280,90))
			for x in [670,1190]:
				for y in [470,800]:
					items.append(prop("meeting_table",x,y,300,140))
					for dx in [30,190]: items.append(prop("chair",x+dx,y+175,70,40))
		"school_fed":
			for x in [230,970,1710]: items.append(prop("regulation_panel",x,310,420,110))
			items.append(prop("hydraulic_bench",1700,770,420,180))
			items.append(prop("tools_bench",230,720,440,150))
			items.append(prop("cyber_desk",230,1160,320,110))
			items.append(prop("meeting_table",920,1110,420,160))
			for x in [950,1180]: items.append(prop("chair",x,1310,70,40))
			items.append(prop("parts_cabinet",1770,1220,360,100))
	return items
static func extras(zone: String) -> Array[Dictionary]:
	if zone=="school_workshop": return [prop("mezzanine",210,130,1220,80),prop("training_panel",1810,340,420,90),prop("regulation_panel",1810,800,420,110),prop("parts_cabinet",240,1320,360,100),prop("steel_column",2320,550,48,48),prop("steel_column",2320,1180,48,48)]
	if zone=="school_cyber": return [prop("measurement_bench",1690,590,210,110),prop("parts_cabinet",1650,850,250,80)]
	return []
static func walls(zone: String) -> Array[Rect2]:
	if zone=="school_tne": return [Rect2(730,185,20,330),Rect2(1450,185,20,330)]
	if zone=="school_fed": return [Rect2(730,185,22,370),Rect2(1470,185,22,370)]
	if zone=="school_cyber": return [Rect2(1605,440,18,500)]
	return []
static func targets(zone: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var data: Array = {
		"school_tne":[["school_tne_panel","Platines · câblage",Vector2(470,500)],["school_tne_bench","Établi · outils et composants",Vector2(1200,900)]],
		"school_meeting":[["school_meeting_board","Tableau · préparation de projet",Vector2(880,290)],["school_meeting_table","Table · travail en groupe",Vector2(1090,700)]],
		"school_fed":[["school_fed_panel","Armoire · régulation",Vector2(1180,550)],["school_fed_hydraulic","Banc · thermique et hydraulique",Vector2(1910,1060)]],
		"school_workshop":[["school_industrial","Boxes · systèmes techniques",Vector2(2020,570)]],
		"school_cyber":[["school_cyber_bench","Banc · instruments de mesure",Vector2(1790,790)]]
	}.get(zone,[])
	if zone in NEW_IDS: data.append(["school_passage_return","Porte · couloir des ateliers",entry(zone)+Vector2(0,70)])
	for item in data: result.append({"id":item[0],"label":item[1],"at":item[2],"radius":95.0})
	return result
