#!/usr/bin/env python3
"""Inventory and validate project source formats and native GDScript syntax.

No user data is used. Godot and any Python compile output use temporary homes.
The generated inventory distinguishes original sources, third-party licenses,
metadata and binary resources; it does not claim graphical or hardware checks.
"""
import argparse
import ast
from collections import Counter
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import wave

ROOT=Path(__file__).resolve().parents[1]
FOLDERS=('scripts','scenes','themes','data','tools','tests','assets','docs')
ROOT_FILES=('project.godot','export_presets.cfg','default_bus_layout.tres','README.md','.gitignore')
TEXT_EXTS={'.gd','.py','.sh','.tscn','.tres','.json','.md','.txt','.uid','.import','.cfg','.godot','.svg'}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--log-dir',type=Path,default=Path('tests/audit_results/static'))
    parser.add_argument('--godot',default=shutil.which('godot') or 'godot')
    args=parser.parse_args();logs=(ROOT/args.log_dir).resolve();logs.mkdir(parents=True,exist_ok=True)
    errors=[];files=[ROOT/x for x in ROOT_FILES]
    for folder in FOLDERS:
        files.extend(p for p in (ROOT/folder).rglob('*') if p.is_file() and p.suffix!='.log' and not any(x in p.parts for x in ('__pycache__','audit_results','release_results','stability_results')))
    records=[];uids={};references=[];links=0
    for path in sorted(set(files)):
        name=path.relative_to(ROOT).as_posix();ext=path.suffix
        kind='third_party_license' if name.startswith('assets/licenses/') else ('metadata' if ext in ('.uid','.import') else ('source' if ext in TEXT_EXTS or path.name=='.gitignore' else 'binary_resource'))
        record={'file':name,'category':kind,'checks':[]}
        if ext=='.py': tree=ast.parse(path.read_text(),filename=name);compile(tree,name,'exec');record['checks'].append('Python AST et compilation')
        elif ext=='.sh':
            result=subprocess.run(['bash','-n',str(path)],text=True,capture_output=True)
            if result.returncode: errors.append(name+': '+result.stderr)
            record['checks'].append('bash -n')
        elif ext=='.json': json.loads(path.read_text());record['checks'].append('JSON')
        elif ext=='.uid':
            value=path.read_text().strip()
            if not re.fullmatch('uid://[a-z0-9]+',value) or value in uids or not path.with_suffix('').exists(): errors.append('UID absent, dupliqué ou orphelin : '+name)
            uids[value]=name;record['checks'].append('UID unique et source présente')
        elif ext=='.wav':
            with wave.open(str(path),'rb') as resource: record['wav']={'frames':resource.getnframes(),'rate':resource.getframerate(),'channels':resource.getnchannels()}
            record['checks'].append('Présence et en-tête WAV, pas écoute')
        if kind!='binary_resource':
            text=path.read_text()
            if ext in ('.gd','.tscn','.tres','.godot','.cfg'):
                for value in re.findall(r'''["'](res://[^"'\n]+)["']''',text):
                    # Variable formats/directory prefixes need runtime validation.
                    if any(token in value for token in ('%', '*','{')): continue
                    target=ROOT/value[6:];references.append({'from':name,'to':value})
                    if not target.exists():
                        if value in ('res://docs/screenshots','res://docs/screenshots/','res://builds/demo-runtime'):
                            record['checks'].append('Dossier de sortie créé à l’exécution : '+value)
                        else: errors.append('Référence absente/casse incorrecte : '+name+' -> '+value)
                record['checks'].append('Chemins res:// littéraux exacts')
            if ext=='.md':
                for value in re.findall(r'\]\(([^)]+)\)',text):
                    if '://' in value or value.startswith('#'): continue
                    target=value.split('#')[0]
                    if target and not (path.parent/target).exists(): errors.append('Lien absent : '+name+' -> '+target)
                    links+=1
                record['checks'].append('Liens Markdown locaux')
        records.append(record)
    with tempfile.TemporaryDirectory(prefix='ciel-static-audit-') as temporary:
        environment=dict(os.environ)
        for key,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
            environment[key]=str(Path(temporary)/folder);Path(environment[key]).mkdir()
        version=subprocess.check_output([args.godot,'--version'],env=environment,text=True).strip()
        if not version.startswith('4.6.3.stable.'): errors.append('Version incompatible '+version)
        result=subprocess.run([args.godot,'--headless','--path',str(ROOT),'--script','res://tests/audit_resources.gd'],env=environment,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
        (logs/'godot-project-context.log').write_text(result.stdout)
        if result.returncode or re.search('SCRIPT ERROR:|Parse Error:|^ERROR:',result.stdout,re.M) or not re.search(r'AUDIT_RESOURCES : \d+ assertions, 0 échec',result.stdout):
            errors.append('Compilation/chargement dans le contexte Godot du projet échoué')
        for record in records:
            if record['file'].endswith('.gd'): record['checks'].append('Compilation ResourceLoader dans le projet avec Autoloads')
    summary={'godot':version,'files':records,'counts':dict(Counter(x['category'] for x in records)),'resource_references':references,'uids':len(uids),'markdown_links':links,'shellcheck_available':bool(shutil.which('shellcheck')),'errors':errors}
    (logs/'inventory.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    print('AUDIT_STATIC :',len(records),'fichiers,',len(uids),'UID,',len(references),'références,',len(errors),'erreur(s).')
    for error in errors: print(error)
    return 1 if errors else 0

if __name__=='__main__': raise SystemExit(main())
