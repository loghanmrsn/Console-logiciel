#!/usr/bin/env python3
"""Regressions for source packaging and command wrappers, using disposable stubs."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from zipfile import ZipFile

PROJECT = Path(__file__).resolve().parents[1]
COUNT = 0

def check(ok, message):
    global COUNT
    COUNT += 1
    if not ok: raise AssertionError(message)
    print('OK ' + message)

def check_profile_packages(project, base):
    """Verify delivery contents with inert, temporary binary fixtures only."""
    (project/'project.godot').write_text('config/version="0.4.2"\n', encoding='utf-8')
    pictures=project/'images_profil'
    pictures.mkdir(exist_ok=True)
    (pictures/'.gdignore').write_bytes(b'')
    (pictures/'LIRE_MOI.txt').write_text('Images locales de test ; fichiers externes au PCK.\n', encoding='utf-8')
    image_bytes=b'LOCAL IMAGE PACKAGING FIXTURE, NOT A DECODED IMAGE\n'
    (pictures/'portrait personnel.png').write_bytes(image_bytes)
    selected_relative='builds/releases/windows-x86_64-profils-0.4.2'
    selected=project/selected_relative
    old=project/'builds/windows-x86_64-navigation-0.4.1'
    for directory, content in ((selected, b'INERT CURRENT BINARY FIXTURE\n'), (old, b'INERT PREVIOUS BINARY FIXTURE\n')):
        (directory/'assets/licenses').mkdir(parents=True)
        # Packaging preserves existing bytes; these are deliberately not PE files.
        (directory/'Console_CIEL.exe').write_bytes(content)
        (directory/'LIRE_MOI.txt').write_text('Livraison temporaire de test.\n', encoding='utf-8')
        (directory/'assets/LICENSES.md').write_text('Fixture licences.\n', encoding='utf-8')
        (directory/'assets/licenses/GODOT_MIT.txt').write_text('Fixture Godot licence.\n', encoding='utf-8')
    shutil.copytree(pictures, selected/'images_profil')
    binary_before={path: path.read_bytes() for path in (selected/'Console_CIEL.exe', old/'Console_CIEL.exe')}

    spec=importlib.util.spec_from_file_location('complete_package_fixture', project/'tools/package_complete.py')
    complete=importlib.util.module_from_spec(spec); spec.loader.exec_module(complete)
    current_output=base/'current-delivery.zip'
    report=complete.create_archive(project, current_output, selected_relative, current_windows_only=True)
    selected_prefix='console-ciel/'+selected_relative+'/'
    old_prefix='console-ciel/builds/windows-x86_64-navigation-0.4.1/'
    with ZipFile(current_output) as archive:
        names=set(archive.namelist())
        check(archive.testzip() is None and report['crc_valid'] and report['all_source_hashes_verified'], 'Livraison courante : CRC et empreintes source vérifiés')
        check(archive.read(selected_prefix+'Console_CIEL.exe')==binary_before[selected/'Console_CIEL.exe'], 'Livraison courante : binaire sélectionné préservé avec chemin imbriqué')
        for prefix in ('console-ciel/images_profil/', selected_prefix+'images_profil/'):
            check({prefix+'.gdignore', prefix+'LIRE_MOI.txt', prefix+'portrait personnel.png'}.issubset(names)
                  and archive.read(prefix+'portrait personnel.png')==image_bytes,
                  'Livraison courante : dossier local, notice, .gdignore et image inclus dans '+prefix)
        check(not any(name.startswith(old_prefix) for name in names), 'Livraison courante : ancien dossier binaire exclu de l’archive')
        manifest=json.loads(archive.read('console-ciel/CONTENU_ARCHIVE.json'))
        check(manifest['latest_windows_directory']==selected_relative
              and any(item['path']=='builds/windows-x86_64-navigation-0.4.1/' for item in manifest['excluded'])
              and any('conservés séparément' in note for note in manifest['notes']),
              'Livraison courante : manifeste indique la sélection et la conservation séparée')
    check(all(path.read_bytes()==content for path, content in binary_before.items()), 'Livraison courante : nouveaux et anciens binaires restent intacts sur disque')

    default_output=base/'default-delivery.zip'
    default_report=complete.create_archive(project, default_output, selected_relative)
    with ZipFile(default_output) as archive:
        check(archive.testzip() is None
              and archive.read(old_prefix+'Console_CIEL.exe')==binary_before[old/'Console_CIEL.exe']
              and archive.read(selected_prefix+'Console_CIEL.exe')==binary_before[selected/'Console_CIEL.exe'],
              'Mode par défaut : ancien et nouveau binaire toujours inclus')
    check(not any(item['path']=='builds/windows-x86_64-navigation-0.4.1/' for item in default_report['excluded'])
          and all(path.read_bytes()==content for path, content in binary_before.items()),
          'Mode par défaut : conservation sur disque et ancien comportement préservés')

    spec=importlib.util.spec_from_file_location('source_package_fixture', project/'tools/package_source.py')
    source=importlib.util.module_from_spec(spec); spec.loader.exec_module(source)
    source_output=base/'profile-source.zip'
    source.create_archive(project, source_output)
    with ZipFile(source_output) as archive:
        names=set(archive.namelist())
        check({'console-ciel/images_profil/'+name for name in ('.gdignore', 'LIRE_MOI.txt', 'portrait personnel.png')}.issubset(names)
              and archive.read('console-ciel/images_profil/portrait personnel.png')==image_bytes,
              'Archive source : dossier images_profil et images personnelles locales inclus')
        check(archive.testzip() is None and not any(name.startswith('console-ciel/builds/') for name in names),
              'Archive source : CRC valide et livraisons binaires exclues')

def run():
    with tempfile.TemporaryDirectory(prefix='ciel-audit-tools-') as temporary:
        base=Path(temporary)
        project=base/'project with spaces'
        shutil.copytree(PROJECT/'tools',project/'tools',ignore=shutil.ignore_patterns('__pycache__'))
        for folder in ('scenes','scripts','assets','themes','data','tests','docs','images_profil'): (project/folder).mkdir()
        for name in ('project.godot','default_bus_layout.tres','export_presets.cfg','README.md','.gitignore'): (project/name).write_text('fixture')
        spec=importlib.util.spec_from_file_location('package',project/'tools/package_source.py')
        package=importlib.util.module_from_spec(spec);spec.loader.exec_module(package)
        out=project/'builds/source.zip'
        package.create_archive(project,out)
        with ZipFile(out) as archive: check(archive.testzip() is None,'Archive normale valide')
        before=out.read_bytes()
        external=base/'private.json';external.write_text('protected test data')
        link=project/'data/linked.json';link.symlink_to(external)
        try: package.create_archive(project,out)
        except ValueError: pass
        else: raise AssertionError('Symlink accepted')
        check(out.read_bytes()==before and external.read_text()=='protected test data','Lien source refusé, archive précédente et cible conservées')
        link.unlink();out.unlink();out.symlink_to(external)
        try: package.create_archive(project,out)
        except ValueError: pass
        else: raise AssertionError('Output symlink accepted')
        check(external.read_text()=='protected test data','Lien de sortie refusé')
        out.unlink()
        check_profile_packages(project,base)
        stub=base/'godot stub'
        stub.write_text('''#!/usr/bin/env python3
import os,sys,time
from pathlib import Path
args=sys.argv[1:]
mode=os.environ.get('STUB_MODE','good')
with open(os.environ['STUB_TRACE'],'a') as log: log.write(repr(args)+'\\n')
if '--version' in args:
 print('4.6.3.rc.fake' if mode=='version' else '4.6.3.stable.official.test');sys.exit(0)
if mode=='import_error' and '--import' in args: print('SCRIPT ERROR: failed import');sys.exit(0)
if mode=='prep_error' and '--script' in args: print('SCRIPT ERROR: failed preparation');sys.exit(0)
if mode=='hold' and '--script' in args: time.sleep(2)
if '--export-release' in args or '--export-debug' in args:
 if mode=='export_error': print('ERROR: export failed');sys.exit(0)
 if mode!='empty': Path(args[-1]).write_text('new executable')
''')
        stub.chmod(0o755)
        trace=base/'trace.log'
        env=dict(os.environ,GODOT_BIN=str(stub),STUB_TRACE=str(trace),XDG_DATA_HOME=str(base/'normal data'),XDG_CONFIG_HOME=str(base/'normal config'),XDG_CACHE_HOME=str(base/'normal cache'))
        runtime=base/'demo root'
        export=project/'tools/export.sh';demo=project/'tools/run_demo.sh'
        binary=project/'builds/linux-arm64/console-ciel.arm64';binary.parent.mkdir(parents=True);binary.write_text('previous executable')
        def command(script,args,mode):
            return subprocess.run([str(script),*args],env=dict(env,STUB_MODE=mode),text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=20)
        for mode in ('import_error','export_error','empty'):
            result=command(export,['arm64'],mode)
            check(result.returncode!=0 and binary.read_text()=='previous executable','Échec '+mode+' ne remplace pas le binaire et ne signale pas succès')
        result=command(export,['arm64'],'good')
        check(result.returncode==0 and binary.read_text()=='new executable','Export réussi avec chemins contenant des espaces')
        check(not list(binary.parent.glob('.export.*')),'Répertoire de préparation nettoyé')
        check(command(export,['arm64'],'version').returncode!=0,'Version rc refusée')
        trace.write_text('')
        result=command(demo,['--output',str(runtime)],'prep_error')
        check(result.returncode!=0 and all('--path' not in row or '--script' in row or '--version' in row for row in trace.read_text().splitlines()),'Erreur de préparation empêche le lancement graphique')
        first=subprocess.Popen([str(demo),'--output',str(runtime),'--prepare-only'],env=dict(env,STUB_MODE='hold'),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        # Wait for the stub to start, rather than an arbitrary long delay.
        import time
        limit=time.monotonic()+5
        while time.monotonic()<limit:
            if trace.read_text().count('--script')>=2: break
            time.sleep(.02)
        result=command(demo,['--output',str(runtime),'--prepare-only'],'good')
        check(result.returncode!=0 and 'déjà' in result.stdout,'Double préparation de la même racine refusée')
        first.communicate(timeout=10)
        check(command(demo,['--output',str(runtime),'--prepare-only'],'good').returncode==0,'Verrou libéré après fermeture')
        spec=importlib.util.spec_from_file_location('test_support',PROJECT/'tools/test_support.py')
        support=importlib.util.module_from_spec(spec);spec.loader.exec_module(support)
        check(bool(support.unexpected_engine_errors('ERROR: runtime broken')),'Erreur moteur générique détectée même sans erreur de script')
        check(not support.unexpected_engine_errors('ERROR: ConfigFile parse error at user://tests/run_123/settings.cfg:0: fixture',True),'Corruption volontaire uniquement dans la copie de test reconnue')
        check(bool(support.unexpected_engine_errors('ERROR: ConfigFile parse error at user://profiles/settings.cfg:0: failure',True)),'Erreur hors copie de test jamais masquée')
        result=subprocess.run(['python3',str(project/'tools/check_close.py'),'--godot',str(base/'absent')],env=env,text=True,capture_output=True,timeout=10)
        check(result.returncode==1 and 'Traceback' not in result.stderr and 'impossible' in result.stdout,'Moteur absent produit un diagnostic exploitable')
    print(f'AUDIT_TOOLS : {COUNT} assertions, 0 échec(s).')

if __name__=='__main__': run()
