"""Reproduce exact CODE/DATA boundaries for every linked runtime input.

Pinned compiler listings are verification sources, never replacements for the
installed runtime. Unknown objects or changed allocated bytes/relocations fail.
"""
from pathlib import Path
import argparse,hashlib,importlib.util,json,re,subprocess

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def load(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def relative_file(root,name):
    path=root/name
    if Path(name).is_absolute() or not path.resolve().is_relative_to(root.resolve()):
        raise ValueError(f'Runtime source path escapes its bundle: {name}')
    return path
def validate_bundle(root):
    index=load(root/'manifest.json')
    if index.get('schemaVersion')!=1 or index.get('replacesRuntimeObjects') is not False or index.get('unknownRuntimeObjectPolicy')!='fail':
        raise ValueError('Unrecognized runtime source bundle policy.')
    files={}
    for item in index['files']:
        name=item['path']
        if name in files:raise ValueError(f'Duplicate runtime source file: {name}')
        path=relative_file(root,name)
        if path.stat().st_size!=item['bytes'] or sha(path)!=item['sha256']:
            raise ValueError(f'Changed pinned runtime source file: {name}')
        files[name]=path
    entries={}
    for entry in index['entries']:
        name=entry['object']
        if not re.fullmatch(r'[A-Za-z0-9_.-]+\.obj',name) or name in entries:
            raise ValueError(f'Invalid or duplicate runtime identity: {name}')
        assembly=files.get(entry['assembly'])
        if assembly is None or sha(assembly)!=entry['assemblySha256']:
            raise ValueError(f'Runtime listing identity differs: {name}')
        if not entry['handwrittenAssembly']:
            source=files.get(entry.get('cSource'))
            if source is None or entry['cSource']!=entry.get('primarySource') or sha(source)!=entry['primarySourceSha256']:
                raise ValueError(f'Runtime C listing lacks its exact primary source: {name}')
        elif 'cSource' in entry:raise ValueError(f'Conflicting runtime source kinds: {name}')
        if 'primarySource' in entry:
            source=files.get(entry['primarySource'])
            if source is None or sha(source)!=entry['primarySourceSha256']:
                raise ValueError(f'Runtime primary source identity differs: {name}')
        entries[name]=entry
    return entries
def build(bundle,runtime_directory,providers,compiler,output):
    entries=validate_bundle(bundle)
    if not isinstance(providers,list) or not providers:raise ValueError('The linked runtime input list is empty or malformed.')
    names=set()
    for provider in providers:
        name=provider['object']
        if name in names:raise ValueError(f'Duplicate linked runtime input: {name}')
        names.add(name)
        if name not in entries:raise ValueError(f'Unproved linked runtime input: {name}; reproduce its primary source before accepting it.')
        native=relative_file(runtime_directory,name)
        if sha(native)!=entries[name]['objectSha256'] or provider.get('sha256')!=entries[name]['objectSha256']:
            raise ValueError(f'Changed installed runtime object: {name}; pinned native object SHA256 does not match.')
    spec=importlib.util.spec_from_file_location('coff_boundaries',Path(__file__).with_name('coff-code-data.py'))
    boundary=importlib.util.module_from_spec(spec);spec.loader.exec_module(boundary)
    output.mkdir(parents=True,exist_ok=True);proofs=[]
    for name in sorted(names):
        entry=entries[name];work=output/Path(name).stem;work.mkdir(exist_ok=True)
        assembly=bundle/entry['assembly'];annotated=work/'annotated.s';marked=work/'annotated.obj'
        annotated.write_text(boundary.annotate(assembly.read_text(encoding='utf-8'),entry['handwrittenAssembly']),encoding='utf-8',newline='')
        process=subprocess.run([str(compiler),'-c','-x','assembler',str(annotated),'-o',str(marked)],capture_output=True,text=True)
        if process.returncode:raise ValueError(f'Cannot reproduce {name}: {process.stderr}')
        proof=boundary.prove(runtime_directory/name,marked,assembly,annotated,bundle/entry['cSource'] if 'cSource' in entry else None,entry['handwrittenAssembly'])
        path=work/'code-data-proof.json';path.write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8');proofs.append(str(path.resolve()))
    report=dict(pass_=True,failures=[],proofs=proofs,runtimeInputs=len(names),
        runtimeBundle=str(bundle.resolve()),runtimeBundleManifestSha256=sha(bundle/'manifest.json'),
        assemblerDriver=str(compiler.resolve()),assemblerDriverSha256=sha(compiler),replacesRuntimeObjects=False)
    report['pass']=report.pop('pass_')
    (output/'proof-index.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return report
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bundle',type=Path,default=Path(__file__).with_name('isa-runtime-reference'))
    p.add_argument('--runtime-directory',type=Path,required=True)
    p.add_argument('--runtime-inputs',type=Path,required=True)
    p.add_argument('--compiler',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    a=p.parse_args()
    report=build(a.bundle,a.runtime_directory,load(a.runtime_inputs),a.compiler,a.output)
    print(f"Runtime source proof PASS: {report['runtimeInputs']} exact installed objects; {a.output/'proof-index.json'}")
if __name__=='__main__':main()
