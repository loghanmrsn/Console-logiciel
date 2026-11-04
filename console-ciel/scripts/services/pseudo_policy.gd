extends RefCounted
## A local naming policy, never a source of permissions or save validity.
const DEFAULT_PATH := "res://data/pseudo_blacklist.json"
const EXTERNAL_FILENAME := "pseudo_blacklist.json"
static var rules_path_override := ""
static func _fail(message: String) -> Dictionary: return {"ok":false,"error":message}
static func _tokens(value: String) -> PackedStringArray:
	var text := ""
	for character in value:
		var code := character.unicode_at(0)
		if code in [0x200b,0x200c,0x200d,0x2060,0xfeff,0xad] or (code>=0x300 and code<=0x36f): continue
		text+=String.chr(code-0xfee0) if code>=0xff01 and code<=0xff5e else character
	text=text.to_lower()
	for pair in [["àáâäãå","a"],["èéêë","e"],["ìíîï","i"],["òóôöõ","o"],["ùúûü","u"],["ç","c"],["ñ","n"]]:
		for letter in pair[0]: text=text.replace(letter,pair[1])
	var regex := RegEx.new()
	regex.compile("[^a-z0-9]+")
	return regex.sub(text," ",true).split(" ",false)
static func _word(value: String) -> String:
	var result := value
	while not result.is_empty() and result[0].is_valid_int(): result=result.substr(1)
	while not result.is_empty() and result[-1].is_valid_int(): result=result.left(-1)
	return result
static func _rules() -> Dictionary:
	var external := OS.get_executable_path().get_base_dir().path_join(EXTERNAL_FILENAME)
	var path := rules_path_override if not rules_path_override.is_empty() else (external if FileAccess.file_exists(external) else DEFAULT_PATH)
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>32768: return _fail("La liste des pseudos interdits est indisponible. Vérifiez pseudo_blacklist.json.")
	var decoder := JSON.new()
	var error := decoder.parse(file.get_as_text())
	file.close()
	if error!=OK: return _fail("La liste des pseudos interdits est invalide. Vérifiez pseudo_blacklist.json.")
	var parsed: Variant=decoder.data
	if not parsed is Dictionary or parsed.get("version")!=1: return _fail("La liste des pseudos interdits est invalide. Vérifiez pseudo_blacklist.json.")
	for key in ["blocked_names","blocked_terms"]:
		if not parsed.get(key) is Array or parsed[key].size()>256: return _fail("La liste des pseudos interdits est invalide. Vérifiez pseudo_blacklist.json.")
		for entry in parsed[key]:
			if not entry is String or entry.length()>64 or _tokens(entry).is_empty(): return _fail("La liste des pseudos interdits contient une entrée invalide.")
	return {"ok":true,"data":parsed}
static func validate_new_name(value: String) -> Dictionary:
	var loaded := _rules()
	if not loaded.ok: return loaded
	var tokens := _tokens(value)
	var compact := "".join(tokens)
	for name in loaded.data.blocked_names:
		if _word(compact)=="".join(_tokens(name)): return _fail("Ce pseudo n’est pas autorisé. Choisissez-en un autre.")
	for term in loaded.data.blocked_terms:
		var forbidden := "".join(_tokens(term))
		if _word(compact)==forbidden: return _fail("Ce pseudo n’est pas autorisé. Choisissez-en un autre.")
		for token in tokens:
			if _word(token)==forbidden: return _fail("Ce pseudo n’est pas autorisé. Choisissez-en un autre.")
	return {"ok":true,"data":value}
