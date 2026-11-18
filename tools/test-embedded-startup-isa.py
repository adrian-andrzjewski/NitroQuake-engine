"""Run startup adversarial tests against a freshly verified release manifest."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,subprocess,sys,tempfile
from _nq import dump_flags

ROOT=Path(__file__).resolve().parents[1]
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest().upper()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest',type=Path)
    parser.add_argument('--tool-root',type=Path)
    args=parser.parse_args()
    path=args.manifest or Path(dump_flags('-CpuTarget','i486')['outputRoot'])/'build-manifest.json'
    manifest=load(path);exe=Path(manifest['executable']);linked=load(Path(manifest['isaLinkedAuditReport']))
    assert manifest['sourceBoundIsa'] and manifest['isaAuditStatus']=='PASS' and linked['pass']
    assert sha(exe)==manifest['executableSha256']==linked['executableSha256']
    crt=[Path(i['path']) for i in linked['runtimeInputs'] if i['kind']=='runtime-object' and Path(i['path']).name=='crt0.o']
    assert len(crt)==1
    work=Path(tempfile.mkdtemp(prefix='embedded-startup-regression-',dir=ROOT/'out'))
    spec=importlib.util.spec_from_file_location('startup_host_tool',ROOT/'tools/djgpp-assembler-tool.py')
    tool=importlib.util.module_from_spec(spec);spec.loader.exec_module(tool)
    host=tool.build(ROOT/'tools/isa-runtime-reference',None,work/'djasm')
    local_app_data=Path(os.environ.get('LOCALAPPDATA') or Path.home())
    tool_root=args.tool_root or local_app_data/'486quake/tools'
    archive=tool_root/'downloads/djlsr205.zip'
    if not archive.is_file():
        raise FileNotFoundError(f'Pinned DJGPP startup source archive is missing: {archive}; run tools/bootstrap-dos.ps1 first')
    config=load(ROOT/'tools/dos-toolchain.json')
    objdump=tool_root/config['djgpp']['installDirectory']/config['djgpp']['objdump']
    common=['--archive',str(archive),
            '--djasm',host['executable'],'--objdump',str(objdump)]
    records=[]
    for name,extra in [('test-mz-loader-proof.py',['--executable',str(exe)]),
            ('test-djgpp-startup-helpers-proof.py',['--object',str(crt[0])]),
            ('test-startup-linked-proof.py',['--executable',str(exe),'--map',linked['linkerMap'],'--crt-object',str(crt[0])])]:
        result=subprocess.run([sys.executable,str(ROOT/'tools'/name),*common,*extra],capture_output=True,text=True)
        (work/(name+'.txt')).write_text(result.stdout+result.stderr,encoding='utf-8')
        print(result.stdout.strip())
        assert result.returncode==0,(name,result.stderr)
        records.append(dict(test=name,passed=True))
    (work/'results.json').write_text(json.dumps(dict(passed=True,manifest=str(path),tests=records),indent=2)+'\n',encoding='utf-8')
    print('PASS: source-rebuilt loader, embedded CRT helpers and final executable startup; '+str(work))
if __name__=='__main__':main()
