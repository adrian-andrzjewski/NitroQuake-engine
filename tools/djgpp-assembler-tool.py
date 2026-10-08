"""Build DJASM from pinned primary sources on the Windows verification host.

This host executable produces the original 16-bit loader/helper images; those
images must independently match the final DOS executable and pass ISA audit.
"""
from pathlib import Path
import argparse,hashlib,json,os,struct,subprocess,zipfile

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def host_compiler(explicit=None):
    """Never confuse a DJGPP target compiler with the Windows verification host."""
    candidates=[explicit] if explicit else [Path(item)/'gcc.exe' for item in os.environ.get('PATH','').split(os.pathsep) if item]
    if not explicit and os.environ.get('LOCALAPPDATA'):
        packages=Path(os.environ['LOCALAPPDATA'])/'Microsoft/WinGet/Packages'
        candidates+=sorted(packages.glob('*/mingw64/bin/gcc.exe'))
    seen=set()
    for path in candidates:
        path=Path(path).resolve()
        if path in seen or not path.is_file():continue
        seen.add(path)
        probe=subprocess.run([str(path),'-dumpmachine'],capture_output=True,text=True)
        target=probe.stdout.strip().lower()
        if probe.returncode==0 and ('mingw' in target or 'windows' in target):return path
        if explicit:raise ValueError(f'The requested host compiler targets {target!r}, rather than Windows.')
    raise ValueError('A Windows host GCC is required; use --host-compiler to identify a MinGW compiler.')

def require_host_executable(path):
    blob=path.read_bytes()
    if len(blob)<64 or blob[:2]!=b'MZ':raise ValueError('The compiled DJASM verification host is not a Windows executable.')
    header=struct.unpack_from('<I',blob,60)[0]
    if header+6>len(blob) or blob[header:header+4]!=b'PE\0\0':
        raise ValueError('The compiled DJASM verification host is not PE; a DOS target compiler may have been selected.')
    machine=struct.unpack_from('<H',blob,header+4)[0]
    if machine not in (0x14c,0x8664):raise ValueError(f'Unsupported Windows DJASM host machine: {machine:#x}')

def host_environment(compiler):
    environment=dict(os.environ)
    for name in ('DJDIR','DJGPP','GCC_EXEC_PREFIX','COMPILER_PATH','LIBRARY_PATH','CPATH','C_INCLUDE_PATH','CPLUS_INCLUDE_PATH'):
        environment.pop(name,None)
    environment['PATH']=str(compiler.parent)+os.pathsep+environment.get('PATH','')
    return environment

def build(bundle,compiler,output):
    compiler=host_compiler(compiler)
    index=json.loads((bundle/'manifest.json').read_text(encoding='utf-8'))
    files={x['path']:x for x in index['files']}
    archives={}
    for name in ['djlsr205.zip','djdev205.zip']:
        path=bundle/'primary'/name;record=files['primary/'+name]
        if path.stat().st_size!=record['bytes'] or sha(path)!=record['sha256']:
            raise ValueError(f'Changed primary DJASM archive: {name}')
        archives[name]=path
    output.mkdir(parents=True,exist_ok=True)
    for archive,member,target in [('djlsr205.zip','src/djasm/djasm.c','src/djasm/djasm.c'),
        ('djdev205.zip','include/coff.h','include/coff.h')]:
        with zipfile.ZipFile(archives[archive]) as package:content=package.read(member)
        path=output/target;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(content)
    executable=output/'djasm-host.exe'
    process=subprocess.run([str(compiler),'-O2','-std=gnu89',str(output/'src/djasm/djasm.c'),'-o',str(executable)],
                           capture_output=True,text=True,env=host_environment(compiler))
    (output/'compilation.txt').write_text(process.stdout+process.stderr,encoding='utf-8')
    if process.returncode:raise ValueError(f'Primary DJASM host build failed: {process.stderr}')
    require_host_executable(executable)
    report=dict(passed=True,hostToolOnly=True,sourceSha256=sha(output/'src/djasm/djasm.c'),headerSha256=sha(output/'include/coff.h'),
        hostCompiler=str(compiler.resolve()),hostCompilerSha256=sha(compiler),executable=str(executable.resolve()),executableSha256=sha(executable),
        archiveSha256={name:sha(path) for name,path in archives.items()})
    (output/'provenance.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return report
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bundle',type=Path,default=Path(__file__).with_name('isa-runtime-reference'))
    p.add_argument('--host-compiler',type=Path);p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();report=build(a.bundle,a.host_compiler,a.output)
    print(f"Primary DJASM host build PASS: {report['executable']}")
if __name__=='__main__':main()
