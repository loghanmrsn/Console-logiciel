extends RefCounted
## Deterministic water: continuous jets, falling droplets and overflowing cup.
const WATER_CENTER := Vector2(95,75)
const NOZZLE := Vector2(95,11)
static func bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return (1-t)*(1-t)*a+2*(1-t)*t*b+t*t*c
static func _stream(c: CanvasItem, a: Vector2, bend: Vector2, b: Vector2, time: float, seed: float, width: float) -> void:
	var points := PackedVector2Array()
	for i in range(25): points.append(bezier(a,bend,b,i/24.0))
	c.draw_polyline(points,Color(.36,.69,.77,.47),width+1.5,true)
	c.draw_polyline(points,Color(.77,.94,.97,.66),width,true)
	# Faster near the bottom, as droplets accelerate under gravity.
	for index in range(5):
		var phase := fposmod(time*.78+seed+index*.20,1.0)
		var t := phase*phase
		var next := minf(1,t+.045)
		c.draw_line(bezier(a,bend,b,t),bezier(a,bend,b,next),Color(.96,1,1,.78),maxf(.65,width*.55),true)
static func _ripples(c: CanvasItem, at: Vector2, time: float, seed: float) -> void:
	for ring in range(3):
		var phase := fposmod(time*.72+seed+ring/3.0,1.0)
		var points := PackedVector2Array()
		for step in range(25):
			var angle := TAU*step/24.0
			points.append(at+Vector2(cos(angle),sin(angle)*.65)*(2+phase*8))
		c.draw_polyline(points,Color(.72,.92,.97,(1-phase)*.40),.8,true)
static func draw(c: CanvasItem, rect: Rect2, time: float) -> void:
	var offset := rect.position
	# Small moving light bands stay inside the water, away from the stone rim.
	for ring in range(5):
		var radius := 12.0+ring*11
		c.draw_arc(offset+WATER_CENTER,radius,time*.12+ring, time*.12+ring+1.05,20,Color(.50,.83,.89,.12),1.2,true)
	# Five separate arcing jets from the raised nozzle.
	for index in range(5):
		var angle := PI+.35+index*(PI-.7)/4
		var landing := WATER_CENTER+Vector2(cos(angle)*51,-sin(angle)*38)
		var a := offset+NOZZLE
		var b := offset+landing
		var crest := (a+b)*.5-Vector2(0,62+sin(time*1.3+index)*1.1)
		_stream(c,a,crest,b,time,index*.17,1.5)
		_ripples(c,b,time,index*.13)
		for drop in range(3):
			var phase := fposmod(time*1.6+drop*.33+index*.11,1)
			var direction := float(drop-1)
			var position := b+Vector2(direction*phase*6,-sin(phase*PI)*6+phase*2)
			c.draw_circle(position,.7,Color(.9,.99,1,(1-phase)*.7))
	# A broken, translucent sheet over the front lip of the upper cup.
	for index in range(11):
		var angle := PI+.18+index*(PI-.36)/10
		var top := offset+Vector2(95+cos(angle)*33,33-sin(angle)*33)
		var bottom := offset+WATER_CENTER+Vector2(cos(angle)*49,-sin(angle)*45)
		var bend := top.lerp(bottom,.50)+Vector2(cos(angle)*4,-6)
		_stream(c,top,bend,bottom,time*1.22,index*.093,1.7+sin(index*2.1)*.5)
		if index%2==0: _ripples(c,bottom,time,index*.17)
