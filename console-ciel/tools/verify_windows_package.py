#!/usr/bin/env python3
"""Check portable ZIP, PE x86_64 and the MD5 of every Godot 4.6 PCK entry."""
from pathlib import Path
import argparse
import hashlib
import json
import struct
import zipfile

def verify(executable: Path, archive: Path) -> dict:
    payload=executable.read_bytes()
    assert payload[:2]==b'MZ','En-tête Windows absent'
    pe=struct.unpack_from('<I',payload,0x3c)[0]
    assert payload[pe:pe+4]==b'PE\0\0','PE invalide'
    assert struct.unpack_from('<H',payload,pe+4)[0]==0x8664,'Architecture incorrecte'
    assert struct.unpack_from('<H',payload,pe+24)[0]==0x20b,'PE32+ requis'
    assert payload[-4:]==b'GDPC','Pack intégré absent'
    pack_size=struct.unpack_from('<Q',payload,len(payload)-12)[0]
    start=len(payload)-pack_size-12
    assert 0<=start<len(payload)-112 and payload[start:start+4]==b'GDPC','Emplacement PCK invalide'
    format_version,major,minor,patch,flags=struct.unpack_from('<IIIII',payload,start+4)
    assert (format_version,major,minor,patch,flags)==(3,4,6,3,2),'Format moteur / pack inattendu'
    base,directory=struct.unpack_from('<QQ',payload,start+24)
    position=start+directory
    count=struct.unpack_from('<I',payload,position)[0];position+=4
    assert 0<count<10000,'Nombre de ressources invalide'
    entries=[]
    for _ in range(count):
        length=struct.unpack_from('<I',payload,position)[0];position+=4
        assert 0<length<65536,'Nom de ressource invalide'
        name=payload[position:position+length].rstrip(b'\0').decode('utf-8');position+=length
        offset,size=struct.unpack_from('<QQ',payload,position)
        expected=payload[position+16:position+32];entry_flags=struct.unpack_from('<I',payload,position+32)[0];position+=36
        begin=start+base+offset;end=begin+size
        assert entry_flags==0 and start+112<=begin<=end<=start+directory,'Bornes ou chiffrement inattendus : '+name
        assert hashlib.md5(payload[begin:end]).digest()==expected,'Ressource altérée : '+name
        assert not name.startswith('/') and '..' not in name.split('/'),'Chemin inattendu : '+name
        assert not name.startswith(('tests/','tools/','docs/','builds/','profiles/')),'Fichier de développement / profil dans le pack'
        entries.append({'file':name,'bytes':size,'md5':expected.hex()})
    files={entry['file'] for entry in entries}
    assert len(files)==count,'Ressource dupliquée'
    art=[p for p in files if p.startswith('assets/art/') and p.endswith('.svg.import')]
    assert len(art)==36,'Collection graphique incomplète'
    for name in ['data/game_rules.json','data/shop_catalog.json','data/controller_mapping.json','project.binary']:
        assert name in files,'Ressource absente : '+name
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None,'CRC ZIP invalide'
        names=package.namelist()
        assert len(names)==len(set(names)),'Entrées dupliquées'
        for name in ['Console_CIEL.exe','LIRE_MOI.txt','assets/LICENSES.md','assets/licenses/GODOT_MIT.txt','assets/licenses/CC0.txt']:
            assert name in names,'Livraison incomplète : '+name
        assert package.read('Console_CIEL.exe')==payload,'ZIP différent du binaire vérifié'
        assert not any(n.endswith('.zip') or n.startswith(('profiles/','.godot/')) or '..' in n.split('/') for n in names),'Contenu interdit'
    return {'executable':str(executable),'architecture':'PE32+ x86_64','exe_bytes':len(payload),'exe_sha256':hashlib.sha256(payload).hexdigest(),'archive':str(archive),'zip_bytes':archive.stat().st_size,'zip_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'crc_valid':True,'archive_entries':names,'embedded_files':entries,'art_textures':len(art)}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True);parser.add_argument('--zip',type=Path,required=True);parser.add_argument('--report',type=Path)
    args=parser.parse_args();report=verify(args.exe,args.zip)
    if args.report:args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print('WINDOWS_PACKAGE : CRC valide, %d ressources intactes, %d SVG importés, %d octets ZIP.'%(len(report['embedded_files']),report['art_textures'],report['zip_bytes']))
if __name__=='__main__':main()
