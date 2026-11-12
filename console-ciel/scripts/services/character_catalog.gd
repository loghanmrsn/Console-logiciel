extends RefCounted
## Original, unbranded wardrobe. Prices are virtual mission points only.
const RIG := "standard_170"
const HEIGHT_METRES := 1.70
const COLORS := {"black":"222a34","blue":"365f99","white":"e7e8e2","navy":"25364e","grey":"87939b","taupe":"68625e","cream":"cabd9e","brown":"70513e","red":"a7353d","green":"4b7663","pink":"c6849c","purple":"7764a6","yellow":"d3b14d","denim":"8eafc4"}
const COLOR_NAMES := {"black":"Noir","blue":"Bleu","white":"Blanc","navy":"Marine","grey":"Gris","taupe":"Gris cendré","cream":"Crème","brown":"Marron","red":"Rouge","green":"Vert","pink":"Rose","purple":"Violet","yellow":"Jaune","denim":"Denim clair"}
const SKIN := {"porcelain":"efd0b7","light":"dcb396","warm":"bf8965","tan":"a66f4f","brown":"7e513a","deep":"50372e"}
const HAIR_COLORS := {"black":"26211f","brown":"5b3a27","chestnut":"875b39","blonde":"d3ad62","copper":"a65c35","silver":"bfc0b6","white":"e4dfcd"}
const EYE_COLORS := {"brown":"684932","hazel":"837140","green":"587953","blue":"537f9b","grey":"8b969b"}
const LIPS := {"natural":"af796d","rose":"bb7b81","peach":"c78e78","berry":"895163","brown":"845e4e"}
const EYES := ["almond","round","soft"]
const SMILES := ["soft","wide","neutral"]
const GAITS := ["natural","loose"] # Accept the old value when reading existing saves.
const CATEGORIES := ["hair","top","trousers","headwear","socks","shoes"]
const BASIC_COLORS := ["black","blue","white"]
const ITEMS := [
	{"id":"short","slot":"hair","name":"Coupe courte","price":0},
	{"id":"sidepart","slot":"hair","name":"Raie sur le côté","price":0},
	{"id":"middlepart","slot":"hair","name":"Raie au milieu","price":0},
	{"id":"long","slot":"hair","name":"Cheveux longs lisses","price":0},
	{"id":"ponytails_mid","slot":"hair","name":"Couettes mi-longues","price":0},
	{"id":"ponytails_long","slot":"hair","name":"Couettes longues","price":0},
	{"id":"mullet","slot":"hair","name":"Mulet","price":0},
	{"id":"fringe_straight","slot":"hair","name":"Coupe casquette lisse","price":40},
	{"id":"fringe_curly","slot":"hair","name":"Coupe casquette bouclée","price":50},
	{"id":"bun_low","slot":"hair","name":"Chignon bas","price":40},
	{"id":"bun_high","slot":"hair","name":"Chignon haut","price":45},
	{"id":"buzz","slot":"hair","name":"Coupe très courte","price":30},
	{"id":"tee","slot":"top","name":"T-shirt simple","price":0},
	{"id":"sweater","slot":"top","name":"Pull ample","price":55},
	{"id":"hoodie","slot":"top","name":"Sweat à capuche ample","price":65},
	{"id":"cardigan","slot":"top","name":"Pull à col zippé","price":60},
	{"id":"regular","slot":"trousers","name":"Pantalon regular","price":0},
	{"id":"baggy","slot":"trousers","name":"Pantalon baggy","price":65},
	{"id":"balloon","slot":"trousers","name":"Pantalon ballon","price":75},
	{"id":"none","slot":"headwear","name":"Sans couvre-chef","price":0},
	{"id":"cap_denim","slot":"headwear","name":"Casquette denim","price":0},
	{"id":"cap_flat","slot":"headwear","name":"Casquette structurée à visière plate","price":60},
	{"id":"straw","slot":"headwear","name":"Chapeau de paille","price":70},
	{"id":"fedora","slot":"headwear","name":"Chapeau feutré","price":80},
	{"id":"socks","slot":"socks","name":"Chaussettes unies","price":0},
	{"id":"canvas","slot":"shoes","name":"Baskets en toile","price":0},
	{"id":"court","slot":"shoes","name":"Baskets basses en cuir","price":85},
	{"id":"boots","slot":"shoes","name":"Bottines à lacets","price":90},
	{"id":"loafers","slot":"shoes","name":"Mocassins","price":75},
	{"id":"runner","slot":"shoes","name":"Baskets de sport","price":80},
	{"id":"high","slot":"shoes","name":"Baskets montantes","price":85}
	,{"id":"madison","slot":"top","name":"Robe Madison · manches séparées","price":120}
	,{"id":"updo","slot":"hair","name":"Chignon avec mèches","price":45}
	,{"id":"tights","slot":"trousers","name":"Collants fins","price":30}
	,{"id":"heels","slot":"shoes","name":"Escarpins à brides","price":65}
]
static func item(id: String, slot: String="") -> Dictionary:
	for entry in ITEMS:
		if entry.id==id and (slot.is_empty() or entry.slot==slot): return entry.duplicate()
	return {}
