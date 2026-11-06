"""Deterministic, original, seamless surface maps. No external images or provider.
R: neutral albedo variation; G: surface height; B: roughness variation.
python tools/generate_character_materials.py
"""
from pathlib import Path
import hashlib, json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/character3d/materials'
OUT.mkdir(parents=True,exist_ok=True)

def noise(size,seed):
    rng=np.random.default_rng(seed)
    y,x=np.mgrid[:size,:size]/size
    value=np.zeros((size,size))
    for frequency,weight in [(1,.10),(3,.16),(8,.23),(20,.26),(50,.25)]:
        for i in range(6):
            a,b=rng.integers(-frequency,frequency+1,2)
            value+=weight*np.sin(2*np.pi*(a*x+b*y)+rng.uniform(0,2*np.pi))/6
    return np.clip(.5+value,0,1)

records={}
for index,name in enumerate(['skin','cotton','knit','denim','leather','felt','straw','hair']):
    size=256 if name=='skin' else 128
    y,x=np.mgrid[:size,:size]/(size-1)
    grain=noise(size,3300+index)
    if name=='skin':
        # Small, irregular pores on a periodic grid, with almost neutral color.
        height=.56+.22*(grain-.5)
        rng=np.random.default_rng(333)
        for i in range(80):
            px,py=rng.random(2)
            dx=np.minimum(abs(x-px),1-abs(x-px));dy=np.minimum(abs(y-py),1-abs(y-py))
            height-=rng.uniform(.14,.31)*np.exp(-(dx*dx+dy*dy)/rng.uniform(.000015,.000045))
        color=.5+(grain-.5)*.13;rough=.55+(grain-.5)*.4
    elif name=='cotton':
        weave=np.sin(x*32*np.pi)*np.sin(y*32*np.pi)
        height=.5+weave*.20+(grain-.5)*.18;color=.5+weave*.13;rough=.62+(grain-.5)*.2
    elif name=='knit':
        stitch=np.cos(2*np.pi*(y*10+np.abs(np.sin(x*8*np.pi))*.45))
        height=.5+.32*stitch+(grain-.5)*.12;color=.5+.17*stitch;rough=.68+(grain-.5)*.2
    elif name=='denim':
        twill=np.sin(2*np.pi*(x*24+y*16));cross=np.sin(2*np.pi*y*32)
        height=.5+.20*twill+.08*cross;color=.5+.18*twill+(grain-.5)*.10;rough=.62+(grain-.5)*.3
    elif name=='leather':
        height=.5+(grain-.5)*.8;color=.5+(grain-.5)*.22;rough=.43+(grain-.5)*.6
    elif name=='felt':
        height=.5+(grain-.5)*.5;color=.5+(grain-.5)*.18;rough=.8+(grain-.5)*.2
    elif name=='straw':
        weave=np.sin(x*48*np.pi)*np.sin(y*48*np.pi)
        height=.5+.25*weave;color=.5+.20*weave;rough=.65+(grain-.5)*.2
    else:
        fibers=np.sin(2*np.pi*(x*48+.08*np.sin(y*4*np.pi)))
        height=.5+.12*fibers;color=.5+.18*fibers+(grain-.5)*.2;rough=.48+(grain-.5)*.3
    image=np.clip(np.stack([color,height,rough],axis=-1)*255,0,255).astype(np.uint8)
    # Exact boundaries make wrapping deterministic at every tile edge.
    image[-1,:,:]=image[0,:,:];image[:,-1,:]=image[:,0,:]
    path=OUT/(name+'.png');Image.fromarray(image).save(path,optimize=True)
    records[name]={'file':path.name,'size':[size,size],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seamless_edges':True}

manifest={'version':1,'license':'CC0-1.0 original procedural artwork','generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'channels':{'R':'neutral albedo detail','G':'height','B':'roughness'},'external_images_or_models':False,'textures':records,'rgba_mipmaps_bytes':sum(r['size'][0]*r['size'][1]*4*4//3 for r in records.values())}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('CHARACTER_MATERIALS:',len(records),'maps;',manifest['rgba_mipmaps_bytes'],'bytes including RGBA mipmaps')
