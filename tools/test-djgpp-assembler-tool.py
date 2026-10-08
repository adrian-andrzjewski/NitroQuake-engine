"""Ensure cross-target environment variables cannot contaminate the host tool."""
from pathlib import Path
import importlib.util,json,os,struct,tempfile
ROOT=Path(__file__).resolve().parents[1]
def main():
    spec=importlib.util.spec_from_file_location('host_tool_test',ROOT/'tools/djgpp-assembler-tool.py')
    tool=importlib.util.module_from_spec(spec);spec.loader.exec_module(tool)
    work=Path(tempfile.mkdtemp(prefix='djasm-host-regression-',dir=ROOT/'out'))
    config=json.loads((ROOT/'tools/dos-toolchain.json').read_text(encoding='utf-8'))
    target_root=Path(os.environ['LOCALAPPDATA'])/'486quake/tools'/config['djgpp']['installDirectory']
    original=dict(os.environ)
    try:
        os.environ['GCC_EXEC_PREFIX']=str(target_root/'lib/gcc')+os.sep
        os.environ['DJDIR']=str(target_root/'i586-pc-msdosdjgpp')
        os.environ['PATH']=str(target_root/'bin')+os.pathsep+os.environ['PATH']
        os.environ['CPATH']=str(work/'missing-target-headers')
        result=tool.build(ROOT/'tools/isa-runtime-reference',None,work/'valid')
        assert result['passed'] and result['hostToolOnly']
        try:tool.host_compiler(target_root/config['djgpp']['compiler'])
        except ValueError:pass
        else:raise AssertionError('The DOS compiler was accepted as a Windows host compiler.')
    finally:
        os.environ.clear();os.environ.update(original)
    original_exe=Path(result['executable']).read_bytes();header=struct.unpack_from('<I',original_exe,60)[0]
    cases={}
    for name,offset,value in [('bad_mz',0,0),('dos_only_header',header,0),('wrong_machine',header+4,0xaa)]:
        blob=bytearray(original_exe);blob[offset]=value;cases[name]=blob
    cases['truncated']=original_exe[:63]
    for name,blob in cases.items():
        path=work/(name+'.exe');path.write_bytes(blob)
        try:tool.require_host_executable(path)
        except ValueError:pass
        else:raise AssertionError('Invalid Windows verification tool accepted: '+name)
    print(f'PASS: poisoned cross-target environment and {len(cases)+1} host-target rejections; {work}')
if __name__=='__main__':main()
