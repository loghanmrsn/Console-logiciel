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

def run():
    with tempfile.TemporaryDirectory(prefix='ciel-audit-tools-') as temporary:
        base=Path(temporary)
        project=base/'project with spaces'
        shutil.copytree(PROJECT/'tools',project/'tools',ignore=shutil.ignore_patterns('__pycache__'))
        for folder in ('scenes','scripts','assets','themes','data','tests','docs'): (project/folder).mkdir()
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
