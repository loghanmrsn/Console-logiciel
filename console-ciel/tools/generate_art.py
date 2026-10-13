#!/usr/bin/env python3
"""Ressources vectorielles originales Console CIEL, CC0. Aucune dépendance réseau."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1] / 'assets/art'
def svg(folder, name, width, height, body):
    target = ROOT / folder / (name + '.svg')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{body}</svg>\n')
def paint(color):
    # Godot's SVG importer does not accept the CSS 8-digit hex alpha notation.
    if color.startswith('#') and len(color)==9:
        return f'fill="{color[:7]}" fill-opacity="{int(color[7:],16)/255:.4f}"'
    return f'fill="{color}"'
def rect(x,y,w,h,fill,rx=0,stroke=None):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" {paint(fill)}'+(f' stroke="{stroke}" stroke-width="1.5"' if stroke else '')+'/>'
def line(x,y,a,b,color='#647E80',width=2):
    return f'<path d="M{x} {y} L{a} {b}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round"/>'
def circle(x,y,r,fill): return f'<circle cx="{x}" cy="{y}" r="{r}" {paint(fill)}/>'
def ellipse(x,y,rx,ry,fill): return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" {paint(fill)}/>'
# Calm, lightly textured ceramic workshop and parquet office. Furniture stays separate.
body = rect(44,50,912,426,'#DEDCD2')
# SVG patterns are deliberately avoided: draw the quiet tile / plank geometry.
for x in range(44,619,48):
 for y in range(50,476,48):
  w=min(47,619-x);h=min(47,476-y)
  body+=rect(x,y,w,h,'#E4E3DB')+rect(x+2,y+2,max(0,w-4),max(0,h-4),'#E9E8E0',2)
for y in range(50,476,36):
 for x in range(639,956,72):
  w=min(71,956-x);h=min(35,476-y)
  body+=rect(x,y,w,h,'#E5D4B9')+line(x+6,y+10,x+w-6,y+10,'#DECBAE',1)
body+=rect(644,268,19,128,'#CDBDA2')+rect(73,392,154,64,'#B9C4B7',10)
for x in range(80,221,8):body+=line(x,399,x,449,'#AAB7AB',1)
svg('world','floor',1000,520,body)
# Walls have a top cap, a front face and restrained shadows, not a technical outline.
b=''
for x,y,w,h in [(24,30,952,20),(24,476,952,20),(24,50,20,426),(956,50,20,426),(619,50,20,226),(619,388,20,88)]:
    b+=rect(x+3,y+7,w,h,'#344B4A20',4)+rect(x,y,w,h,'#8A9C97',3)+rect(x,y,w,max(6,h-6),'#C9D3CB',3)+line(x+3,y+3,x+w-3,y+3,'#E6EBE3',2)
b+=rect(105,463,100,13,'#AE9D80',3)+line(110,466,200,466,'#F3E8D2',2)
svg('world','walls',1000,520,b)
# Electrical panel with hinges, breakers and a clearly fictitious low-voltage symbol.
for state in ['off','on']:
 b=ellipse(55,80,47,8,'#344B4A22')+rect(10,9,90,62,'#687D78',7)+rect(10,7,90,55,'#BBCAC5',7,'#718783')+rect(17,14,76,42,'#DEE6DF',4)+rect(24,20,39,28,'#8B9E9B',4)
 for x in [29,39,49]:b+=rect(x,25,6,15,'#F3F2E8',2)+line(x+1,30,x+5,30,'#768B87',2)
 b+=circle(79,28,5,'#91B49A' if state=='on' else '#BDA891')+rect(72,40,15,6,'#A6B8B3',2)+line(98,20,98,29)+line(98,46,98,54)
 b+='<path d="M43 50 l-5 7 h7 l-3 6" fill="none" stroke="#657B74" stroke-width="2"/>'
 svg('world','electrical_'+state,110,90,b)
# Workbench, tools, timber edge and legs.
b=ellipse(86,76,75,9,'#344B4A22')+rect(11,14,146,54,'#AA9578',6)+rect(11,9,146,48,'#DCC6A0',6,'#9D896E')+line(16,52,152,52,'#BAA17C',3)+rect(22,19,49,25,'#92ACA5',3)
b+=line(33,31,55,31,'#E3E9DF',3)+line(44,24,44,38,'#E3E9DF',3)+rect(97,23,22,7,'#BD8669',2)+line(118,26,135,26,'#748681',3)+rect(79,36,8,14,'#789C9A',2)+circle(83,37,4,'#B0C9C4')+rect(20,65,8,9,'#877F6E',2)+rect(140,65,8,9,'#877F6E',2)
svg('world','workbench',168,88,b)
# Storage shelf with books, a tool case and stacked boxes.
b=ellipse(42,83,35,7,'#344B4A22')+rect(10,11,64,63,'#81978B',5)+rect(13,5,58,63,'#AEC0AE',4,'#789387')+rect(18,12,48,22,'#657D72',3)+rect(20,38,44,24,'#799084',3)
for x,c in [(21,'#DEC19B'),(28,'#CFAC9B'),(35,'#90B2B0'),(42,'#E5D7B6')]:b+=rect(x,15,5,17,c,1)
b+=rect(25,43,27,16,'#D8C6A5',3)+rect(32,43,12,3,'#C0AC88',1)+line(15,35,68,35,'#DCE5D4',3)
svg('world','shelf',84,96,b)
# Desk comes with separate monitor variants (state affects the real room).
b=ellipse(100,109,90,8,'#344B4A22')+rect(14,33,172,67,'#AE8F6F',7)+rect(14,23,172,67,'#D5B58C',7,'#A38669')+line(19,86,181,86,'#E6CEAA',3)+rect(18,92,9,12,'#8B7B68',2)+rect(173,92,9,12,'#8B7B68',2)
b+=rect(104,50,26,25,'#EADFC6',2)+line(109,58,125,58,'#B6AD95',1)+line(109,64,123,64,'#B6AD95',1)+circle(141,44,10,'#71998E')+circle(141,43,6,'#E6E1CE')+rect(59,76,66,11,'#E3E6DD',3)
for x in range(64,120,6):b+=line(x,79,x,84,'#ADB9B3',1)
b+=ellipse(135,81,6,8,'#DCE2D9')
svg('world','desk',200,122,b)
for state in ['off','on']:
 b=rect(2,2,81,47,'#637D78',5)+rect(6,5,73,36,'#D5DFD5',3)+rect(9,8,67,30,'#778B8B' if state=='off' else '#BBD7C9',2)+rect(38,46,8,7,'#78908B',1)+rect(27,52,30,5,'#B7C7BE',3)
 if state=='off':b+=line(30,20,53,20,'#D6DFD7',2)+line(39,28,46,28,'#D6DFD7',2)
 else:b+=rect(13,12,23,19,'#E8EFDE',2)+rect(40,12,30,3,'#77A496',1)+rect(40,20,22,2,'#8BB3A1',1)+rect(40,27,27,2,'#8BB3A1',1)
 svg('world','monitor_'+state,85,61,b)
b=rect(4,4,28,57,'#6D817B',4)+rect(4,1,25,53,'#CBD7CE',4)+rect(9,9,15,4,'#8CA099',2)+circle(17,24,3,'#95BBA1')
for y in [34,38,42]:b+=line(10,y,23,y,'#A1B4AA',1)
svg('world','tower',36,68,b)
b=ellipse(30,62,24,7,'#344B4A25')+rect(8,7,44,18,'#708F8A',8)+rect(10,21,40,31,'#9FB7AA',10)+rect(24,48,12,12,'#718A80',3)+line(30,58,12,65,'#718A80',3)+line(30,58,48,65,'#718A80',3)
svg('world','chair',60,74,b)
b=ellipse(69,75,60,7,'#344B4A22')+rect(9,17,114,47,'#8FA48F',5)+rect(9,9,114,45,'#C3CDB6',5,'#829780')+line(64,13,64,51,'#96AA90',2)+circle(57,33,2,'#7C9178')+circle(71,33,2,'#7C9178')+rect(19,1,32,11,'#C9AD86',3)
svg('world','cabinet',132,86,b)
# Fictive badge reader and gate: no real access-control instructions.
for state in ['off','on']:
 b=rect(3,5,23,38,'#738E89',4)+rect(2,1,23,36,'#E0E5DA',4)+circle(13,9,3,'#8FB29A' if state=='on' else '#C2AD8D')+rect(7,17,12,11,'#99ACA4',2)+line(10,21,16,21,'#DEE9DE',1)
 svg('world','reader_'+state,30,49,b)
b=rect(3,0,20,112,'#8D9D95',3)+rect(4,3,15,105,'#C1AE8F',3)+line(17,12,17,99,'#E7D3AF',2)+rect(12,52,4,16,'#718780',2)
svg('world','door_closed',28,120,b)
b=rect(0,0,112,20,'#8D9D95',3)+rect(3,3,106,14,'#C1AE8F',3)+line(12,5,98,5,'#E7D3AF',2)+rect(52,9,16,4,'#718780',2)
svg('world','door_open',120,28,b)
b=rect(2,4,166,18,'#D9DED0',8)+rect(8,7,154,8,'#F3ECD0',4)+line(14,17,154,17,'#BAC5B5',2)
svg('world','light',172,28,b)
b=ellipse(25,47,20,5,'#344B4A20')+rect(15,26,20,20,'#B8947B',5)+ellipse(25,26,12,5,'#C9AA8D')
for x,y,r in [(19,19,10),(30,16,11),(25,8,8)]:b+=circle(x,y,r,'#7E9C78')
b+=line(25,12,25,30,'#6F8D69',2)
svg('world','plant',50,55,b)
b=rect(2,4,64,40,'#6A827F20',4)+rect(0,0,64,40,'#F2E9CA',4,'#B8AA87')+rect(5,5,54,30,'#EEE3C2',2)
for y,w in [(12,42),(19,36),(26,27)]:b+=line(10,y,10+w,y,'#B5AA8D',2)
svg('world','note',70,48,b)
# Character: 4 directions, idle plus two walking poses. The origin is at the feet.
for direction in ['down','up','left','right']:
 for pose in range(3):
  step=0 if pose==0 else (3 if pose==1 else -3)
  b=ellipse(32,62,14,5,'#304B4930')
  b+=rect(22,45+step,9,15,'#465F63',4)+rect(33,45-step,9,15,'#465F63',4)+rect(21,56+step,11,6,'#314A51',3)+rect(32,56-step,11,6,'#314A51',3)
  b+=rect(18,29,28,24,'#557E92',9,'#426676')+rect(14,33-step/2,8,17,'#D7B496',4)+rect(42,33+step/2,8,17,'#D7B496',4)
  b+=line(31,33,31,49,'#AAC6C5',2)+rect(36,37,6,5,'#86A9B0',1)+ellipse(32,24,14,14,'#DDBDA0')
  if direction=='up':b+=ellipse(32,22,15,14,'#695A4D')+ellipse(32,17,12,9,'#776655')
  elif direction=='down':
   b+='<path d="M18 23 Q16 7 32 8 Q48 7 46 22 L39 18 L29 19 L23 23 Z" fill="#695A4D"/>'
   b+=circle(26,26,1.5,'#36494B')+circle(38,26,1.5,'#36494B')+line(29,32,35,32,'#AB8D74',1.5)
  else:
   left=direction=='left';b+='<path d="M18 24 Q16 8 32 8 Q48 8 46 28 L39 26 L38 18 L24 18 L23 26 Z" fill="#695A4D"/>'
   b+=circle(23 if left else 41,26,1.8,'#36494B')+ellipse(18 if left else 46,29,3,4,'#DDBDA0')
  svg('character',direction+'_'+str(pose),64,72,b)
# Original single-line symbols for the 5 menu destinations.
icons={'home':'M4 11 L12 4 L20 11 M6 10 V20 H18 V10 M10 20 V14 H14 V20','shop':'M5 8 H19 L20 20 H4 Z M9 8 V6 A3 3 0 0 1 15 6 V8','profiles':'M15 7 A3 3 0 1 1 9 7 A3 3 0 1 1 15 7 M5 20 V17 Q5 12 12 12 Q19 12 19 17 V20','settings':'M4 7 H20 M4 17 H20 M8 4 V10 M16 14 V20','help':'M12 21 A9 9 0 1 1 12 3 A9 9 0 1 1 12 21 M9 9 Q9 6 12 6 Q16 6 15 10 Q15 11 12 12 V14 M12 17 V18'}
for name,path in icons.items(): svg('icons',name,32,32,f'<g transform="translate(4 4)" fill="none" stroke="#426676" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="{path}"/></g>')
print('Ressources CC0 créées :',len(list(ROOT.rglob('*.svg'))))
