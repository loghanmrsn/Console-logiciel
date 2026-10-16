extends Node2D
## Décor original dessiné avec la grille physique, sans image externe.
const Layout = preload("res://scripts/game/maze_layout.gd")
var completed := false:
	set(value):
		completed = value
		queue_redraw()

func _draw() -> void:
	var tile: float = Layout.TILE
	draw_rect(Rect2(Vector2.ZERO, Layout.extent()), Color("dce6e3"))
	for y in range(Layout.GRID.size()):
		for x in range(Layout.GRID[y].length()):
			var rect := Rect2(Vector2(x,y) * tile, Vector2.ONE * tile)
			if Layout.GRID[y][x] == "#":
				draw_rect(rect, Color("69868a"))
				draw_rect(Rect2(rect.position, Vector2(tile,8)), Color("9bb6b8"))
				draw_rect(Rect2(rect.position + Vector2(0,tile-9), Vector2(tile,9)), Color("567176"))
				draw_rect(rect.grow(-5), Color("759296"), false, 1)
			else:
				draw_rect(rect.grow(-3), Color("d2dfdb") if (x+y)%2 == 0 else Color("dce6e3"))
	var font := ThemeDB.fallback_font
	for note in Layout.NOTES:
		var origin: Vector2 = Layout.at(note.wall) - Vector2(42,29)
		draw_rect(Rect2(origin + Vector2(2,3),Vector2(84,58)),Color(0,0,0,.13))
		draw_rect(Rect2(origin,Vector2(84,58)),Color("f1e8c9"))
		draw_rect(Rect2(origin,Vector2(84,5)),Color("b89967"))
		draw_string(font,origin+Vector2(5,23),str(note.title),HORIZONTAL_ALIGNMENT_LEFT,76,10,Color("675d49"))
		draw_string(font,origin+Vector2(5,44),str(note.short),HORIZONTAL_ALIGNMENT_LEFT,76,12,Color("374e50"))
	var portal: Vector2 = Layout.at(Layout.START)
	draw_circle(portal,30,Color("c2d7ce"))
	draw_arc(portal,28,0,TAU,32,Color("658d83"),3,true)
	draw_string(font,portal+Vector2(-24,5),"RETOUR",HORIZONTAL_ALIGNMENT_LEFT,60,11,Color("486d62"))
