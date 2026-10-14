extends RefCounted
## Images personnelles hors ligne, sans import Godot et sans toucher à l'inventaire.
## Les sources utilisent images_profil/ ; les exports le dossier voisin de l'exécutable.

const MAX_FILE_BYTES := 8 * 1024 * 1024
const MAX_IMAGE_EDGE := 4096
const MAX_IMAGE_PIXELS := 16 * 1024 * 1024
const MAX_LIBRARY_IMAGES := 128
const THUMBNAIL_EDGE := 256
const EXTENSIONS := ["png", "jpg", "jpeg", "webp"]

# Les tests utilisent exclusivement leurs répertoires temporaires isolés.
static var directories_override: Array[String] = []
static var _cache: Dictionary = {}


static func folder_path() -> String:
	if not directories_override.is_empty():
		return directories_override[0]
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://images_profil")
	return OS.get_executable_path().get_base_dir().path_join("images_profil")


static func is_safe_filename(value: Variant) -> bool:
	if not value is String:
		return false
	var filename: String = value
	if filename.is_empty() or filename.to_utf8_buffer().size() > 255 or filename != filename.strip_edges() or filename.begins_with(".") or filename.ends_with("."):
		return false
	if filename.get_extension().to_lower() not in EXTENSIONS:
		return false
	for character in filename:
		var code := character.unicode_at(0)
		if code < 32 or (code >= 127 and code <= 159) or character in ['<', '>', ':', '"', '/', '\\', '|', '?', '*']:
			return false
	var stem := filename.split(".")[0].to_lower()
	# Ces noms ne désignent pas un fichier ordinaire sous Windows.
	if stem in ["con", "prn", "aux", "nul"]:
		return false
	if stem.length() == 4 and (stem.begins_with("com") or stem.begins_with("lpt")) and stem[3] in "123456789":
		return false
	return true


static func refresh() -> void:
	_cache.clear()


static func _directories() -> Array[String]:
	if not directories_override.is_empty():
		return directories_override.duplicate()
	return [folder_path()]


static func list_images() -> Array[Dictionary]:
	var images: Array[Dictionary] = []
	var seen: Dictionary = {}
	for directory_path in _directories():
		var directory := _open_directory(directory_path)
		if directory == null:
			continue
		var filenames := directory.get_files()
		filenames.sort()
		for filename in filenames:
			if seen.has(filename) or not is_safe_filename(filename) or directory.is_link(filename):
				continue
			var texture := _load_texture(directory_path, filename)
			if texture == null:
				continue
			seen[filename] = true
			images.append({"filename": filename, "name": filename.get_basename().replace("_", " "), "texture": texture})
			if images.size() >= MAX_LIBRARY_IMAGES:
				return images
	return images


static func texture_for(filename: String) -> Texture2D:
	if not is_safe_filename(filename):
		return null
	for directory_path in _directories():
		var texture := _load_texture(directory_path, filename)
		if texture != null:
			return texture
	return null


static func _load_texture(directory_path: String, filename: String) -> Texture2D:
	var directory := _open_directory(directory_path)
	if directory == null or directory.is_link(filename) or not directory.file_exists(filename):
		_cache.erase(directory_path.path_join(filename))
		return null
	var path := directory_path.path_join(filename)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_cache.erase(path)
		return null
	var length := file.get_length()
	var modified := FileAccess.get_modified_time(path)
	if length <= 0 or length > MAX_FILE_BYTES:
		file.close()
		_cache.erase(path)
		return null
	if _cache.has(path) and _cache[path].length == length and _cache[path].modified == modified:
		file.close()
		return _cache[path].texture
	var data := file.get_buffer(length)
	var read_error := file.get_error()
	file.close()
	if data.size() != length or read_error != OK:
		return null
	var extension := filename.get_extension().to_lower()
	var dimensions := _dimensions(data, extension)
	if dimensions.x < 1 or dimensions.y < 1 or dimensions.x > MAX_IMAGE_EDGE or dimensions.y > MAX_IMAGE_EDGE or dimensions.x * dimensions.y > MAX_IMAGE_PIXELS:
		_cache_result(path, length, modified, null)
		return null
	var image := Image.new()
	var result: Error
	match extension:
		"png": result = image.load_png_from_buffer(data)
		"jpg", "jpeg": result = image.load_jpg_from_buffer(data)
		"webp": result = image.load_webp_from_buffer(data)
		_: return null
	if result != OK or image.is_empty() or image.get_width() != dimensions.x or image.get_height() != dimensions.y:
		_cache_result(path, length, modified, null)
		return null
	if maxi(dimensions.x, dimensions.y) > THUMBNAIL_EDGE:
		var ratio := float(THUMBNAIL_EDGE) / float(maxi(dimensions.x, dimensions.y))
		image.resize(maxi(1, int(round(dimensions.x * ratio))), maxi(1, int(round(dimensions.y * ratio))), Image.INTERPOLATE_LANCZOS)
	var texture := ImageTexture.create_from_image(image)
	_cache_result(path, length, modified, texture)
	return texture