static func key(slot: String,id: String) -> String: return slot+"/"+id
static func allowed_colors(slot: String,id: String) -> Array:
	if slot=="socks": return ["white","black"]
	if slot=="hair": return HAIR_COLORS.keys()
	if id=="cap_denim": return ["denim","blue","white"]
	if id=="straw": return ["cream","brown","white"]
	if id in ["tee","regular"]: return BASIC_COLORS.duplicate()
	if id=="canvas": return ["white","black"]
	return COLORS.keys()
static func defaults() -> Dictionary:
	return {"version":1,"rig":RIG,"owned":[],"appearance":{"gait":"natural","skin":"warm","hair":"short","hair_color":"brown","eyes":"almond","eye_color":"brown","smile":"soft","lips":"natural","top":"tee","top_color":"blue","trousers":"regular","trousers_color":"black","headwear":"none","headwear_color":"black","socks":"socks","socks_color":"white","shoes":"canvas","shoes_color":"white"}}
static func record(profile: Dictionary) -> Dictionary:
	var result: Dictionary=profile.get("character",defaults()).duplicate(true)
	result.appearance.gait="natural"
	return result
static func owned(record_: Dictionary, entry: Dictionary) -> bool:
	return int(entry.price)==0 or key(entry.slot,entry.id) in record_.get("owned",[])
static func valid(record_: Variant, require_ownership:=true) -> bool:
	if not record_ is Dictionary or record_.size()!=4 or record_.get("version")!=1 or record_.get("rig")!=RIG or not record_.get("owned") is Array or not record_.get("appearance") is Dictionary: return false
	var seen=[]
	for id in record_.owned:
		if not id is String or id in seen: return false
		var parts=id.split("/")
		if parts.size()!=2: return false
		var product=item(parts[1],parts[0])
		if product.is_empty() or int(product.price)==0: return false
		seen.append(id)
	var a: Dictionary=record_.appearance
	if a.size()!=defaults().appearance.size(): return false
	if a.get("gait","") not in GAITS: return false
	if a.get("skin","") not in SKIN or a.get("hair_color","") not in HAIR_COLORS or a.get("eye_color","") not in EYE_COLORS or a.get("lips","") not in LIPS or a.get("eyes","") not in EYES or a.get("smile","") not in SMILES: return false
	for slot in CATEGORIES:
		var product=item(str(a.get(slot,"")),slot)
		if product.is_empty() or (require_ownership and not owned(record_,product)): return false
		if slot!="hair" and a.get(slot+"_color","") not in allowed_colors(slot,product.id): return false
	return true

static func madison_appearance() -> Dictionary:
	var a=defaults().appearance
	a.skin="light";a.hair="updo";a.hair_color="brown";a.eye_color="hazel";a.smile="soft";a.lips="rose"
	a.top="madison";a.top_color="taupe";a.trousers="regular";a.trousers_color="black";a.shoes="heels";a.shoes_color="black";a.socks_color="black"
	return a
