"""Prove boundaries from the exact C listings and preprocessed maintained ASM built."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,shutil,subprocess

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def build(inputs,compiler,output):
    if not isinstance(inputs,list) or not inputs:raise ValueError('No project source inputs were supplied.')
    spec=importlib.util.spec_from_file_location('project_boundaries',Path(__file__).with_name('coff-code-data.py'))
    boundary=importlib.util.module_from_spec(spec);spec.loader.exec_module(boundary)
    output.mkdir(parents=True,exist_ok=False);proofs=[];names=set();bindings=[]
    for item in inputs:
        native=Path(item['object']);assembly=Path(item['assembly']);source=Path(item['source']);hand=item['handwrittenAssembly']
        if native.name.lower() in names:raise ValueError('Duplicate project object: '+native.name)
        names.add(native.name.lower())
        work=output/native.stem;work.mkdir();saved_assembly=work/'built.s';saved_source=work/source.name
        shutil.copy2(assembly,saved_assembly);shutil.copy2(source,saved_source)
        if hand is not (source.suffix.lower()=='.s'):raise ValueError('Conflicting project source kind: '+str(source))
        annotated=work/'annotated.s';marked=work/'annotated.obj'
        annotated.write_text(boundary.annotate(saved_assembly.read_text(encoding='utf-8'),hand),encoding='utf-8',newline='')
        process=subprocess.run([str(compiler),'-c','-x','assembler',str(annotated),'-o',str(marked)],capture_output=True,text=True)
        if process.returncode:raise ValueError(f'Boundary reassembly failed for {native.name}: {process.stderr}')
        proof=boundary.prove(native,marked,saved_assembly,annotated,None if hand else saved_source,hand)
        path=work/'code-data-proof.json';path.write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8');proofs.append(str(path.resolve()))
        bindings.append(dict(object=str(native.resolve()),objectSha256=sha(native),source=str(source.resolve()),sourceSha256=sha(source),
            builtAssembly=str(assembly.resolve()),builtAssemblySha256=sha(assembly),handwrittenAssembly=hand))
    report=dict(**{'pass':True},failures=[],proofs=proofs,projectInputs=len(proofs),sourceBindings=bindings,
        assemblerDriver=str(compiler.resolve()),assemblerDriverSha256=sha(compiler))
    (output/'proof-index.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return report
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--inputs',type=Path,required=True);p.add_argument('--compiler',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();report=build(json.loads(a.inputs.read_text(encoding='utf-8-sig')),a.compiler,a.output)
    print(f"Project source proof PASS: {report['projectInputs']} exact objects; {a.output/'proof-index.json'}")
if __name__=='__main__':main()