static func _open_directory(directory_path: String) -> DirAccess:
	var absolute := ProjectSettings.globalize_path(directory_path).trim_suffix("/")
	var parent := DirAccess.open(absolute.get_base_dir())
	if parent == null or parent.is_link(absolute.get_file()):
		return null
	return DirAccess.open(absolute)


static func _cache_result(path: String, length: int, modified: int, texture: Texture2D) -> void:
	if not _cache.has(path) and _cache.size() >= MAX_LIBRARY_IMAGES:
		_cache.erase(_cache.keys()[0])
	_cache[path] = {"length": length, "modified": modified, "texture": texture}


static func _u16_be(data: PackedByteArray, offset: int) -> int:
	return (int(data[offset]) << 8) | int(data[offset + 1])


static func _u32_be(data: PackedByteArray, offset: int) -> int:
	return (int(data[offset]) << 24) | (int(data[offset + 1]) << 16) | (int(data[offset + 2]) << 8) | int(data[offset + 3])


static func _dimensions(data: PackedByteArray, extension: String) -> Vector2i:
	# Lire les dimensions avant le décodage évite de charger une image démesurée.
	if extension == "png":
		if data.size() < 33 or data.slice(0, 8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]) or data.slice(12, 16).get_string_from_ascii() != "IHDR":
			return Vector2i.ZERO
		return Vector2i(_u32_be(data, 16), _u32_be(data, 20))
	if extension in ["jpg", "jpeg"]:
		if data.size() < 4 or data[0] != 255 or data[1] != 216:
			return Vector2i.ZERO
		var position := 2
		while position + 3 < data.size():
			if data[position] != 255:
				return Vector2i.ZERO
			while position < data.size() and data[position] == 255:
				position += 1
			if position >= data.size():
				return Vector2i.ZERO
			var marker := int(data[position])
			position += 1
			if marker == 217 or marker == 218:
				return Vector2i.ZERO
			if marker == 1 or marker == 216 or (marker >= 208 and marker <= 215):
				continue
			if position + 2 > data.size():
				return Vector2i.ZERO
			var segment_size := _u16_be(data, position)
			if segment_size < 2 or position + segment_size > data.size():
				return Vector2i.ZERO
			if marker in [192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207] and segment_size >= 7:
				return Vector2i(_u16_be(data, position + 5), _u16_be(data, position + 3))
			position += segment_size
		return Vector2i.ZERO
	if extension == "webp":
		if data.size() < 20 or data.slice(0, 4).get_string_from_ascii() != "RIFF" or data.slice(8, 12).get_string_from_ascii() != "WEBP":
			return Vector2i.ZERO
		var position := 12
		while position + 8 <= data.size():
			var chunk := data.slice(position, position + 4).get_string_from_ascii()
			var chunk_size := int(data.decode_u32(position + 4))
			var start := position + 8
			if chunk_size < 0 or start + chunk_size > data.size():
				return Vector2i.ZERO
			if chunk == "VP8X" and chunk_size >= 10:
				return Vector2i(1 + int(data[start + 4]) + (int(data[start + 5]) << 8) + (int(data[start + 6]) << 16), 1 + int(data[start + 7]) + (int(data[start + 8]) << 8) + (int(data[start + 9]) << 16))
			if chunk == "VP8 " and chunk_size >= 10 and data[start + 3] == 157 and data[start + 4] == 1 and data[start + 5] == 42:
				return Vector2i(int(data.decode_u16(start + 6)) & 16383, int(data.decode_u16(start + 8)) & 16383)
			if chunk == "VP8L" and chunk_size >= 5 and data[start] == 47:
				var bits := int(data.decode_u32(start + 1))
				return Vector2i(1 + (bits & 16383), 1 + ((bits >> 14) & 16383))
			position = start + chunk_size + (chunk_size & 1)
	return Vector2i.ZERO
